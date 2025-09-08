// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title SimpleAllowanceDistributorV7
/// @notice Раздача аллокаций без Merkle: владелец задаёт totalAllocation адресам.
///         Разблокировка по жёсткому графику: 20% на TGE и дальше 8 траншей по 10%.
///         Интервал между траншами настраиваемый (для теста 10 минут, затем 15 дней).
contract SimpleAllowanceDistributorV7 is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    error NothingToClaim();
    error InsufficientBalance();
    error ZeroAddress();
    error BadLengths();
    error BpsOverflow();

    IERC20 public immutable token;            // ERC20 (CCR)

    // --- График: 20% на TGE + 8 * 10% = 100%
    uint16 private constant TGE_BPS = 2000;   // 20.00%
    uint16 private constant STEP_BPS = 1000;  // 10.00% каждый интервал
    uint8  private constant STEPS = 8;        // восемь пост-TGE шагов
    uint16 private constant DENOM = 10000;    // 100.00%

    // Параметры расписания
    uint64 public tgeTimestamp;               // unix-время TGE (UTC)
    uint32 public intervalSeconds;            // длительность одного шага

    mapping(address => uint256) public totalAllocation;
    mapping(address => uint256) public claimed;

    event Claimed(address indexed user, uint256 amount);
    event AllocationsSet(uint256 count);
    event TgeUpdated(uint64 tgeTimestamp);
    event IntervalUpdated(uint32 intervalSeconds);

    /// @param token_ адрес ERC20 токена
    /// @param initialOwner владелец (Ownable v5 принимает владельца в конструкторе)
    constructor(address token_, address initialOwner) Ownable(initialOwner) {
        if (token_ == address(0)) revert ZeroAddress();
        token = IERC20(token_);
        // значения по умолчанию (можно поменять сеттерами):
        // TGE = 0 (не начался), intervalSeconds = 0 (нужно задать).
    }

    // ============ Admin ============
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    /// @notice Установить/изменить TGE timestamp (можно менять в любой момент)
    function setTge(uint64 tgeTs) external onlyOwner {
        tgeTimestamp = tgeTs;
        emit TgeUpdated(tgeTs);
    }

    /// @notice Установить/изменить длительность интервала (секунды)
    /// Для теста ставим 600 (10 минут), в проде — 1296000 (15 дней).
    function setIntervalSeconds(uint32 seconds_) external onlyOwner {
        intervalSeconds = seconds_;
        emit IntervalUpdated(seconds_);
    }

    /// @notice Массово задать totalAllocation для адресов (перезаписывает total; claimed не трогаем)
    function setAllocations(address[] calldata users, uint256[] calldata totals) external onlyOwner {
        uint256 len = users.length;
        if (len == 0 || len != totals.length) revert BadLengths();
        for (uint256 i = 0; i < len; i++) {
            address u = users[i];
            if (u == address(0)) revert ZeroAddress();
            totalAllocation[u] = totals[i];
        }
        emit AllocationsSet(len);
    }

    // ============ View ============
    /// @notice Сколько бипсов (из 10000) разблокировано на момент ts
    function unlockedBpsAt(uint64 ts) public view returns (uint16) {
        if (tgeTimestamp == 0 || ts < tgeTimestamp) {
            return 0;
        }
        // На TGE доступно 20%
        if (intervalSeconds == 0) {
            // если интервал не задан, открываем только TGE 20%
            return TGE_BPS;
        }

        // k = сколько полных интервалов прошло после TGE
        // при ts == tgeTimestamp -> k = 0 -> 20%
        uint256 k = (uint256(ts) - uint256(tgeTimestamp)) / uint256(intervalSeconds);
        if (k >= STEPS) {
            return DENOM; // 100%
        }
        // 20% + k * 10%
        uint256 bps = uint256(TGE_BPS) + k * uint256(STEP_BPS);
        if (bps > DENOM) revert BpsOverflow(); // защитный чек (не должен срабатывать)
        return uint16(bps);
    }

    /// @notice Текущие разблокированные бипсы
    function unlockedBpsNow() public view returns (uint16) {
        return unlockedBpsAt(uint64(block.timestamp));
    }

    /// @notice Сколько уже доступно пользователю (в токенах)
    function available(address user) public view returns (uint256) {
        uint256 tot = totalAllocation[user];
        if (tot == 0) return 0;
        uint256 unlocked = (tot * uint256(unlockedBpsNow())) / DENOM;
        uint256 done = claimed[user];
        if (unlocked <= done) return 0;
        return unlocked - done;
    }

    function info(address user) external view returns (uint256 tot, uint256 done, uint256 avail, uint16 bps) {
        tot = totalAllocation[user];
        done = claimed[user];
        bps = unlockedBpsNow();
        uint256 unlocked = (tot * uint256(bps)) / DENOM;
        avail = unlocked > done ? unlocked - done : 0;
    }

    /// @notice Номер стадии для UI (0 = до TGE; 1 = TGE 20%; 2..9 = пост-транши; 9 = 100%)
    function stageNow() external view returns (uint8) {
        if (tgeTimestamp == 0 || block.timestamp < tgeTimestamp) return 0;
        if (intervalSeconds == 0) return 1; // только TGE
        uint256 k = (uint256(block.timestamp) - uint256(tgeTimestamp)) / uint256(intervalSeconds);
        if (k >= STEPS) return 9;
        return uint8(1 + k); // 1..9
    }

    // ============ Claim ============
    function claim() external nonReentrant whenNotPaused {
        uint256 amt = available(msg.sender);
        if (amt == 0) revert NothingToClaim();
        // эффект
        claimed[msg.sender] += amt;
        // проверка ликвидности
        if (token.balanceOf(address(this)) < amt) revert InsufficientBalance();
        token.safeTransfer(msg.sender, amt);
        emit Claimed(msg.sender, amt);
    }

    // ============ Rescue (на случай ошибочных переводов не-целевого токена) ============
    function rescueTokens(address otherToken, uint256 amount, address to) external onlyOwner {
        if (otherToken == address(token)) revert(); // нельзя спасать сам вестимый токен
        if (to == address(0)) revert ZeroAddress();
        IERC20(otherToken).safeTransfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @notice Линейный вестинг через меркл-дистрибьютор, с несколькими кампаниями.
///   Для каждой кампании (campaignId) у участника в дереве хранится его total allocation.
///   В любой момент он может забрать linearVested(total) - уже_забранное.
contract CCRLinearMerkleDistributor is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Campaign {
        uint64 start;        // когда начинается линейка
        uint64 cliff;        // до cliff клейм = 0
        uint64 duration;     // длительность линейки
        uint128 cap;         // верхняя граница общей раздачи (страховка)
        uint128 totalClaimed; 
        bytes32 merkleRoot;  // leaf = keccak256(abi.encodePacked(account, totalAllocation))
        bool active;
    }

    IERC20 public immutable token;
    mapping(uint32 => Campaign) public campaigns;
    mapping(uint32 => mapping(address => uint128)) public claimed; // campaignId => user => claimed

    event CampaignCreated(uint32 indexed id, uint64 start, uint64 cliff, uint64 duration, uint128 cap, bytes32 merkleRoot);
    event CampaignToggled(uint32 indexed id, bool active);
    event MerkleRootUpdated(uint32 indexed id, bytes32 newRoot); // на случай досоздания волны той же кампании (не злоупотреблять)
    event Claimed(uint32 indexed id, address indexed account, uint128 amount);

    constructor(IERC20 _token, address initialOwner) Ownable(initialOwner) {
        token = _token;
    }

    // -------- Admin (через Timelock позже) --------
    function createCampaign(
        uint32 id,
        uint64 start,
        uint64 cliff,
        uint64 duration,
        uint128 cap,
        bytes32 merkleRoot
    ) external onlyOwner {
        require(campaigns[id].merkleRoot == bytes32(0), "exists");
        require(duration > 0, "bad duration");
        require(merkleRoot != bytes32(0), "bad root");
        campaigns[id] = Campaign({
            start: start,
            cliff: cliff,
            duration: duration,
            cap: cap,
            totalClaimed: 0,
            merkleRoot: merkleRoot,
            active: true
        });
        emit CampaignCreated(id, start, cliff, duration, cap, merkleRoot);
    }

    function toggleCampaign(uint32 id, bool active) external onlyOwner {
        campaigns[id].active = active;
        emit CampaignToggled(id, active);
    }

    // опционально — если нужно выпустить следующую волну в той же кампании
    function setMerkleRoot(uint32 id, bytes32 newRoot) external onlyOwner {
        require(newRoot != bytes32(0), "bad root");
        campaigns[id].merkleRoot = newRoot;
        emit MerkleRootUpdated(id, newRoot);
    }

    // -------- Пользователь --------
    /// @param id campaignId
    /// @param total total allocation для msg.sender из merkle-листа (в wei)
    /// @param proof меркл-путь для (msg.sender, total)
    function claim(uint32 id, uint128 total, bytes32[] calldata proof) external nonReentrant {
        Campaign memory c = campaigns[id];
        require(c.active, "inactive");
        require(c.merkleRoot != bytes32(0), "no root");

        // проверяем меркл-лист
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, total));
        require(MerkleProof.verifyCalldata(proof, c.merkleRoot, leaf), "bad proof");

        // сколько всего должно быть доступно на этот момент по линейке
        uint128 vestedNow = _vestedAmount(c, total);
        uint128 already = claimed[id][msg.sender];
        require(vestedNow > already, "nothing");

        uint128 toClaim = vestedNow - already;

        // защита от переполнения общей шапки кампании
        if (c.cap > 0) {
            require(c.totalClaimed + toClaim <= c.cap, "cap");
        }

        // эффекты
        claimed[id][msg.sender] = vestedNow; // эквивалентно += toClaim
        campaigns[id].totalClaimed += toClaim;

        // перевод
        token.safeTransfer(msg.sender, toClaim);
        emit Claimed(id, msg.sender, toClaim);
    }

    function claimable(uint32 id, address account, uint128 total) external view returns (uint128) {
        Campaign memory c = campaigns[id];
        if (!c.active || c.merkleRoot == bytes32(0)) return 0;
        uint128 v = _vestedAmount(c, total);
        uint128 a = claimed[id][account];
        return v > a ? v - a : 0;
    }

    // -------- внутренняя математика --------
    function _vestedAmount(Campaign memory c, uint128 total) internal view returns (uint128) {
        uint64 t = uint64(block.timestamp);
        if (t < c.cliff) return 0;
        if (t >= c.start + c.duration) return total;
        if (t <= c.start) return 0;
        uint256 elapsed = t - c.start;
        return uint128(uint256(total) * elapsed / c.duration);
    }
}

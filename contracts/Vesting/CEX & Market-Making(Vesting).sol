// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LinearVestingWithCliff
 * @notice Вестинг с клифом и последующей линейной разблокировкой.
 *         Контракт пополняемый: можно докидивать токены, формула считает
 *         аллокацию как (released + currentBalance).
 *         Без функции revoke. Владелец может сменить бенефициара и
 *         спасти "чужие" токены (кроме вестимого токена).
 */
contract LinearVestingWithCliff is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public beneficiary;

    uint64 public immutable start;        // TGE (UTC)
    uint64 public immutable cliffEnd;     // start + cliff
    uint64 public immutable end;          // cliffEnd + linearDuration

    uint256 public released;              // сколько уже выдано бенефициару (token)

    event Released(uint256 amount);
    event BeneficiaryUpdated(address indexed oldBeneficiary, address indexed newBeneficiary);

    constructor(
        IERC20 token_,
        address beneficiary_,
        address owner_,
        uint64 start_,
        uint64 cliffDurationSeconds_,
        uint64 linearDurationSeconds_
    ) Ownable(owner_) {
        require(address(token_) != address(0), "token=0");
        require(beneficiary_ != address(0), "beneficiary=0");
        require(linearDurationSeconds_ > 0, "linear=0");

        token = token_;
        beneficiary = beneficiary_;
        start = start_;
        cliffEnd = start_ + cliffDurationSeconds_;
        end = cliffEnd + linearDurationSeconds_;
    }

    function totalAllocation() public view returns (uint256) {
        // Динамическая аллокация = уже выдано + то, что лежит на контракте
        return released + token.balanceOf(address(this));
    }

    function vestedAmount(uint64 timestamp) public view returns (uint256) {
        uint256 total = totalAllocation();
        if (timestamp < cliffEnd) {
            return 0;
        } else if (timestamp >= end) {
            return total;
        } else {
            uint64 vestedSeconds = timestamp - cliffEnd;
            uint64 totalLinear = end - cliffEnd; // = linearDurationSeconds
            return (total * vestedSeconds) / totalLinear;
        }
    }

    function releasable() public view returns (uint256) {
        uint256 vested = vestedAmount(uint64(block.timestamp));
        return vested > released ? (vested - released) : 0;
    }

    function release() external {
        uint256 amount = releasable();
        require(amount > 0, "Nothing to release");
        released += amount;
        token.safeTransfer(beneficiary, amount);
        emit Released(amount);
    }

    function setBeneficiary(address newBeneficiary) external onlyOwner {
        require(newBeneficiary != address(0), "beneficiary=0");
        address old = beneficiary;
        beneficiary = newBeneficiary;
        emit BeneficiaryUpdated(old, newBeneficiary);
    }

    // Спасение любых других токенов, кроме вестимого
    function rescueTokens(IERC20 other, uint256 amount) external onlyOwner {
        require(address(other) != address(token), "cannot rescue vested token");
        other.safeTransfer(owner(), amount);
    }
}

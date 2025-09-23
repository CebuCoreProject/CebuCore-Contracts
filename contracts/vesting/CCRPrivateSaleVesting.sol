// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title PRIVATE SALE Vesting (hard-coded, ownerless)
/// @notice TGE -> 6 months cliff -> per-second linear vesting over 24 months.

interface IERC20_Private {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CCRPrivateSaleVesting {
    address public constant TOKEN = 0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a;
    address public constant BENEFICIARY = 0x18338629A6e109F5b07db7270Ce1Ce9FF7A7EccF;
    uint256 public constant TOTAL_ALLOCATION = 1000000000000000000000000000;

    uint64  public constant TGE_TS   = 1760961600; // 20.10.2025 14:00
    uint64  public constant CLIFF_TS = 1776686400; // 20.04.2026 14:00
    uint64  public constant END_TS   = 1839844800; // 20.04.2028 14:00

    uint256 public claimed;

    event Claimed(address indexed account, uint256 amount);
    error NothingToClaim();
    error NotBeneficiary();
    error TransferFailed();

    function claimable() public view returns (uint256) {
        uint256 vested = _vestedAt(block.timestamp);
        if (vested <= claimed) return 0;
        return vested - claimed;
    }

    function _vestedAt(uint256 ts) internal pure returns (uint256) {
        if (ts < TGE_TS) return 0;
        if (ts < CLIFF_TS) return 0;
        if (ts >= END_TS) return TOTAL_ALLOCATION;

        uint256 duration = uint256(END_TS - CLIFF_TS);
        uint256 elapsed  = ts - CLIFF_TS;
        return (TOTAL_ALLOCATION * elapsed) / duration;
    }

    function claim() external {
        if (msg.sender != BENEFICIARY) revert NotBeneficiary();
        uint256 amount = claimable();
        if (amount == 0) revert NothingToClaim();

        claimed += amount;
        if (!IERC20_Private(TOKEN).transfer(BENEFICIARY, amount)) revert TransferFailed();
        emit Claimed(BENEFICIARY, amount);
    }
}

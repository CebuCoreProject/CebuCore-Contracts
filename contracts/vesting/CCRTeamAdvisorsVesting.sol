// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title TEAM & ADVISORS Vesting (hard-coded, ownerless)
/// @notice TGE -> 6 months cliff -> per-second linear vesting over 24 months.
/// @dev No owner, no pause, no constructor args; all critical params are constants.

interface IERC20_Team {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CCRTeamAdvisorsVesting {
    // --- Hard-coded constants ---
    address public constant TOKEN = 0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a;
    address public constant BENEFICIARY = 0xeF88eb9dA1493D0Cc9a18AfafA09F5EA99BC70cf;
    uint256 public constant TOTAL_ALLOCATION = 1500000000000000000000000000;

    // TGE: 20.10.2025 14:00 → 1760961600
    // Cliff: +6 months → 20.04.2026 14:00 → 1776686400
    // End: +24 months from cliff → 20.04.2028 14:00 → 1839844800
    uint64  public constant TGE_TS   = 1760961600;
    uint64  public constant CLIFF_TS = 1776686400;
    uint64  public constant END_TS   = 1839844800;

    // --- State ---
    uint256 public claimed;

    // --- Events ---
    event Claimed(address indexed account, uint256 amount);

    // --- Errors ---
    error NothingToClaim();
    error NotBeneficiary();
    error TransferFailed();

    // --- Views ---
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

    // --- Actions ---
    function claim() external {
        if (msg.sender != BENEFICIARY) revert NotBeneficiary();
        uint256 amount = claimable();
        if (amount == 0) revert NothingToClaim();

        claimed += amount;
        if (!IERC20_Team(TOKEN).transfer(BENEFICIARY, amount)) revert TransferFailed();
        emit Claimed(BENEFICIARY, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title CEX & Market-Making Vesting (hard-coded, ownerless)
/// @notice 3 months cliff after TGE, then linear vesting over 12 months.

interface IERC20_CexMm {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CCRCexMmVesting {
    // CCR token & beneficiary (multisig)
    address public constant TOKEN = 0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a;
    address public constant BENEFICIARY = 0x66bf61E4dAAdc87e15B2c75A7ceA69963Cc5E234;

    // Total: 1.2B * 1e18
    uint256 public constant TOTAL_ALLOCATION = 1200000000000000000000000000;

    // Schedule (Europe/Zurich)
    // TGE:   20.10.2025 14:00 → 1760961600
    // Cliff: 20.01.2026 14:00 → 1771557600 (TGE + 3 months)
    // End:   20.01.2027 14:00 → 1803093600 (Cliff + 12 months)
    uint64  public constant TGE_TS   = 1760961600;
    uint64  public constant CLIFF_TS = 1771557600;
    uint64  public constant END_TS   = 1803093600;

    // State
    uint256 public claimed;

    // Events / Errors
    event Claimed(address indexed account, uint256 amount);
    error NothingToClaim();
    error NotBeneficiary();
    error TransferFailed();

    // Views
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

    // Actions
    function claim() external {
        if (msg.sender != BENEFICIARY) revert NotBeneficiary();
        uint256 amount = claimable();
        if (amount == 0) revert NothingToClaim();

        claimed += amount;
        if (!IERC20_CexMm(TOKEN).transfer(BENEFICIARY, amount)) revert TransferFailed();
        emit Claimed(BENEFICIARY, amount);
    }
}

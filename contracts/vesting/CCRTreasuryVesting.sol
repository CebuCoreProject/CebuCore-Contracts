// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title TREASURY Vesting (hard-coded, ownerless)
/// @notice Linear vesting from TGE over 24 months (no cliff).

interface IERC20_Treasury {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CCRTreasuryVesting {
    // CCR token & beneficiary (multisig)
    address public constant TOKEN = 0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a;
    address public constant BENEFICIARY = 0x0130c46Ec30DF64e7f430395F2d99E2C93A4c53D;

    // Total: 1.0B * 1e18
    uint256 public constant TOTAL_ALLOCATION = 1000000000000000000000000000;

    // Schedule (Europe/Zurich)
    // TGE:  20.10.2025 14:00 → 1760961600
    // End:  20.10.2027 14:00 → 1824033600
    uint64  public constant TGE_TS   = 1760961600;
    uint64  public constant END_TS   = 1824033600;

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
        if (ts >= END_TS) return TOTAL_ALLOCATION;

        uint256 duration = uint256(END_TS - TGE_TS);
        uint256 elapsed  = ts - TGE_TS;
        return (TOTAL_ALLOCATION * elapsed) / duration;
    }

    // Actions
    function claim() external {
        if (msg.sender != BENEFICIARY) revert NotBeneficiary();
        uint256 amount = claimable();
        if (amount == 0) revert NothingToClaim();

        claimed += amount;
        if (!IERC20_Treasury(TOKEN).transfer(BENEFICIARY, amount)) revert TransferFailed();
        emit Claimed(BENEFICIARY, amount);
    }
}

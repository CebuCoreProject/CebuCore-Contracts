// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title ECOSYSTEM Vesting (hard-coded, ownerless)
/// @notice Linear vesting from TGE over 24 months (no cliff).

interface IERC20_Eco {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract CCREcosystemVesting {
    // CCR token & beneficiary (multisig)
    address public constant TOKEN = 0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a;
    address public constant BENEFICIARY = 0x06e65FEb92280f1f9ed06D0833B441c72E66f1b7;

    // Total: 2.0B * 1e18
    uint256 public constant TOTAL_ALLOCATION = 2000000000000000000000000000;

    // Schedule (Europe/Zurich)
    // TGE:  20.10.2025 14:00 → 1760961600
    // End:  20.10.2027 14:00 → 1824033600
    uint64  public constant TGE_TS   = 1760961600;
    uint64  public constant END_TS   = 1824033600;

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
        if (ts >= END_TS) return TOTAL_ALLOCATION;
        uint256 duration = uint256(END_TS - TGE_TS);
        uint256 elapsed  = ts - TGE_TS;
        return (TOTAL_ALLOCATION * elapsed) / duration; // per-second linear
    }

    function claim() external {
        if (msg.sender != BENEFICIARY) revert NotBeneficiary();
        uint256 amount = claimable();
        if (amount == 0) revert NothingToClaim();
        claimed += amount;
        if (!IERC20_Eco(TOKEN).transfer(BENEFICIARY, amount)) revert TransferFailed();
        emit Claimed(BENEFICIARY, amount);
    }
}

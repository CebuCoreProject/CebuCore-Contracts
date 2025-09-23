// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Claim Distributor (ownerless, non-merkle, immutable schedule)
/// @notice Fixed schedule: 20% at TGE + 10% every 15 days × 8 (total 100%).
/// @dev No owner, no pause. Allocations can be seeded once per address by SEEDER before sealing.

interface IERC20_Claim {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address) external view returns (uint256);
}

contract CCRClaimDistributor {
    // ===== Constants (hard-coded) =====
    // CCR token (BNB Chain)
    address public constant TOKEN = 0x7576AC3010f4d41b73a03220CDa0e5e040F64c8a;

    // Address allowed to seed allocations before sealing (your Treasury Safe)
    address public constant SEEDER = 0xA0060Fd1CC044514D4E2F7D9F4204fEc517d7aDE;

    // Pool cap: 1,000,000,000 * 1e18
    uint256 public constant POOL_CAP = 1000000000000000000000000000;

    // Schedule: 20% TGE, then 10% every 15 days × 8
    uint16  public constant BPS_DENOM     = 10000;
    uint16  public constant TGE_BPS       = 2000;    // 20%
    uint16  public constant STEP_BPS      = 1000;    // 10%
    uint8   public constant STEPS         = 8;       // 8 steps → 80%
    uint32  public constant INTERVAL_SECS = 1296000; // 15 days in seconds

    // TGE timestamp (Europe/Zurich 2025-10-20 14:00 → unix)
    uint64  public constant TGE_TS        = 1760961600;

    // ===== Storage =====
    mapping(address => uint256) private _total;   // total allocation per user
    mapping(address => uint256) private _claimed; // claimed per user
    uint256 public totalAllocated;                // sum of all allocations
    bool    public isSealed;                      // once true → seeding disabled forever

    // ===== Events =====
    event Seeded(address indexed account, uint256 amount);
    event Sealed();
    event Claimed(address indexed account, uint256 amount);

    // ===== Errors =====
    error NotSeeder();
    error AlreadySeeded();
    error SealedAlready();
    error ZeroAddress();
    error ZeroAmount();
    error PoolCapExceeded();
    error NothingToClaim();
    error TransferFailed();

    // ===== Seeder ops (before seal) =====

    /// @notice Seed multiple allocations once; each address can be set only once.
    /// @dev Only SEEDER, only before seal. Cannot exceed POOL_CAP. No overwrites.
    function seedAllocations(address[] calldata accounts, uint256[] calldata amounts) external {
        if (msg.sender != SEEDER) revert NotSeeder();
        if (isSealed) revert SealedAlready();
        uint256 len = accounts.length;
        if (len == 0 || len != amounts.length) revert ZeroAmount(); // also guards empty

        uint256 added;
        for (uint256 i = 0; i < len; i++) {
            address a = accounts[i];
            uint256 v = amounts[i];
            if (a == address(0)) revert ZeroAddress();
            if (v == 0) revert ZeroAmount();
            if (_total[a] != 0) revert AlreadySeeded();

            _total[a] = v;
            added += v;
            emit Seeded(a, v);
        }

        uint256 newTotal = totalAllocated + added;
        if (newTotal > POOL_CAP) revert PoolCapExceeded();
        totalAllocated = newTotal;
    }

    /// @notice Irreversibly seal the distributor (no further seeding).
    function seal() external {
        if (msg.sender != SEEDER) revert NotSeeder();
        if (isSealed) revert SealedAlready();
        isSealed = true;
        emit Sealed();
    }

    // ===== Views =====

    function tgeTs() external pure returns (uint64) { return TGE_TS; }
    function intervalSeconds() external pure returns (uint32) { return INTERVAL_SECS; }
    function tgeBps() external pure returns (uint16) { return TGE_BPS; }
    function stepBps() external pure returns (uint16) { return STEP_BPS; }
    function steps() external pure returns (uint8) { return STEPS; }

    function allocationOf(address account) external view returns (uint256) {
        return _total[account];
    }

    function claimedOf(address account) external view returns (uint256) {
        return _claimed[account];
    }

    /// @notice How much `account` could claim right now.
    function claimable(address account) public view returns (uint256) {
        uint256 tot = _total[account];
        if (tot == 0) return 0;
        uint256 unlocked = (tot * _unlockedBpsAt(block.timestamp)) / BPS_DENOM;
        uint256 already  = _claimed[account];
        if (unlocked <= already) return 0;
        return unlocked - already;
    }

    /// @dev Unlock curve: 0% before TGE; at TGE => +20%; then +10% each 15 days, up to 100%.
    function _unlockedBpsAt(uint256 ts) internal pure returns (uint16) {
        if (ts < TGE_TS) return 0;
        unchecked {
            uint256 passed = (ts - TGE_TS) / INTERVAL_SECS;
            if (passed >= STEPS) return BPS_DENOM; // 100%
            uint256 bps = uint256(TGE_BPS) + uint256(STEP_BPS) * passed;
            if (bps >= BPS_DENOM) return BPS_DENOM;
            return uint16(bps);
        }
    }

    // ===== Claims =====

    /// @notice Claim vested tokens to caller (user wallet).
    function claim() external {
        uint256 amount = claimable(msg.sender);
        if (amount == 0) revert NothingToClaim();
        _claimed[msg.sender] += amount;
        if (!IERC20_Claim(TOKEN).transfer(msg.sender, amount)) revert TransferFailed();
        emit Claimed(msg.sender, amount);
    }
}

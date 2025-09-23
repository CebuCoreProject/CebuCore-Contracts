// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
 * CCR — CebuCore Token (BEP-20 on BNB Smart Chain)
 * Features:
 * - Fixed supply: 10,000,000,000 CCR (18 decimals) minted to owner
 * - Burnable (ERC20Burnable)
 * - Pausable (owner can pause in emergencies)
 * - Trading lock until owner enables trading (anti-sniper)
 * - Soft anti-bot limits for first N seconds after trading is enabled:
 *     * maxTx and maxWallet limits (owner-configurable)
 *     * exclude list for CEX/treasury/owner, etc.
 * All settings are simple and can be disabled after запуска.
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract CebuCoreToken is ERC20, ERC20Burnable, Pausable, Ownable {
    // --- Trading gate ---
    bool public tradingEnabled;
    uint256 public tradingStart; // timestamp when trading enabled

    // --- Soft anti-bot limits (active only for a short window after enableTrading) ---
    struct Limits {
        uint256 maxTx;       // absolute amount (in wei of token)
        uint256 maxWallet;   // absolute amount (in wei of token)
        uint256 endTime;     // timestamp when limits stop
        bool enabled;        // master switch
    }
    Limits public limits;

    mapping(address => bool) public isExcludedFromLimits;

    event TradingEnabled(uint256 startTime, uint256 durationSeconds, uint256 maxTx, uint256 maxWallet);
    event LimitsUpdated(uint256 maxTx, uint256 maxWallet, uint256 endTime, bool enabled);
    event ExclusionUpdated(address indexed account, bool isExcluded);
    event PausedByOwner(address indexed owner);
    event UnpausedByOwner(address indexed owner);

    constructor()
        ERC20("CebuCore", "CCR")
        Ownable(msg.sender) // OZ v5: set initial owner explicitly
    {
        // Mint full supply to owner
        _mint(msg.sender, 10_000_000_000 * 10 ** decimals());

        // sensible defaults: exclude owner from limits
        isExcludedFromLimits[msg.sender] = true;
        // limits disabled by default
        limits = Limits({
            maxTx: 0,
            maxWallet: 0,
            endTime: 0,
            enabled: false
        });
    }

    // --- Owner controls ---

    /// @notice Enable trading and (optionally) set temporary anti-bot limits window.
    /// @param durationSeconds how long limits stay active after enabling (e.g., 600 = 10 min). set 0 to keep limits disabled.
    /// @param maxTxBps max tx in basis points of totalSupply (e.g., 100 = 1%). Ignored if durationSeconds=0.
    /// @param maxWalletBps max wallet in basis points of totalSupply (e.g., 200 = 2%). Ignored if durationSeconds=0.
    function enableTrading(
        uint256 durationSeconds,
        uint256 maxTxBps,
        uint256 maxWalletBps
    ) external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");
        tradingEnabled = true;
        tradingStart = block.timestamp;

        if (durationSeconds > 0) {
            require(maxTxBps > 0 && maxWalletBps > 0, "Invalid bps");
            uint256 ts = totalSupply();
            limits.maxTx = (ts * maxTxBps) / 10_000;       // bps of totalSupply
            limits.maxWallet = (ts * maxWalletBps) / 10_000;
            limits.endTime = tradingStart + durationSeconds;
            limits.enabled = true;
        } else {
            // disable limits
            limits.maxTx = 0;
            limits.maxWallet = 0;
            limits.endTime = 0;
            limits.enabled = false;
        }

        emit TradingEnabled(tradingStart, durationSeconds, limits.maxTx, limits.maxWallet);
    }

    /// @notice Manually update/extend limits window (optional).
    function setLimits(uint256 maxTxAmount, uint256 maxWalletAmount, uint256 endTime, bool enabled) external onlyOwner {
        limits.maxTx = maxTxAmount;
        limits.maxWallet = maxWalletAmount;
        limits.endTime = endTime;
        limits.enabled = enabled;
        emit LimitsUpdated(maxTxAmount, maxWalletAmount, endTime, enabled);
    }

    /// @notice Exclude/include account from temporary limits.
    function setExcludedFromLimits(address account, bool excluded) external onlyOwner {
        isExcludedFromLimits[account] = excluded;
        emit ExclusionUpdated(account, excluded);
    }

    /// @notice Pause all transfers (emergency only).
    function pause() external onlyOwner {
        _pause();
        emit PausedByOwner(msg.sender);
    }

    /// @notice Unpause transfers.
    function unpause() external onlyOwner {
        _unpause();
        emit UnpausedByOwner(msg.sender);
    }

    // --- Internal transfer hook enforcing pause/trading/limits ---
    function _update(address from, address to, uint256 value) internal override(ERC20) whenNotPaused {
        // Before trading is enabled, only owner can move tokens (e.g., to set up IDO/LP)
        if (!tradingEnabled) {
            require(from == owner() || to == owner(), "Trading not enabled");
        } else {
            // If limits window active, enforce soft anti-bot rules
            if (limits.enabled && block.timestamp < limits.endTime) {
                if (!isExcludedFromLimits[from] && !isExcludedFromLimits[to]) {
                    if (limits.maxTx > 0) {
                        require(value <= limits.maxTx, "Over maxTx during limits");
                    }
                    if (limits.maxWallet > 0 && to != address(0)) {
                        require(balanceOf(to) + value <= limits.maxWallet, "Over maxWallet during limits");
                    }
                }
            }
        }
        super._update(from, to, value);
    }
}

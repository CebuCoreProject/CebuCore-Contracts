// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract CCRMultiVesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Schedule {
        uint128 total;
        uint128 claimed;
        uint64  start;
        uint64  cliff;
        uint64  duration;
        bool    active;
    }

    IERC20 public immutable token;
    mapping(address => Schedule[]) public schedules;

    event ScheduleAdded(address indexed beneficiary, uint256 indexed id, uint128 total, uint64 start, uint64 cliff, uint64 duration);
    event Claimed(address indexed beneficiary, uint256 indexed id, uint128 amount);
    event ScheduleToggled(address indexed beneficiary, uint256 indexed id, bool active);

    constructor(IERC20 _token, address initialOwner) Ownable(initialOwner) {
        token = _token;
    }

    // ---- Admin (через Timelock позже) ----
    function addSchedule(
        address beneficiary,
        uint128 total,
        uint64 start,
        uint64 cliff,
        uint64 duration
    ) external onlyOwner {
        require(beneficiary != address(0), "bad beneficiary");
        require(total > 0 && duration > 0, "bad params");
        schedules[beneficiary].push(Schedule({
            total: total,
            claimed: 0,
            start: start,
            cliff: cliff,
            duration: duration,
            active: true
        }));
        emit ScheduleAdded(beneficiary, schedules[beneficiary].length - 1, total, start, cliff, duration);
    }

    function toggleSchedule(address beneficiary, uint256 id, bool active) external onlyOwner {
        schedules[beneficiary][id].active = active;
        emit ScheduleToggled(beneficiary, id, active);
    }

    // ---- Beneficiary ----
    function claim(uint256 id) external nonReentrant {
        Schedule storage s = schedules[msg.sender][id];
        require(s.active, "inactive");
        uint128 releasable = _releasableAmount(s);
        require(releasable > 0, "nothing");
        s.claimed += releasable;
        token.safeTransfer(msg.sender, releasable);
        emit Claimed(msg.sender, id, releasable);
    }

    function vested(address beneficiary, uint256 id) external view returns (uint128) {
        Schedule memory s = schedules[beneficiary][id];
        return _vestedAmount(s);
    }

    function releasable(address beneficiary, uint256 id) external view returns (uint128) {
        Schedule memory s = schedules[beneficiary][id];
        return _releasableAmount(s);
    }

    // ---- Internal math ----
    function _releasableAmount(Schedule memory s) internal view returns (uint128) {
        uint128 v = _vestedAmount(s);
        return v > s.claimed ? v - s.claimed : 0;
    }

    function _vestedAmount(Schedule memory s) internal view returns (uint128) {
        uint64 t = uint64(block.timestamp);
        if (t < s.cliff) return 0;
        if (t >= s.start + s.duration) return s.total;
        if (t <= s.start) return 0;
        uint256 elapsed = t - s.start;
        return uint128(uint256(s.total) * elapsed / s.duration);
    }
}

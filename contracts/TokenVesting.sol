// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title TokenVesting — sample token vesting / lock contract
/// @notice Lock ERC-20 tokens for a beneficiary and release them linearly
///         over time after an optional cliff. Commonly used for team and
///         investor allocations so tokens unlock gradually, not all at once.
///         Written as a portfolio sample.
contract TokenVesting {
    IERC20 public token;
    address public beneficiary;
    address public owner;

    uint256 public start;       // vesting start timestamp
    uint256 public cliff;       // seconds after start before anything unlocks
    uint256 public duration;    // total vesting period in seconds
    uint256 public released;    // amount already paid out
    bool public revocable;
    bool public revoked;

    event TokensReleased(uint256 amount);
    event VestingRevoked();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    constructor(
        address token_,
        address beneficiary_,
        uint256 start_,
        uint256 cliffSeconds_,
        uint256 durationSeconds_,
        bool revocable_
    ) {
        require(beneficiary_ != address(0), "Zero address");
        require(durationSeconds_ > 0, "Duration is zero");
        require(cliffSeconds_ <= durationSeconds_, "Cliff longer than duration");
        token = IERC20(token_);
        beneficiary = beneficiary_;
        owner = msg.sender;
        start = start_;
        cliff = cliffSeconds_;
        duration = durationSeconds_;
        revocable = revocable_;
    }

    /// @notice Total tokens currently held by this contract + already released.
    function totalAllocation() public view returns (uint256) {
        return token.balanceOf(address(this)) + released;
    }

    /// @notice Amount vested (unlocked) at the current time.
    function vestedAmount() public view returns (uint256) {
        if (revoked) return released;
        uint256 total = totalAllocation();
        if (block.timestamp < start + cliff) return 0;
        if (block.timestamp >= start + duration) return total;
        return (total * (block.timestamp - start)) / duration;
    }

    /// @notice Amount that can be released right now.
    function releasableAmount() public view returns (uint256) {
        return vestedAmount() - released;
    }

    /// @notice Release the currently unlocked tokens to the beneficiary.
    function release() external {
        require(!revoked, "Vesting revoked");
        uint256 amount = releasableAmount();
        require(amount > 0, "Nothing to release");
        released += amount;
        require(token.transfer(beneficiary, amount), "Transfer failed");
        emit TokensReleased(amount);
    }

    /// @notice Owner can revoke (if revocable): unvested tokens return to the
    ///         owner, vested-but-unreleased tokens go to the beneficiary.
    function revoke() external onlyOwner {
        require(revocable, "Not revocable");
        require(!revoked, "Already revoked");
        revoked = true;
        uint256 vested = vestedAmount();
        if (vested > released) {
            uint256 due = vested - released;
            released = vested;
            require(token.transfer(beneficiary, due), "Transfer failed");
        }
        uint256 remaining = token.balanceOf(address(this));
        if (remaining > 0) {
            require(token.transfer(owner, remaining), "Transfer failed");
        }
        emit VestingRevoked();
    }
}

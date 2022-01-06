// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

/// @title CERC20
/// @author Compound Labs and Rari Capital
/// @notice Minimal Compound/Fuse ERC20 cToken interface.
interface CERC20 {
    /// @notice Returns the underlying ERC20 token the cToken accepts.
    /// @return The underlying ERC20 token the cToken accepts.
    function underlying() external view returns (ERC20);

    /// @notice Deposit a specific amount of underlying tokens into the cToken.
    /// @param amount The amount of underlying tokens to deposit.
    /// @return An error code, or 0 if the deposit was successful.
    function mint(uint256 amount) external returns (uint256);

    /// @notice Borrow a specific amount of underlying tokens from the cToken.
    /// @param amount The amount of underlying tokens to borrow.
    /// @return An error code, or 0 if the borrow was successful.
    function borrow(uint256 amount) external returns (uint256);

    /// @notice Repay a specific amount of borrowed underlying tokens.
    /// @param amount The amount of underlying tokens to repay.
    /// @return An error code, or 0 if the repay was successful.
    function repayBorrow(uint256 amount) external returns (uint256);

    /// @notice Withdraws a specific amount of underlying tokens from the cToken.
    /// @param amount The amount of underlying tokens to withdraw.
    /// @return An error code, or 0 if the withdrawal was successful.
    function redeemUnderlying(uint256 amount) external returns (uint256);

    /// @notice Returns a user's cToken balance in underlying tokens.
    /// @param user The user to get the underlying balance of.
    /// @return The user's cToken balance in underlying tokens.
    /// @dev May mutate the state of the cToken by accruing interest.
    function balanceOfUnderlying(address user) external returns (uint256);

    /// @notice Returns a user's cToken borrow balance in underlying tokens.
    /// @param user The user to get the borrow balance of.
    /// @return The user's cToken borrow balance in underlying tokens.
    function borrowBalanceCurrent(address user) external returns (uint256);
}

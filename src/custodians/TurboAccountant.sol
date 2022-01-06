// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {TurboSafe} from "../TurboSafe.sol";

/// @title Turbo Accountant
/// @author Transmissions11
/// @notice Fee determination module for Turbo Safes.
contract TurboAccountant is Auth {
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Accountant contract.
    /// @param _owner The owner of the Accountant.
    /// @param _authority The Authority of the Accountant.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                        DEFAULT FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The default fee on Safe interest taken by the protocol.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    uint256 public defaultFeePercentage;

    /// @notice Emitted when the default fee percentage is updated.
    /// @param newDefaultFeePercentage The new default fee percentage.
    event DefaultFeePercentageUpdated(uint256 newDefaultFeePercentage);


    /// @notice Sets the default fee percentage.
    /// @param newDefaultFeePercentage The new default fee percentage.
    function setDefaultFeePercentage(uint256 newDefaultFeePercentage) external {
        // A fee percentage over 100% makes no sense.
        require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the default fee percentage.
        defaultFeePercentage = newDefaultFeePercentage;

        emit DefaultFeePercentageUpdated(newDefaultFeePercentage);
    }

    /*///////////////////////////////////////////////////////////////
                        CUSTOM FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps Safes to their custom fees on interest taken by the protocol.
    /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    mapping(address => uint256) public getCustomFeePercentageForSafe;

    /// @notice Emitted when a Safe's custom fee percentage is updated.
    /// @param safe The Safe who's custom fee percentage was updated.
    /// @param newFeePercentage The new custom fee percentage.
    event CustomFeePercentageUpdated(TurboSafe safe, uint256 newFeePercentage);

    /// @notice Sets a Safe's custom fee percentage.
    /// @param safe The Safe to set the custom fee percentage for.
    /// @param newFeePercentage The new custom fee percentage for the Safe.
    function setCustomFeePercentageForSafe(TurboSafe safe, uint256 newFeePercentage) external requiresAuth {
        // A fee percentage over 100% makes no sense.
        require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the custom fee percentage for the Safe.
        getCustomFeePercentageForSafe[safe] = newFeePercentage;

        emit CustomFeePercentageUpdated(safe, newFeePercentage);
    }

    /*///////////////////////////////////////////////////////////////
                          ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the fee on interest taken by the protocol for a Safe.
    /// @param safe The Safe to get the fee percentage for.
    /// @return The fee percentage for the Safe.
    function getFeePercentageForSafe(TurboSafe safe) external view returns (uint256) {
        // If a custom fee percentage is set for the Safe, return it.
        if (getCustomFeePercentageForSafe[safe] != 0) return getCustomFeePercentageForSafe[safe];

        // Otherwise, return the default fee percentage.
        return defaultFeePercentage;
    }
}

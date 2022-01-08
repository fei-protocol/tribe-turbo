// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Auth, Authority} from "solmate/auth/Auth.sol";

import {TurboSafe} from "../TurboSafe.sol";

/// @title Turbo Impounder
/// @author Transmissions11
/// @notice Authorization module for Turbo Safe impounding.
contract TurboImpounder is Auth {
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Impounder contract.
    /// @param _owner The owner of the Impounder.
    /// @param _authority The Authority of the Impounder.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                            WHITELIST STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps users to a boolean indicating if they are whitelisted to impound any Safe.
    mapping(address => bool) isWhitelistedToImpoundAll;

    /// @notice Maps users to a boolean indicating if they are whitelisted to impound a specific Safe.
    mapping(address => mapping(TurboSafe => bool)) isWhitelistedToImpoundSafe;

    /// @notice Emitted when whether a user is whitelisted to impound any Safe is updated.
    /// @param user The user whose whitelist status was updated.
    /// @param isWhitelisted Whether the user was whitelisted to impound any Safe.
    event WhitelistToImpoundAllStatusUpdated(address indexed user, bool isWhitelisted);

    /// @notice Sets the whitelisted status of a user to impound any Safe.
    /// @param user The user to set the whitelisted status of.
    /// @param isWhitelisted Whether the user should be whitelisted to impound all safes.
    function setIsWhitelistedToImpoundAll(address user, bool isWhitelisted) external requiresAuth {
        isWhitelistedToImpoundAll[user] = isWhitelisted;

        emit WhitelistToImpoundAllStatusUpdated(user, isWhitelisted);
    }

    /// @notice Emitted when whether a user is whitelisted to impound a specific Safe is updated.
    /// @param user The user whose whitelist status was updated.
    /// @param safe The Safe the user was or was not be whitelisted to impound.
    /// @param isWhitelisted Whether the user was whitelisted to impound the Safe.
    event WhitelistToImpoundSafeStatusUpdated(address indexed user, TurboSafe indexed safe, bool isWhitelisted);

    /// @notice Sets the whitelisted status of a user to impound a specific Safe.
    /// @param user The user to set the whitelisted status of.
    /// @param safe The Safe the user should or should not be whitelisted to impound.
    /// @param isWhitelisted Whether the user should be whitelisted to impound the Safe.
    function setIsWhitelistedToImpoundSafe(
        address user,
        TurboSafe safe,
        bool isWhitelisted
    ) external requiresAuth {
        isWhitelistedToImpoundSafe[user][safe] = isWhitelisted;

        emit WhitelistToImpoundSafeStatusUpdated(user, safe, isWhitelisted);
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether a user is authorized to impound a Safe.
    /// @param user The user to check is authorized to impound an amount of underlying tokens from the Safe.
    /// @param safe The Safe to check if the user is authorized for.
    /// @param underlyingAmount The amount of the underlying asset to check the user is authorized to impound.
    /// @return Whether the user is authorized to impound a specific amount of underlying tokens from the Safe.
    function canImpoundSafe(
        address user,
        TurboSafe safe,
        uint256 underlyingAmount
    ) external view returns (uint256) {
        return isWhitelistedToImpoundAll[user] || isWhitelistedToImpoundSafe[user][safe];
    }
}

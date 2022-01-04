// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {CERC20} from "./external/CERC20.sol";

import {TurboSafe} from "./TurboSafe.sol";

/// @title Turbo Custodian
/// @author Transmissions11
/// @notice Authorization module for Turbo Safes.
contract TurboCustodian {
    /*///////////////////////////////////////////////////////////////
                         AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether a given Safe is allowed to deposit
    /// a specific amount of Fei into a specific cToken contract.
    /// @param safe The Safe to check is allowed.
    /// @param cToken The cToken to check is allowed.
    /// @param feiAmount The amount of Fei to check is allowed.
    function isAuthorizedToBoost(
        TurboSafe safe,
        CERC20 cToken,
        uint256 feiAmount
    ) external pure returns (bool) {
        return true; // TODO: Implement.
    }

    /// @notice Returns whether a given user is allowed to impound
    /// a specific amount of collateral from a specific Safe contract.
    /// @param user The user to check is authorized to impound.
    /// @param safe The Safe to check the user is allowed to impound from.
    /// @param underlyingAmount The amount of underlying tokens to check is allowed.
    function isAuthorizedToImpound(
        address user,
        TurboSafe safe,
        uint256 underlyingAmount
    ) external pure returns (bool) {
        return true; // TODO: Implement.
    }
}

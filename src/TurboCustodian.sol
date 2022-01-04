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

    function isAuthorizedToBoost(
        TurboSafe safe,
        CERC20 cToken,
        uint256 feiAmount
    ) external pure returns (bool) {
        return true; // todo
    }

    function isAuthorizedToImpound(
        address user,
        TurboSafe safe,
        ERC20 underlying,
        uint256 underlyingAmount
    ) external pure returns (bool) {
        return true; // todo
    }
}

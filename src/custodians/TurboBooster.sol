// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Auth, Authority} from "solmate/auth/Auth.sol";

import {CERC20} from "../interfaces/CERC20.sol";

import {TurboSafe} from "../TurboSafe.sol";
import {TurboMaster} from "../TurboMaster.sol";

/// @title Turbo Booster
/// @author Transmissions11
/// @notice Boost authorization module.
contract TurboBooster is Auth {
    /*///////////////////////////////////////////////////////////////
                             MASTER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Master contract used by the Booster.
    TurboMaster public immutable master;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Booster contract.
    /// @param _master The Master used by the Booster.
    /// @param _owner The owner of the Booster.
    /// @param _authority The Authority of the Booster.
    constructor(
        TurboMaster _master,
        address _owner,
        Authority _authority
    ) Auth(_owner, _authority) {
        master = _master;
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATOIN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether a Safe is authorized to boost a Vault.
    /// @param safe The Safe to check is authorized to boost the Vault.
    /// @param vault The Vault to check the Safe is authorized to boost.
    /// @param feiAmount The amount of Fei asset to check the Safe is authorized boost the Vault with.
    /// @return Whether the Safe is authorized to boost the Vault with the given amount of Fei asset.
    function canSafeBoostVault(
        TurboSafe safe,
        CERC20 vault,
        uint256 feiAmount
    ) external view returns (uint256) {
        // TODO: Call the master, check caps, n such.
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {ERC4626} from "../interfaces/ERC4626.sol";

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
                      GLOBAL FREEZE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Whether boosting is currently frozen.
    bool public frozen;

    /// @notice Emitted when boosting is frozen or unfrozen.
    /// @param user The user who froze or unfroze boosting.
    /// @param frozen Whether boosting is now frozen.
    event FreezeStatusUpdated(address indexed user, bool frozen);

    /// @notice Sets whether boosting is frozen.
    /// @param freeze Whether boosting will be frozen.
    function setFreezeStatus(bool freeze) external requiresAuth {
        // Update freeze status.
        frozen = freeze;

        emit FreezeStatusUpdated(msg.sender, frozen);
    }

    /*///////////////////////////////////////////////////////////////
                         BOOST CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps Safes to the cap on the amount of Fei used to boost them.
    mapping(TurboSafe => uint256) public getBoostCapForSafe;

    /// @notice Emitted when a Safe's boost cap is updated.
    /// @param safe The Safe who's boost cap was updated.
    /// @param newBoostCap The new boost cap for the Safe.
    event BoostCapUpdatedForSafe(address indexed user, TurboSafe indexed safe, uint256 newBoostCap);

    /// @notice Sets a Safe's boost cap.
    /// @param safe The Safe to set the boost cap for.
    /// @param newBoostCap The new boost cap for the Safe.
    function setBoostCapForSafe(TurboSafe safe, uint256 newBoostCap) external requiresAuth {
        // Update the boost cap for the Safe.
        getBoostCapForSafe[safe] = newBoostCap;

        emit BoostCapUpdatedForSafe(msg.sender, safe, newBoostCap);
    }

    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATOIN LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns whether a Safe is authorized to boost a vault.
    /// @param safe The Safe to check is authorized to boost the vault.
    /// @param vault The vault to check the Safe is authorized to boost.
    /// @param feiAmount The amount of Fei asset to check the Safe is authorized boost the vault with.
    /// @return Whether the Safe is authorized to boost the vault with the given amount of Fei asset.
    function canSafeBoostVault(
        TurboSafe safe,
        ERC4626 vault,
        uint256 feiAmount
    ) external view returns (bool) {
        // Ensure new boosts aren't frozen.
        require(!frozen, "FROZEN");

        // Ensure the boost would not result in the total boost amount exceeding the vault's cap.
        require(getBoostCapForSafe[safe] > (feiAmount + master.getTotalBoostedForVault(vault)), "EXCEEDS_CAP");
    }
}

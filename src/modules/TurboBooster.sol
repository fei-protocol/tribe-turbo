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
                     VAULT BOOST CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps vaults to the cap on the amount of Fei used to boost them.
    mapping(ERC4626 => uint256) public getBoostCapForVault;

    /// @notice Emitted when a vault's boost cap is updated.
    /// @param vault The vault who's boost cap was updated.
    /// @param newBoostCap The new boost cap for the vault.
    event BoostCapUpdatedForVault(address indexed user, ERC4626 indexed vault, uint256 newBoostCap);

    /// @notice Sets a vault's boost cap.
    /// @param vault The vault to set the boost cap for.
    /// @param newBoostCap The new boost cap for the vault.
    function setBoostCapForVault(ERC4626 vault, uint256 newBoostCap) external requiresAuth {
        // Update the boost cap for the vault.
        getBoostCapForVault[vault] = newBoostCap;

        emit BoostCapUpdatedForVault(msg.sender, vault, newBoostCap);
    }

    /*///////////////////////////////////////////////////////////////
                     COLLATERAL BOOST CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps collateral types to the cap on the amount of Fei boosted against them.
    mapping(ERC20 => uint256) public getBoostCapForCollateral;

    /// @notice Emitted when a collateral type's boost cap is updated.
    /// @param collateral The collateral type who's boost cap was updated.
    /// @param newBoostCap The new boost cap for the collateral type.
    event BoostCapUpdatedForCollateral(address indexed user, ERC20 indexed collateral, uint256 newBoostCap);

    /// @notice Sets a collateral type's boost cap.
    /// @param collateral The collateral type to set the boost cap for.
    /// @param newBoostCap The new boost cap for the collateral type.
    function setBoostCapForCollateral(ERC20 collateral, uint256 newBoostCap) external requiresAuth {
        // Update the boost cap for the collateral type.
        getBoostCapForCollateral[collateral] = newBoostCap;

        emit BoostCapUpdatedForCollateral(msg.sender, collateral, newBoostCap);
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
        ERC20 underlying = safe.underlying();

        return
            !frozen &&
            getBoostCapForVault[vault] > (feiAmount + master.getTotalBoostedForVault(vault)) &&
            getBoostCapForCollateral[underlying] > (feiAmount + master.getTotalBoostedAgainstCollateral(underlying));
    }
}

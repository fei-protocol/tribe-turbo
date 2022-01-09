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
                     DEFAULT BOOST CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The default cap of Fei used to boost any vault.
    uint256 public defaultBoostCap;

    /// @notice Emitted when the default boost cap is updated.
    /// @param newDefaultBoostCap The new default boost cap.
    event DefaultBoostCapUpdated(address indexed user, uint256 newDefaultBoostCap);

    /// @notice Sets the default boost cap.
    /// @param newDefaultBoostCap The new default boost cap.
    function setDefaultBoostCap(uint256 newDefaultBoostCap) external {
        // Update the default boost cap.
        defaultBoostCap = newDefaultBoostCap;

        emit DefaultBoostCapUpdated(msg.sender, newDefaultBoostCap);
    }

    /*///////////////////////////////////////////////////////////////
                     CUSTOM BOOST CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps collaterals to the cap on the amount of Fei used to boost them.
    mapping(ERC20 => uint256) public getCustomBoostCapForCollateral;

    /// @notice Maps Safes to the cap on the amount of Fei used to boost them.
    mapping(TurboSafe => uint256) public getCustomBoostCapForSafe;

    /// @notice Emitted when a collateral's custom boost cap is updated.
    /// @param collateral The collateral who's custom boost cap was updated.
    /// @param newBoostCap The new custom boost cap.
    event CustomBoostCapUpdatedForCollateral(address indexed user, ERC20 indexed collateral, uint256 newBoostCap);

    /// @notice Sets a collateral's custom fee percentage.
    /// @param collateral The collateral to set the custom fee percentage for.
    /// @param newFeePercentage The new custom fee percentage for the collateral.
    function setCustomFeePercentageForCollateral(ERC20 collateral, uint256 newFeePercentage) external requiresAuth {
        // A fee percentage over 100% makes no sense.
        require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the custom fee percentage for the Safe.
        getCustomFeePercentageForCollateral[collateral] = newFeePercentage;

        emit CustomFeePercentageUpdatedForCollateral(msg.sender, collateral, newFeePercentage);
    }

    /// @notice Emitted when a Safe's custom boost cap is updated.
    /// @param safe The Safe who's custom boost cap was updated.
    /// @param newBoostCap The new custom boost cap.
    event CustomBoostCapUpdatedForCollateral(address indexed user, TurboSafe indexed safe, uint256 newBoostCap);

    /// @notice Sets a Safe's custom fee percentage.
    /// @param safe The Safe to set the custom fee percentage for.
    /// @param newFeePercentage The new custom fee percentage for the Safe.
    function setCustomFeePercentageForSafe(TurboSafe safe, uint256 newFeePercentage) external requiresAuth {
        // A fee percentage over 100% makes no sense.
        require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

        // Update the custom fee percentage for the Safe.
        getCustomFeePercentageForSafe[safe] = newFeePercentage;

        emit CustomFeePercentageUpdatedForSafe(msg.sender, safe, newFeePercentage);
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
        // TODO: Call the master, check caps, n such.
    }
}

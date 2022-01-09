// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

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

    // TODO: debt caps for vaults

    /*///////////////////////////////////////////////////////////////
                        DEBT CAP CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    // /// @notice Maps Safes to their custom fees on interest taken by the protocol.
    // /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    // mapping(ERC20 => uint256) public getCustomFeePercentageForCollateral;

    // /// @notice Maps Safes to their custom fees on interest taken by the protocol.
    // /// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
    // mapping(TurboSafe => uint256) public getCustomFeePercentageForSafe;

    // /// @notice Emitted when a collateral's custom fee percentage is updated.
    // /// @param collateral The collateral who's custom fee percentage was updated.
    // /// @param newFeePercentage The new custom fee percentage.
    // event CustomFeePercentageUpdatedForCollateral(ERC20 collateral, uint256 newFeePercentage);

    // /// @notice Sets a collateral's custom fee percentage.
    // /// @param collateral The collateral to set the custom fee percentage for.
    // /// @param newFeePercentage The new custom fee percentage for the collateral.
    // function setCustomFeePercentageForCollateral(ERC20 collateral, uint256 newFeePercentage) external requiresAuth {
    //     // A fee percentage over 100% makes no sense.
    //     require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

    //     // Update the custom fee percentage for the Safe.
    //     getCustomFeePercentageForCollateral[collateral] = newFeePercentage;

    //     emit CustomFeePercentageUpdatedForCollateral(collateral, newFeePercentage);
    // }

    // /// @notice Emitted when a Safe's custom fee percentage is updated.
    // /// @param safe The Safe who's custom fee percentage was updated.
    // /// @param newFeePercentage The new custom fee percentage.
    // event CustomFeePercentageUpdatedForSafe(TurboSafe safe, uint256 newFeePercentage);

    // /// @notice Sets a Safe's custom fee percentage.
    // /// @param safe The Safe to set the custom fee percentage for.
    // /// @param newFeePercentage The new custom fee percentage for the Safe.
    // function setCustomFeePercentageForSafe(TurboSafe safe, uint256 newFeePercentage) external requiresAuth {
    //     // A fee percentage over 100% makes no sense.
    //     require(newFeePercentage <= 1e18, "FEE_TOO_HIGH");

    //     // Update the custom fee percentage for the Safe.
    //     getCustomFeePercentageForSafe[safe] = newFeePercentage;

    //     emit CustomFeePercentageUpdatedForSafe(safe, newFeePercentage);
    // }

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate-next/tokens/ERC20.sol";
import {Auth, Authority} from "solmate-next/auth/Auth.sol";
import {SafeTransferLib} from "solmate-next/utils/SafeTransferLib.sol";

import {ERC4626} from "solmate-next/mixins/ERC4626.sol";

import {FuseAdmin} from "./interfaces/FuseAdmin.sol";
import {Comptroller} from "./interfaces/Comptroller.sol";

import {TurboGibber} from "./modules/TurboGibber.sol";
import {TurboBooster} from "./modules/TurboBooster.sol";
import {TurboClerk} from "./modules/TurboClerk.sol";

import {TurboSafe} from "./TurboSafe.sol";

/// @title Turbo Master
/// @author Transmissions11
/// @notice Factory for creating and managing Turbo Safes.
/// @dev Must be authorized to call the Turbo Fuse Pool's FuseAdmin.
contract TurboMaster is Auth {
    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice  The Turbo Fuse Pool the Master and its Safes use.
    Comptroller public immutable pool;

    /// @notice The Fei token on the network.
    ERC20 public immutable fei;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Master contract.
    /// @param _pool The Turbo Fuse Pool the Master will use.
    /// @param _fei The Fei token on the network.
    /// @param _owner The owner of the Master.
    /// @param _authority The Authority of the Master.
    constructor(
        Comptroller _pool,
        ERC20 _fei,
        address _owner,
        Authority _authority
    ) Auth(_owner, _authority) {
        pool = _pool;
        fei = _fei;

        // Prevent the first safe from getting id 0.
        safes.push(TurboSafe(address(0)));
    }

    /*///////////////////////////////////////////////////////////////
                            BOOSTER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Booster module used by the Master and its Safes.
    TurboBooster public booster;

    /// @notice Emitted when the Booster is updated.
    /// @param user The user who triggered the update of the Booster.
    /// @param newBooster The new Booster contract used by the Master.
    event BoosterUpdated(address indexed user, TurboBooster newBooster);

    /// @notice Update the Booster used by the Master.
    /// @param newBooster The new Booster contract to be used by the Master.
    function setBooster(TurboBooster newBooster) external requiresAuth {
        booster = newBooster;

        emit BoosterUpdated(msg.sender, newBooster);
    }

    /*///////////////////////////////////////////////////////////////
                             CLERK STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Clerk module used by the Master and its Safes.
    TurboClerk public clerk;

    /// @notice Emitted when the Clerk is updated.
    /// @param user The user who triggered the update of the Clerk.
    /// @param newClerk The new Clerk contract used by the Master.
    event ClerkUpdated(address indexed user, TurboClerk newClerk);

    /// @notice Update the Clerk used by the Master.
    /// @param newClerk The new Clerk contract to be used by the Master.
    function setClerk(TurboClerk newClerk) external requiresAuth {
        clerk = newClerk;

        emit ClerkUpdated(msg.sender, newClerk);
    }

    /*///////////////////////////////////////////////////////////////
                            GIBBER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Gibber module used by the Master and its Safes.
    TurboGibber public gibber;

    /// @notice Emitted when the Gibber is updated.
    /// @param user The user who triggered the update of the Gibber.
    /// @param newGibber The new Gibber contract used by the Master.
    event GibberUpdated(address indexed user, TurboGibber newGibber);

    /// @notice Update the Gibber used by the Master.
    /// @param newGibber The new Gibber contract to be used by the Master.
    function setGibber(TurboGibber newGibber) external requiresAuth {
        gibber = newGibber;

        emit GibberUpdated(msg.sender, newGibber);
    }

    /*///////////////////////////////////////////////////////////////
                  DEFAULT SAFE AUTHORITY CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The default authority to be used by created Safes.
    Authority public defaultSafeAuthority;

    /// @notice Emitted when the default safe authority is updated.
    /// @param user The user who triggered the update of the default safe authority.
    /// @param newDefaultSafeAuthority The new default authority to be used by created Safes.
    event DefaultSafeAuthorityUpdated(address indexed user, Authority newDefaultSafeAuthority);

    /// @notice Set the default authority to be used by created Safes.
    /// @param newDefaultSafeAuthority The new default safe authority.
    function setDefaultSafeAuthority(Authority newDefaultSafeAuthority) external requiresAuth {
        // Update the default safe authority.
        defaultSafeAuthority = newDefaultSafeAuthority;

        emit DefaultSafeAuthorityUpdated(msg.sender, newDefaultSafeAuthority);
    }

    /*///////////////////////////////////////////////////////////////
                             SAFE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The total Fei currently boosting vaults.
    uint256 public totalBoosted;

    /// @notice Maps Safe addresses to the id they are stored under in the safes array.
    mapping(TurboSafe => uint256) public getSafeId;

    /// @notice Maps vault addresses to the total amount of Fei they've being boosted with.
    mapping(ERC4626 => uint256) public getTotalBoostedForVault;

    /// @notice Maps collateral types to the total amount of Fei boosted by Safes using it as collateral.
    mapping(ERC20 => uint256) public getTotalBoostedAgainstCollateral;

    /// @notice An array of all Safes created by the Master.
    TurboSafe[] public safes;

    /// @notice Returns all Safes created by the Master.
    /// @return An array of all Safes created by the Master.
    /// @dev This is provided because Solidity converts public arrays into index getters,
    /// but we need a way to allow external contracts and users to access the whole array.
    function getAllSafes() external view returns (TurboSafe[] memory) {
        return safes;
    }

    /*///////////////////////////////////////////////////////////////
                          SAFE CREATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Safe is created.
    /// @param user The user who created the Safe.
    /// @param underlying The underlying token of the Safe.
    /// @param safe The newly deployed Safe contract.
    /// @param id The index of the Safe in the safes array.
    event TurboSafeCreated(address indexed user, ERC20 indexed underlying, TurboSafe safe, uint256 id);

    /// @notice Creates a new Turbo Safe which supports a specific underlying token.
    /// @param underlying The ERC20 token that the Safe should accept.
    /// @return safe The newly deployed Turbo Safe which accepts the provided underlying token.
    function createSafe(ERC20 underlying) external requiresAuth returns (TurboSafe safe, uint256 id) {
        // Create a new Safe using the default authority and provided underlying token.
        safe = new TurboSafe(msg.sender, defaultSafeAuthority, underlying);

        // Add the safe to the list of Safes.
        safes.push(safe);

        unchecked {
            // Get the index/id of the new Safe.
            // Cannot underflow, we just pushed to it.
            id = safes.length - 1;
        }

        // Store the id/index of the new Safe.
        getSafeId[safe] = id;

        emit TurboSafeCreated(msg.sender, underlying, safe, id);

        // Prepare a users array to whitelist the Safe.
        address[] memory users = new address[](1);
        users[0] = address(safe);

        // Prepare an enabled array to whitelist the Safe.
        bool[] memory enabled = new bool[](1);
        enabled[0] = true;

        // Whitelist the Safe to access the Turbo Fuse Pool.
        FuseAdmin(pool.admin())._setWhitelistStatuses(users, enabled);
    }

    /*///////////////////////////////////////////////////////////////
                          SAFE CALLBACK LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Callback triggered whenever a Safe boosts a vault.
    /// @param vault The vault that was boosted.
    /// @param feiAmount The amount of Fei used to boost the vault.
    function onSafeBoost(ERC4626 vault, uint256 feiAmount) external {
        // Get the caller as a Safe instance.
        TurboSafe safe = TurboSafe(msg.sender);

        // Ensure the Safe was created by this Master.
        require(getSafeId[safe] != 0, "INVALID_SAFE");

        // Get the Safe's underlying token.
        ERC20 underlying = safe.underlying();

        // Compute the total amount of Fei that will be boosting the vault.
        uint256 newTotalBoostedForVault = getTotalBoostedForVault[vault] + feiAmount;

        // Compute the total amount of Fei boosted that will be boosted the Safe's collateral type.
        uint256 newTotalBoostedAgainstCollateral = getTotalBoostedAgainstCollateral[underlying] + feiAmount;

        // Check with the booster that the Safe is allowed to boost the vault using this amount of Fei.
        require(
            booster.canSafeBoostVault(
                safe,
                underlying,
                vault,
                feiAmount,
                newTotalBoostedForVault,
                newTotalBoostedAgainstCollateral
            ),
            "BOOSTER_REJECTED"
        );

        unchecked {
            // Update the total amount of Fei being using to boost vaults.
            // Overflow is safe because it will be caught when updating the total against collateral.
            totalBoosted += feiAmount;
        }

        // Update the total amount of Fei being using to boost the vault.
        getTotalBoostedForVault[vault] = newTotalBoostedForVault;

        // Update the total amount of Fei boosted against the collateral type.
        getTotalBoostedAgainstCollateral[safe.underlying()] = newTotalBoostedAgainstCollateral;
    }

    /// @notice Callback triggered whenever a Safe withdraws from a vault.
    /// @param vault The vault that was withdrawn from.
    /// @param feiAmount The amount of Fei withdrawn from the vault.
    function onSafeLess(ERC4626 vault, uint256 feiAmount) external {
        // Get the caller as a Safe instance.
        TurboSafe safe = TurboSafe(msg.sender);

        // Ensure the Safe was created by this Master.
        require(getSafeId[safe] != 0, "INVALID_SAFE");

        unchecked {
            // Update the total amount of Fei being using to boost the vault.
            // Cannot underflow as the Safe validated the withdrawal amount before.
            getTotalBoostedForVault[vault] -= feiAmount;

            // Update the total amount of Fei being using to boost vaults.
            // Cannot underflow as the Safe validated the withdrawal amount earlier.
            totalBoosted -= feiAmount;

            // Update the total amount of Fei boosted against the collateral type.
            // Cannot underflow as the Safe validated the withdrawal amount previously.
            getTotalBoostedAgainstCollateral[safe.underlying()] -= feiAmount;
        }
    }

    /*///////////////////////////////////////////////////////////////
                           FEE CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when fees are claimed by an authorized user.
    /// @param user The authorized user who claimed the fees.
    /// @param feiAmount The amount of Fei fees that were claimed.
    event FeesClaimed(address indexed user, uint256 feiAmount);

    /// @notice Claims the fees generated as Fei sent to the Master.
    /// @param feiAmount The amount of Fei fees that should be claimed.
    function claimFees(uint256 feiAmount) external requiresAuth {
        emit FeesClaimed(msg.sender, feiAmount);

        // Transfer the Fei fees to the authorized caller.
        fei.safeTransfer(msg.sender, feiAmount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Comptroller} from "./interfaces/Comptroller.sol";

import {TurboBooster} from "./custodians/TurboBooster.sol";
import {TurboImpounder} from "./custodians/TurboImpounder.sol";
import {TurboAccountant} from "./custodians/TurboAccountant.sol";

import {TurboSafe} from "./TurboSafe.sol";

/// @title Turbo Master
/// @author Transmissions11
/// @notice Factory for creating and managing Turbo Safes.
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
    }

    /*///////////////////////////////////////////////////////////////
                            BOOSTER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Booster custodian used by the Master and its Safes.
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
                            ACCOUNTANT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Accountant custodian used by the Master and its Safes.
    TurboAccountant public accountant;

    /// @notice Emitted when the Accountant is updated.
    /// @param user The user who triggered the update of the Accountant.
    /// @param newAccountant The new Accountant contract used by the Master.
    event AccountantUpdated(address indexed user, TurboAccountant newAccountant);

    /// @notice Update the Accountant used by the Master.
    /// @param newAccountant The new Accountant contract to be used by the Master.
    function setAccountant(TurboAccountant newAccountant) external requiresAuth {
        accountant = newAccountant;

        emit AccountantUpdated(msg.sender, newAccountant);
    }

    /*///////////////////////////////////////////////////////////////
                           IMPOUNDER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Impounder custodian used by the Master and its Safes.
    TurboImpounder public impounder;

    /// @notice Emitted when the Impounder is updated.
    /// @param user The user who triggered the update of the Impounder.
    /// @param newImpounder The new Impounder contract used by the Master.
    event ImpounderUpdated(address indexed user, TurboImpounder newImpounder);

    /// @notice Update the Impounder used by the Master.
    /// @param newImpounder The new Impounder contract to be used by the Master.
    function setImpounder(TurboImpounder newImpounder) external requiresAuth {
        impounder = newImpounder;

        emit ImpounderUpdated(msg.sender, newImpounder);
    }

    /*///////////////////////////////////////////////////////////////
                             SAFE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Maps Safe addresses to a boolean confirming they exist.
    mapping(TurboSafe => bool) public isSafe;

    /// @notice Maps Vault addresses to the total amount of Fei they've been boosted.
    mapping(CERC20 => uint256) public getTotalBoostedForVault;

    /*///////////////////////////////////////////////////////////////
                          SAFE CREATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a new Safe is created.
    /// @param user The user who created the Safe.
    /// @param underlying The underlying token of the Safe.
    /// @param safe The newly deployed Safe contract.
    event TurboSafeCreated(address indexed user, ERC20 indexed underlying, TurboSafe safe);

    /// @notice Creates a new Turbo Safe which supports a specific underlying token.
    /// @param underlying The ERC20 token that the Safe should accept.
    /// @return safe The newly deployed Turbo Safe which accepts the provided underlying token.
    function createSafe(ERC20 underlying) external requiresAuth returns (TurboSafe safe) {
        safe = new TurboSafe(msg.sender, underlying);

        isSafe[safe] = true;

        // TODO: Authorize the Safe to the Turbo Fuse Pool.

        emit TurboSafeCreated(msg.sender, underlying, safe);
    }

    /*///////////////////////////////////////////////////////////////
                          SAFE CALLBACK LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Callback triggered whenever a Safe boosts a Vault.
    /// @param safe The Turbo Safe that boosted the Vault.
    /// @param vault The Vault that was boosted.
    /// @param feiAmount The amount of Fei used to boost the Vault.
    function onSafeBoost(
        TurboSafe safe,
        CERC20 vault,
        uint256 feiAmount
    ) external {
        require(isSafe[safe], "INVALID_SAFE");

        getTotalBoostedForVault[vault] += amount;
    }

    /// @notice Callback triggered whenever a Safe withdraws from a Vault.
    /// @param safe The Turbo Safe that withdrew from the Vault.
    /// @param vault The Vault that was withdrawn from.
    /// @param feiAmount The amount of Fei withdrawn from the Vault.
    function onSafeLess(
        TurboSafe safe,
        CERC20 vault,
        uint256 feiAmount
    ) external {
        require(isSafe[safe], "INVALID_SAFE");

        getTotalBoostedForVault[vault] -= amount;
    }

    /*///////////////////////////////////////////////////////////////
                         FEE RECLAMATION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when fees are reclaimed by an authorized user.
    /// @param user The authorized user who reclaimed the fees.
    /// @param feiAmount The amount of Fei fees that were reclaimed.
    event FeesReclaimed(address indexed user, uint256 feiAmount);

    /// @notice Reclaims the fees generated as Fei sent to the Master.
    /// @param feiAmount The amount of Fei fees that should be reclaimed.
    function reclaimFees(uint256 feiAmount) external requiresAuth {
        emit FeesReclaimed(msg.sender, feiAmount);

        // Transfer the Fei fees to the authorized caller.
        fei.safeTransfer(msg.sender, feiAmount);
    }
}

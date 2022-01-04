// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Comptroller} from "./external/Comptroller.sol";

import {TurboCustodian} from "./TurboCustodian.sol";

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
                           CUSTODIAN STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the Custodian is updated.
    /// @param user The user who triggered the update of the Custodian.
    /// @param newCustodian The new Custodian contract used by the Master.
    event CustodianUpdated(address indexed user, TurboCustodian newCustodian);

    /// @notice The Custodian contract used by the Master and its Safes.
    TurboCustodian public custodian;

    /// @notice Update the Custodian used by the Master.
    /// @param newCustodian The new Custodian contract to be used by the Master.
    function setCustodian(TurboCustodian newCustodian) external requiresAuth {
        custodian = newCustodian;

        emit CustodianUpdated(msg.sender, custodian);
    }

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

        // TODO: Authorize the safe to the Turbo Fuse Pool.

        emit TurboSafeCreated(msg.sender, underlying, safe);
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

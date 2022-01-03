// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Comptroller} from "./external/Comptroller.sol";

import {TurboCustodian} from "./TurboCustodian.sol";

import {TurboSafe} from "./TurboSafe.sol";

contract TurboMaster is Auth {
    using SafeTransferLib for ERC20;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    Comptroller public immutable pool;

    ERC20 public immutable fei;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

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

    event CustodianUpdated(address indexed user, TurboCustodian newCustodian);

    TurboCustodian public custodian;

    function setCustodian(TurboCustodian _custodian) external requiresAuth {
        custodian = _custodian;

        emit CustodianUpdated(msg.sender, custodian);
    }

    /*///////////////////////////////////////////////////////////////
                          SAFE CREATION LOGIC
    //////////////////////////////////////////////////////////////*/

    event TurboSafeCreated(address indexed user, ERC20 indexed underlying, TurboSafe safe);

    function createSafe(ERC20 underlying) external requiresAuth returns (TurboSafe safe) {
        safe = new TurboSafe{salt: bytes32(0)}(msg.sender, underlying);

        emit TurboSafeCreated(msg.sender, underlying, safe);
    }

    /*///////////////////////////////////////////////////////////////
                         FEE RECLAMATION LOGIC
    //////////////////////////////////////////////////////////////*/

    event FeesReclaimed(address indexed user, uint256 feiAmount);

    function reclaimFees(uint256 feiAmount) external requiresAuth {
        emit FeesReclaimed(msg.sender, feiAmount);

        fei.safeTransfer(msg.sender, feiAmount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {Comptroller} from "./external/Comptroller.sol";

import {TurboSafe} from "./TurboSafe.sol";

contract TurboMaster {
    Comptroller public immutable boostPool;

    constructor(Comptroller _boostPool) public {
        boostPool = _boostPool;
    }

    event TurboSafeCreated(address indexed user, ERC20 indexed underlying, TurboSafe safe);

    function createSafe(ERC20 underlying) external returns (TurboSafe safe) {
        safe = new TurboSafe{salt: bytes32(0)}(msg.sender, underlying);

        // TODO: whitelist to boost pool if sender is allowed? who do we whitelist?

        emit TurboSafeCreated(msg.sender, underlying, safe);
    }
}

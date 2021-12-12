// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {BoostSafe} from "./BoostSafe.sol";

contract BoostMaster {
    event BoostSafeCreated(address indexed creator, BoostSafe safe);

    function createSafe() external returns (BoostSafe safe) {
        safe = new BoostSafe();

        emit BoostSafeCreated(msg.sender, safe);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {TurboSafe} from "./TurboSafe.sol";

contract TurboMaster {
    event TurboSafeCreated(address indexed creator, TurboSafe safe);

    function createSafe() external returns (TurboSafe safe) {
        safe = new TurboSafe();

        emit TurboSafeCreated(msg.sender, safe);
    }
}

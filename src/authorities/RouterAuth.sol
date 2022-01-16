// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import {Auth, Authority} from "solmate-next/auth/Auth.sol";

/**
 @title an auth module for routers
 */
abstract contract RouterAuth {

    modifier authenticate(Auth target, bytes4 sig) {
        Authority auth = target.authority();

        require((address(auth) != address(0) && auth.canCall(msg.sender, address(target), sig)) || msg.sender == target.owner(), "not authed");

        _;
    }
}
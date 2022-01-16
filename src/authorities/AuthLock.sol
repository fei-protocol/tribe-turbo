// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;
import {Auth, Authority} from "solmate-next/auth/Auth.sol";

abstract contract AuthLock {
    
    uint256 private constant _NOT_AUTHED = 0;
    uint256 private constant _AUTHED = 1;

    mapping(Auth => mapping(bytes4 => uint256)) private _status;

    modifier authLock(Auth target, bytes4 sig) {
        if(_status[target][sig] == _NOT_AUTHED) {
            Authority auth = target.authority();

            require((address(auth) != address(0) && auth.canCall(msg.sender, address(target), sig)) || msg.sender == target.owner(), "AuthLock: not authed");
            _status[target][sig] = _AUTHED;
        }

        _;
        
        _status[target][sig] = _NOT_AUTHED;
    }
}
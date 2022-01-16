// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Auth, Authority} from "solmate-next/auth/Auth.sol";

/// @notice An authority which whitelists a router by default
contract RouterAuthority is Authority {
    
    event TargetCustomAuthorityUpdated(address indexed target, address indexed customAuthority);

    address immutable router;

    constructor(address _router) {
        router = _router;
    }

    /*///////////////////////////////////////////////////////////////
                       CUSTOM TARGET AUTHORITY STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => Authority) public getTargetCustomAuthority;

    function setTargetCustomAuthority(address target, Authority customAuthority) public {
        require(isAuthorized(msg.sender, target, msg.sig), "Auth");

        getTargetCustomAuthority[target] = customAuthority;

        emit TargetCustomAuthorityUpdated(target, address(customAuthority));
    }


    /*///////////////////////////////////////////////////////////////
                          AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view override returns (bool) {
        return user == router || isAuthorized(user, target, functionSig);
    }

    function isAuthorized(address user, address target, bytes4 functionSig) internal view returns(bool) { 
        Authority customAuthority = getTargetCustomAuthority[target];
        return msg.sender == Auth(target).owner() || ((address(customAuthority) != address(0)) && customAuthority.canCall(user, target, functionSig));
    }
}
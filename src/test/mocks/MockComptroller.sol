// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate-next/tokens/ERC20.sol";

import {CERC20} from "libcompound/interfaces/CERC20.sol";

import {Comptroller} from "../../interfaces/Comptroller.sol";

contract MockComptroller is Comptroller {
    /*///////////////////////////////////////////////////////////////
                             STRATEGY LOGIC
    //////////////////////////////////////////////////////////////*/

    mapping(ERC20 => CERC20) public override cTokensByUnderlying;

    address public override admin;

    /*///////////////////////////////////////////////////////////////
                             MOCK LOGIC
    //////////////////////////////////////////////////////////////*/

    function setAdmin(address newAdmin) public {
        admin = newAdmin;
    }

    function mapUnderlyingToCToken(ERC20 underlying, CERC20 cToken) public {
        cTokensByUnderlying[underlying] = cToken;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {CERC20} from "./CERC20.sol";

interface Comptroller {
    function cTokensByUnderlying(ERC20) external view returns (CERC20);
}

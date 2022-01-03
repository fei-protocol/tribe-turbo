// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

interface CERC20 {
    function underlying() external view returns (ERC20);

    function mint(uint256 amount) external returns (uint256);

    function borrow(uint256 amount) external returns (uint256);

    function repayBorrow(uint256 amount) external returns (uint256);

    function redeemUnderlying(uint256 amount) external returns (uint256);

    function balanceOfUnderlying(address user) external returns (uint256);

    function borrowBalanceCurrent(address user) external returns (uint256);
}

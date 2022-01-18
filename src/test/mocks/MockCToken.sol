// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";

import {CERC20} from "libcompound/interfaces/CERC20.sol";
import {InterestRateModel} from "libcompound/interfaces/InterestRateModel.sol";

contract MockCToken is CERC20 {
    function underlying() external view override returns (ERC20) {}

    function totalBorrows() external view override returns (uint256) {}

    function totalFuseFees() external view override returns (uint256) {}

    function totalReserves() external view override returns (uint256) {}

    function exchangeRateCurrent() external override returns (uint256) {}

    function totalAdminFees() external view override returns (uint256) {}

    function fuseFeeMantissa() external view override returns (uint256) {}

    function mint(uint256 amount) external override returns (uint256) {}

    function borrow(uint256 amount) external override returns (uint256) {}

    function adminFeeMantissa() external view override returns (uint256) {}

    function exchangeRateStored() external view override returns (uint256) {}

    function accrualBlockNumber() external view override returns (uint256) {}

    function repayBorrow(uint256 amount) external override returns (uint256) {}

    function reserveFactorMantissa() external view override returns (uint256) {}

    function redeemUnderlying(uint256 amount) external override returns (uint256) {}

    function borrowBalanceCurrent(address user) external override returns (uint256) {}

    function repayBorrowBehalf(address, uint256) external override returns (uint256) {}

    function balanceOfUnderlying(address) external override returns (uint256) {}

    function interestRateModel() external view override returns (InterestRateModel) {}

    function initialExchangeRateMantissa() external view override returns (uint256) {}
}

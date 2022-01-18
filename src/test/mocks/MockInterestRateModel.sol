// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {InterestRateModel} from "libcompound/interfaces/InterestRateModel.sol";

contract MockInterestRateModel is InterestRateModel {
    function getBorrowRate(
        uint256,
        uint256,
        uint256
    ) external pure returns (uint256) {
        return 0;
    }

    function getSupplyRate(
        uint256,
        uint256,
        uint256,
        uint256
    ) external pure returns (uint256) {
        return 0;
    }
}

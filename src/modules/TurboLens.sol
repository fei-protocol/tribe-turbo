// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

import {PriceFeed, Comptroller} from "../interfaces/Comptroller.sol";
import {TurboClerk} from "./TurboClerk.sol";
import {TurboBooster} from "./TurboBooster.sol";

import {TurboMaster, TurboSafe} from "../TurboMaster.sol";

interface UncompliantERC4626 {
    function previewRedeem(uint shares) external returns(uint);
}

/// @title Turbo Lens
contract TurboLens {
    Comptroller public immutable pool;

    TurboMaster public immutable master;

    struct StrategyInfo {
        /// @notice the fei strategy boosted by the safe
        ERC4626 strategy;
        
        /// @notice the amount of fei boosted by the safe to this strategy
        uint256 boostedAmount;
        
        /// @notice the amount of fei held by the safe in this strategy
        uint256 feiAmount;
    }

    struct SafeInfo {
        /// @notice the safe collateral
        ERC20 collateralAsset;

        /// @notice the balance of collateral assets held by the safe
        uint256 collateralAmount;
        
        /// @notice the collateral value of assets
        uint256 collateralValue;

        /// @notice the FEI debt held by safe
        uint256 debtAmount;

        /// @notice the value of FEI deby held by safe
        uint256 debtValue;

        /// @notice the total FEI boosted value
        uint256 boostedAmount;

        /// @notice the total amount of FEI boosted by the vault
        uint256 feiAmount;

        StrategyInfo[] strategyInfo;
    }

    constructor (TurboMaster _master) {
        master = _master;
        pool = _master.pool();
    }

    function getAllUserSafes(address owner) external returns (SafeInfo[] memory) {

    }

    function getSafeInfo(TurboSafe safe) external returns(SafeInfo memory) {
        TurboBooster booster = master.booster();
        ERC4626[] memory strategies = booster.getBoostableVaults();
        return _getSafeInfo(safe, strategies, pool.oracle());
    }

    function _getSafeInfo(TurboSafe safe, ERC4626[] memory strategies, PriceFeed oracle) internal returns (SafeInfo memory) {
        StrategyInfo[] memory info = new StrategyInfo[](strategies.length);

        uint256 totalFeiAmount;

        for (uint256 i = 0; i < strategies.length; i++) {
            ERC4626 strategy = strategies[i];
            uint256 boosted = safe.getTotalFeiBoostedForVault(strategy);
            uint256 feiAmount = UncompliantERC4626(address(strategy)).previewRedeem(strategy.balanceOf(address(safe)));

            if (boosted != 0 || feiAmount != 0) {
                totalFeiAmount += feiAmount;
                info[i] = StrategyInfo({strategy: strategy, boostedAmount: boosted, feiAmount: feiAmount});
            }
        }


        uint256 debtAmount = safe.feiTurboCToken().borrowBalanceCurrent(address(safe));
        uint256 feiPrice = oracle.getUnderlyingPrice(safe.feiTurboCToken());

        uint256 collateralAmount = safe.previewRedeem(safe.totalSupply());
        uint256 collateralPrice = oracle.getUnderlyingPrice(safe.assetTurboCToken());

        return SafeInfo({
            collateralAsset: safe.asset(), 
            collateralAmount: collateralAmount,
            collateralValue: collateralAmount * collateralPrice / 1e18,
            debtAmount: debtAmount,
            debtValue: debtAmount * feiPrice / 1e18,
            boostedAmount: safe.totalFeiBoosted(),
            feiAmount: totalFeiAmount,
            strategyInfo: info
        });
    }
}
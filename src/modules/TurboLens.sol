// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";

import {PriceFeed, Comptroller} from "../interfaces/Comptroller.sol";
import {TurboClerk} from "./TurboClerk.sol";
import {TurboBooster} from "./TurboBooster.sol";

import {TurboMaster, TurboSafe} from "../TurboMaster.sol";

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
        /// @notice the safe's address
        address safeAddress;

        /// @notice the safe collateral
        ERC20 collateralAsset;

        /// @notice the balance of collateral assets held by the safe
        uint256 collateralAmount;

        /// @notice collateral price in ETH
        uint256 collateralPrice;

        /// @notice collateral factor of the collateral asset scaled by 1e18
        uint256 collateralFactor;

        /// @notice fei price in ETH
        uint256 feiPrice;
        
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

        /// @notice fee split to TRIBE dao scaled by 1e18
        uint256 tribeDAOFee;

        StrategyInfo[] strategyInfo;
    }

    constructor (TurboMaster _master) {
        master = _master;
        pool = _master.pool();
    }

    function getAllUserSafes(address owner) external returns (SafeInfo[] memory) {
        TurboSafe[] memory safes = master.getAllSafes();
        uint256 userSafeCount;
        for (uint256 i = 1; i < safes.length; i++) {
            if (safes[i].owner() == owner) userSafeCount += 1;
        }
        
        TurboBooster booster = master.booster();
        TurboClerk clerk = master.clerk();

        ERC4626[] memory strategies = booster.getBoostableVaults();
        PriceFeed oracle = pool.oracle();
        
        SafeInfo[] memory userSafes = new SafeInfo[](userSafeCount);
        uint256 userSafesAdded;
        for (uint256 j = 1; j < safes.length; j++) {
            if (safes[j].owner() == owner) {
                userSafes[userSafesAdded] = _getSafeInfo(safes[j], strategies, oracle, clerk);
                userSafesAdded += 1; 
            }
        }

        return userSafes;
    }

    /// @dev this is non-view because some ERC-4626 vaults will be non-compliant and so the previewRedeem function is not static called.
    /// @dev likewise the compound borrowBalanceCurrent is non-view
    function getSafeInfo(TurboSafe safe) external returns(SafeInfo memory) {
        TurboBooster booster = master.booster();
        ERC4626[] memory strategies = booster.getBoostableVaults();
        return _getSafeInfo(safe, strategies, pool.oracle(), master.clerk());
    }

    function _getSafeInfo(TurboSafe safe, ERC4626[] memory strategies, PriceFeed oracle, TurboClerk clerk) internal returns (SafeInfo memory) {
        StrategyInfo[] memory info = new StrategyInfo[](strategies.length);

        uint256 totalFeiAmount;
        {
            for (uint256 i = 0; i < strategies.length; i++) {
                ERC4626 strategy = strategies[i];
                uint256 boosted = safe.getTotalFeiBoostedForVault(strategy);
                uint256 feiAmount = strategy.previewRedeem(strategy.balanceOf(address(safe)));

                if (boosted != 0 || feiAmount != 0) {
                    totalFeiAmount += feiAmount;
                    info[i] = StrategyInfo({strategy: strategy, boostedAmount: boosted, feiAmount: feiAmount});
                }
            }
        }

        ERC20 collateral = safe.asset();
        uint256 fee = clerk.getFeePercentageForSafe(safe, collateral);
        uint256 debtAmount = safe.feiTurboCToken().borrowBalanceCurrent(address(safe));
        uint256 feiPrice = oracle.getUnderlyingPrice(safe.feiTurboCToken());

        uint256 collateralAmount = safe.previewRedeem(safe.totalSupply());
        uint256 collateralPrice = oracle.getUnderlyingPrice(safe.assetTurboCToken());
        (, uint256 collateralFactor) = pool.markets(safe.assetTurboCToken());

        return SafeInfo({
            safeAddress: address(safe),
            collateralAsset: collateral, 
            collateralPrice: collateralPrice,
            collateralFactor: collateralFactor,
            feiPrice: feiPrice,
            collateralAmount: collateralAmount,
            collateralValue: collateralAmount * collateralPrice / 1e18,
            debtAmount: debtAmount,
            debtValue: debtAmount * feiPrice / 1e18,
            boostedAmount: safe.totalFeiBoosted(),
            feiAmount: totalFeiAmount,
            tribeDAOFee: fee,
            strategyInfo: info
        });
    }
}
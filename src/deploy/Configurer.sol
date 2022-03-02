// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {MultiRolesAuthority} from "solmate/auth/authorities/MultiRolesAuthority.sol";

import {Comptroller} from "../interfaces/Comptroller.sol";

import {TurboAdmin} from "../modules/TurboAdmin.sol";
import {TurboClerk} from "../modules/TurboClerk.sol";
import {TurboGibber} from "../modules/TurboGibber.sol";
import {TurboBooster} from "../modules/TurboBooster.sol";
import {TurboSavior} from "../modules/TurboSavior.sol";


import {TurboRouter, IWETH9} from "../TurboRouter.sol";
import {TurboMaster, TurboSafe, ERC4626} from "../TurboMaster.sol";

import {TimelockController} from "@openzeppelin/governance/TimelockController.sol";

/// @title Turbo Configurer
contract Configurer {
    address constant feiDAOTimelock = 0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c;
    address constant guardian = 0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c;

    ERC20 fei = ERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
    ERC20 tribe = ERC20(0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B);

    uint8 public constant GIBBER_ROLE = 1;
    uint8 public constant ROUTER_ROLE = 2;
    uint8 public constant SAVIOR_ROLE = 3;
    uint8 public constant TURBO_ADMIN_ROLE = 4;
    uint8 public constant GUARDIAN_ROLE = 5;
    uint8 public constant GOVERN_ROLE = 6;

    function configureAuthority(MultiRolesAuthority turboAuthority) public {
        // GIBBER_ROLE
        turboAuthority.setRoleCapability(GIBBER_ROLE, TurboSafe.gib.selector, true);
        
        // TURBO_ADMIN_ROLE
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboSafe.slurp.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboSafe.less.selector, true);
        
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.createSafe.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.setBooster.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.setClerk.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.setDefaultSafeAuthority.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboMaster.sweep.selector, true);
        
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboClerk.setDefaultFeePercentage.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboClerk.setCustomFeePercentageForCollateral.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboClerk.setCustomFeePercentageForSafe.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboBooster.setFreezeStatus.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboBooster.setBoostCapForVault.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboBooster.setBoostCapForCollateral.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboSavior.setMinDebtPercentageForSaving.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMarketSupplyCaps.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMarketSupplyCapsByUnderlying.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMarketBorrowCaps.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMarketBorrowCapsByUnderlying.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMintPausedByUnderlying.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setMintPaused.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setBorrowPausedByUnderlying.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setBorrowPaused.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin.oracleAdd.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._deployMarket.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._addRewardsDistributor.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setWhitelistStatuses.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setCloseFactor.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setCollateralFactor.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setLiquidationIncentive.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin.schedule.selector, true);

        // ROUTER_ROLE
        turboAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.boost.selector, true);
        turboAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.less.selector, true);
        turboAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.slurp.selector, true);
        turboAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.sweep.selector, true);
        turboAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.deposit.selector, true);
        turboAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.mint.selector, true);
        turboAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.withdraw.selector, true);
        turboAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.redeem.selector, true);


        // SAVIOR_ROLE
        turboAuthority.setRoleCapability(SAVIOR_ROLE, TurboSafe.less.selector, true);
        turboAuthority.setPublicCapability(TurboSavior.save.selector, true);
        
        // GUARDIAN_ROLE
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboSafe.less.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboBooster.setFreezeStatus.selector, true);
        
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMarketSupplyCaps.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMarketSupplyCapsByUnderlying.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMarketBorrowCaps.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMarketBorrowCapsByUnderlying.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMintPausedByUnderlying.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setMintPaused.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setBorrowPausedByUnderlying.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setBorrowPaused.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setTransferPaused.selector, true);
        turboAuthority.setRoleCapability(GUARDIAN_ROLE, TurboAdmin._setSeizePaused.selector, true);
        
        // GOVERN_ROLE
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._setBorrowCapGuardian.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._setPauseGuardian.selector, true);

        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin.oracleChangeAdmin.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._setWhitelistEnforcement.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._setPriceOracle.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._unsupportMarket.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin._toggleAutoImplementations.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin.scheduleSetPendingAdmin.selector, true);

        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin.schedule.selector, true);
        turboAuthority.setRoleCapability(GOVERN_ROLE, TurboAdmin.cancel.selector, true);


        turboAuthority.setPublicCapability(TurboAdmin.execute.selector, true);
    }

    function configurePool(TurboAdmin turboAdmin, TurboBooster booster) public {
        turboAdmin._deployMarket(
            address(fei), 
            0xC9dB5A1034BcBcca3f59dD61dbeE31b78CeFD126, // ZERO IRM
            "Turbo Fei", 
            "fFEI", 
            0x67Db14E73C2Dce786B5bbBfa4D010dEab4BBFCF9, 
            new bytes(0), 
            0, 
            0, 
            0
        );
        turboAdmin._deployMarket(
            address(tribe), 
            0xEDE47399e2aA8f076d40DC52896331CBa8bd40f7, 
            "Turbo Tribe", 
            "fTRIBE", 
            0x67Db14E73C2Dce786B5bbBfa4D010dEab4BBFCF9, 
            new bytes(0), 
            0, 
            0, 
            80e16
        );
        turboAdmin._setBorrowPausedByUnderlying(tribe, true);

        booster.setBoostCapForCollateral(tribe, 2_000_000e18); // 1M boost cap TRIBE

        address[] memory users = new address[](1);
        users[0] = feiDAOTimelock;

        bool[] memory enabled = new bool[](1);
        enabled[0] = true;

        turboAdmin._setWhitelistStatuses(users, enabled);

    }

    function configureClerk(TurboClerk clerk) public {
        clerk.setDefaultFeePercentage(90e16);
    }

    function configureSavior(TurboSavior savior) public {
        savior.setMinDebtPercentageForSaving(80e16); // 80%
    }

    function configureRoles(
        MultiRolesAuthority turboAuthority,
        TurboRouter router,
        TurboSavior savior,
        TurboGibber gibber
    ) public {
        turboAuthority.setUserRole(address(router), ROUTER_ROLE, true);
        turboAuthority.setUserRole(address(savior), SAVIOR_ROLE, true);
        turboAuthority.setUserRole(address(gibber), GIBBER_ROLE, true);
    }

    function configureMaster(
        TurboMaster master, 
        TurboClerk clerk, 
        TurboBooster booster,
        TurboAdmin admin
    ) public {
        MultiRolesAuthority turboAuthority = MultiRolesAuthority(address(master.authority()));

        turboAuthority.setUserRole(address(master), TURBO_ADMIN_ROLE, true);
        turboAuthority.setUserRole(address(admin), TURBO_ADMIN_ROLE, true);
        turboAuthority.setUserRole(address(feiDAOTimelock), TURBO_ADMIN_ROLE, true);
        
        turboAuthority.setUserRole(address(feiDAOTimelock), GOVERN_ROLE, true);

        turboAuthority.setUserRole(address(guardian), GUARDIAN_ROLE, true);

        master.setClerk(clerk);
        master.setBooster(booster);
        master.setDefaultSafeAuthority(turboAuthority);
    }
}
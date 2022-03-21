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

/**
 @title Turbo Configurer
 IS INTENDED FOR MAINNET DEPLOYMENT

 This contract is a helper utility to completely configure the turbo system, assuming the contracts are deployed.
 The deployment should follow the logic in Deployer.sol.

 Each function details its access control assumptions.
 */ 
contract Configurer {

    /// @notice Fei DAO Timelock, to be granted TURBO_ADMIN_ROLE and GOVERN_ROLE
    address constant feiDAOTimelock = 0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c;
    
    /// @notice Tribe Guardian, to be granted GUARDIAN_ROLE
    address constant guardian = 0xB8f482539F2d3Ae2C9ea6076894df36D1f632775;

    ERC20 fei = ERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
    ERC20 tribe = ERC20(0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B);

    /******************** ROLES ********************/

    /// @notice HIGH CLEARANCE. capable of calling `gib` to impound collateral. 
    uint8 public constant GIBBER_ROLE = 1;
    
    /// @notice HIGH CLEARANCE. Optional module which can interact with any user's vault by default.
    uint8 public constant ROUTER_ROLE = 2;

    /// @notice Capable of lessing any vault. Exposed on optional TurboSavior module.
    uint8 public constant SAVIOR_ROLE = 3;

    /// @notice Operational admin of Turbo, can whitelist collaterals, strategies, and configure most parameters.
    uint8 public constant TURBO_ADMIN_ROLE = 4;
    
    /// @notice Pause and security Guardian role
    uint8 public constant GUARDIAN_ROLE = 5;
    
    /// @notice HIGH CLEARANCE. Capable of critical governance functionality on TurboAdmin such as oracle upgrades. 
    uint8 public constant GOVERN_ROLE = 6;

    /// @notice limited version of TURBO_ADMIN_ROLE which can manage collateral and vault parameters.
    uint8 public constant TURBO_STRATEGIST_ROLE = 7;

    /******************** CONFIGURATION ********************/

    /// @notice configure the turbo timelock. Requires TIMELOCK_ADMIN_ROLE over timelock.
    function configureTimelock(TimelockController turboTimelock, TurboAdmin admin) public {
        turboTimelock.grantRole(turboTimelock.TIMELOCK_ADMIN_ROLE(), address(admin));
        turboTimelock.grantRole(turboTimelock.EXECUTOR_ROLE(), address(admin));
        turboTimelock.grantRole(turboTimelock.PROPOSER_ROLE(), address(admin));
        turboTimelock.revokeRole(turboTimelock.TIMELOCK_ADMIN_ROLE(), address(this));
    }

    /// @notice configure the turbo authority. Requires ownership over turbo authority.
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
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin.addCollateral.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._deployMarket.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._addRewardsDistributor.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setWhitelistStatuses.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setCloseFactor.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setCollateralFactor.selector, true);
        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin._setLiquidationIncentive.selector, true);

        turboAuthority.setRoleCapability(TURBO_ADMIN_ROLE, TurboAdmin.schedule.selector, true);
        
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
    
        // TURBO_STRATEGIST_ROLE
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboAdmin.addCollateral.selector, true);
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboAdmin._setMarketSupplyCaps.selector, true);
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboAdmin._setMarketSupplyCapsByUnderlying.selector, true);
        
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboBooster.setBoostCapForVault.selector, true);
        turboAuthority.setRoleCapability(TURBO_STRATEGIST_ROLE, TurboBooster.setBoostCapForCollateral.selector, true);
    
        turboAuthority.setPublicCapability(TurboSavior.save.selector, true);
    }

        /// @notice configure the default authority. Requires ownership over default authority.
    function configureDefaultAuthority(MultiRolesAuthority defaultAuthority) public {
        // ROUTER_ROLE
        defaultAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.boost.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.less.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.slurp.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, TurboSafe.sweep.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.deposit.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.mint.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.withdraw.selector, true);
        defaultAuthority.setRoleCapability(ROUTER_ROLE, ERC4626.redeem.selector, true);


        // SAVIOR_ROLE
        defaultAuthority.setRoleCapability(SAVIOR_ROLE, TurboSafe.less.selector, true);
    }

    /// @notice configure the turbo pool through turboAdmin. TurboAdmin requires pool ownership, and Configurer requires TURBO_ADMIN_ROLE.
    function configurePool(TurboAdmin turboAdmin, TurboBooster booster) public {
        turboAdmin._deployMarket(
            address(fei), 
            turboAdmin.ZERO_IRM(),
            "Turbo Fei", 
            "fFEI", 
            turboAdmin.CTOKEN_IMPL(), 
            new bytes(0), 
            0, 
            0, 
            0
        );
        turboAdmin.addCollateral(
            address(tribe), 
            "Turbo Tribe", 
            "fTRIBE",
            60e16,
            50_000_000e18
        );
        booster.setBoostCapForCollateral(tribe, 2_000_000e18); // 1M boost cap TRIBE

        address[] memory users = new address[](1);
        users[0] = feiDAOTimelock;

        bool[] memory enabled = new bool[](1);
        enabled[0] = true;

        turboAdmin._setWhitelistStatuses(users, enabled);
    }

    /// @notice requires TURBO_ADMIN_ROLE.
    function configureClerk(TurboClerk clerk) public {
        clerk.setDefaultFeePercentage(75e16); // 75% default revenue split
    }

    /// @notice requires TURBO_ADMIN_ROLE.
    function configureSavior(TurboSavior savior) public {
        savior.setMinDebtPercentageForSaving(80e16); // 80%
    }

    /// @notice requires ownership of Turbo Authority and default authority.
    function configureRoles(
        MultiRolesAuthority turboAuthority,
        MultiRolesAuthority defaultAuthority,
        TurboRouter router,
        TurboSavior savior,
        TurboGibber gibber
    ) public {
        defaultAuthority.setUserRole(address(router), ROUTER_ROLE, true);
        defaultAuthority.setUserRole(address(savior), SAVIOR_ROLE, true);
        turboAuthority.setUserRole(address(gibber), GIBBER_ROLE, true);
    }

    /// @notice requires TURBO_ADMIN_ROLE and ownership over Turbo Authority.
    function configureMaster(
        TurboMaster master, 
        TurboClerk clerk, 
        TurboBooster booster,
        TurboAdmin admin,
        MultiRolesAuthority defaultAuthority
    ) public {
        MultiRolesAuthority turboAuthority = MultiRolesAuthority(address(master.authority()));

        turboAuthority.setUserRole(address(master), TURBO_ADMIN_ROLE, true);
        turboAuthority.setUserRole(address(admin), TURBO_ADMIN_ROLE, true);
        turboAuthority.setUserRole(address(feiDAOTimelock), TURBO_ADMIN_ROLE, true);
        
        turboAuthority.setUserRole(address(feiDAOTimelock), GOVERN_ROLE, true);

        turboAuthority.setUserRole(address(guardian), GUARDIAN_ROLE, true);

        master.setClerk(clerk);
        master.setBooster(booster);
        master.setDefaultSafeAuthority(defaultAuthority);
    }

    function configureAdmin(MultiRolesAuthority turboAuthority, Comptroller pool, TurboAdmin admin) public {
        // temporarily assume ownership of pool (required by deployer)
        pool._acceptAdmin();
        
        // Temporarily grant the deployer the turbo admin role for setup
        turboAuthority.setUserRole(address(this), TURBO_ADMIN_ROLE, true);
        pool._setPendingAdmin(address(admin));
        admin._acceptAdmin();
    }
    
    function resetOwnership(
        MultiRolesAuthority defaultAuthority,
        MultiRolesAuthority turboAuthority,
        TimelockController turboTimelock,
        address admin
    ) public {
        if (admin != address(0)) {
            turboAuthority.setUserRole(admin, TURBO_ADMIN_ROLE, true);
        }
        turboAuthority.setUserRole(address(this), TURBO_ADMIN_ROLE, false);
        turboAuthority.setOwner(address(turboTimelock));
        defaultAuthority.setOwner(address(turboTimelock));
    }
}
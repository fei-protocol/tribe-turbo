// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./Configurer.sol";
import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";
import {TurboLens} from "../modules/TurboLens.sol";

interface PoolDeployer {
    function deployPool(string memory name, address implementation, bool enforceWhitelist, uint256 closeFactor, uint256 liquidationIncentive, address priceOracle) external returns (uint256, Comptroller);
}

/**
 @title Turbo Deployer
 NOT INTENDED FOR MAINNET DEPLOYMENT

 This contract would far exceed the bytecode limit. 

 The "Deployer" is a thin extension layer on the Configurer in terms of logic, but it holds all the actual deployment code.

 The actual deployment will just use the Configurer, assume the deployer steps are manually taken in order per the deploy function
 */
contract Deployer is Configurer {
    
    /// @notice the comptroller of the turbo fuse pool
    Comptroller pool;
    
    IWETH9 weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    PoolDeployer poolDeployer = PoolDeployer(0x835482FE0532f169024d5E9410199369aAD5C77E);
    
    /// @notice the master oracle used for the turbo fuse pool
    address masterOracle = 0x1887118E49e0F4A78Bd71B792a49dE03504A764D;
   
    /// @notice the comptroller implementation for the turbo fuse pool
    /// TODO change impl to b Protocol impl also edit TurboAdmin
    address poolImpl = 0xE16DB319d9dA7Ce40b666DD2E365a4b8B3C18217;

    /// @notice the turbo timelock controller delay
    uint256 public timelockDelay = 15 days;

    // Turbo contracts
    TurboMaster public master;
    TurboGibber public gibber;
    TurboSavior public savior;
    TurboRouter public router;

    TurboLens public lens;

    MockERC4626 public strategy;

    constructor() {
        deploy();
    }

    function deploy() public {
        // First deploy a new Fuse pool
        (,pool) = poolDeployer.deployPool(
            "Tribe Turbo Pool", // name 
            poolImpl, // comptroller impl address
            true, // set whitelist enforcement true
            50e16, // 50% Close Factor
            108e16, // 8% Liquidation Incentive (not sure why it needs to be 108 but it does)
            masterOracle // master oracle for pool
        );

        // temporarily assume ownership of pool (required by deployer)
        pool._acceptAdmin();

        // Deploy a timelock and authority to use throughout system 
        TimelockController turboTimelock = new TimelockController(timelockDelay, new address[](0), new address[](0));
        MultiRolesAuthority turboAuthority = new MultiRolesAuthority(address(this), Authority(address(0)));
        
        // Temporarily grant the deployer the turbo admin role for setup
        turboAuthority.setUserRole(address(this), TURBO_ADMIN_ROLE, true);

        // Deploy the Turbo Admin and assume pool ownership
        TurboAdmin admin = new TurboAdmin(pool, turboTimelock, turboAuthority);
        pool._setPendingAdmin(address(admin));
        admin._acceptAdmin();

        // Create ACL roles and configure timelock
        configureTimelock(turboTimelock, admin);
        configureAuthority(turboAuthority);

        // Deploy master, clerk, booster and configure
        master = new TurboMaster(
            pool,
            fei,
            address(turboTimelock),
            turboAuthority
        );

        TurboClerk clerk = new TurboClerk(address(turboTimelock), turboAuthority);
        TurboBooster booster = new TurboBooster(address(turboTimelock), turboAuthority);
        configureMaster(master, clerk, booster, admin);
        
        lens = new TurboLens(master);

        // Configure the base turbo pool with FEI and initial collaterals
        configurePool(admin, booster);

        gibber = new TurboGibber(master, address(turboTimelock), Authority(address(0))); // gibber only operates behind timelock, no authority
        savior = new TurboSavior(master, address(turboTimelock), turboAuthority);
        router = new TurboRouter(master, "", weth); // TODO add ENS everywhere

        // configure remaining ACL roles and params
        configureRoles(turboAuthority, router, savior, gibber);
        configureClerk(clerk);
        configureSavior(savior);

        // TODO migrate mock to an actual strategy
        strategy = new MockERC4626(fei, "xFEI", "xFEI");
        booster.setBoostCapForVault(strategy, 2_000_000e18); // 1M boost cap for vault

        // reset admin access on deployer
        turboAuthority.setUserRole(address(this), TURBO_ADMIN_ROLE, false);
        turboAuthority.setOwner(address(turboTimelock));
    }
}
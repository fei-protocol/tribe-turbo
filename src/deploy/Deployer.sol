// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "./Configurer.sol";

interface PoolDeployer {
    function deployPool(string memory name, address implementation, bool enforceWhitelist, uint256 closeFactor, uint256 liquidationIncentive, address priceOracle) external returns (uint256, Comptroller);
}

/// @title Turbo Deployer
contract Deployer is Configurer {
    Comptroller pool; // = Comptroller(0xc62ceB397a65edD6A68715b2d3922dEE0D63F45c);
    IWETH9 weth = IWETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    PoolDeployer poolDeployer = PoolDeployer(0x835482FE0532f169024d5E9410199369aAD5C77E);
    address masterOracle = 0x1887118E49e0F4A78Bd71B792a49dE03504A764D;
   
    // TODO change impl to b Protocol impl also edit TurboAdmin
    address poolImpl = 0xE16DB319d9dA7Ce40b666DD2E365a4b8B3C18217;

    uint256 public timelockDelay = 15 days;

    TurboMaster public master;
    TurboGibber public gibber;
    TurboSavior public savior;
    TurboRouter public router;

    constructor() {
        deploy();
    }

    function deploy() public {
        (,pool) = poolDeployer.deployPool("Tribe Turbo Pool", poolImpl, true, 50e16, 108e16, masterOracle);
        pool._acceptAdmin();

        TimelockController turboTimelock = new TimelockController(timelockDelay, new address[](0), new address[](0));
        MultiRolesAuthority turboAuthority = new MultiRolesAuthority(address(this), Authority(address(0)));
        turboAuthority.setUserRole(address(this), TURBO_ADMIN_ROLE, true);

        TurboAdmin admin = new TurboAdmin(pool, turboTimelock, turboAuthority);
        pool._setPendingAdmin(address(admin));
        admin._acceptAdmin();

        configureAuthority(turboAuthority);

        master = new TurboMaster(
            pool,
            fei,
            address(turboTimelock),
            turboAuthority
        );

        TurboClerk clerk = new TurboClerk(address(turboTimelock), turboAuthority);
        TurboBooster booster = new TurboBooster(address(turboTimelock), turboAuthority);
        configureMaster(master, clerk, booster, admin);
        configurePool(admin, booster);

        gibber = new TurboGibber(master, address(turboTimelock), Authority(address(0))); // gibber only operates behind timelock
        savior = new TurboSavior(master, address(turboTimelock), turboAuthority);
        router = new TurboRouter(master, "", weth);

        configureRoles(turboAuthority, router, savior, gibber);
        configureClerk(clerk);
        configureSavior(savior);

        turboAuthority.setUserRole(address(this), TURBO_ADMIN_ROLE, false);
    }
}
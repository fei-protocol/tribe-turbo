// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import "../deploy/Deployer.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";

import {CERC20} from "../interfaces/CERC20.sol";

interface ICore {
    function grantRole(bytes32 role, address to) external;

    function allocateTribe(address to, uint amount) external;
}

contract Integration is DSTestPlus {
    TurboMaster master;
    TurboGibber gibber;
    TurboSavior savior;
    TurboBooster booster;
    MultiRolesAuthority authority;
    Comptroller comptroller;
    TurboAdmin fuseAdmin;

    MockERC4626 strategy;

    ERC20 tribe = ERC20(0xc7283b66Eb1EB5FB86327f08e1B5816b0720212B);
    MockERC20 fei = MockERC20(0x956F47F50A910163D8BF957Cf5846D573E7f87CA);
    CERC20 fFEI;

    address constant feiDAOTimelock = 0xd51dbA7a94e1adEa403553A8235C302cEbF41a3c;
    ICore constant core = ICore(0x8d5ED43dCa8C2F7dFB20CF7b53CC7E593635d7b9);

    function setUp() public {
        Deployer deployer = new Deployer();

        master = deployer.master();
        gibber = deployer.gibber();
        savior = deployer.savior();

        booster = master.booster();
        authority = MultiRolesAuthority(address(master.authority()));

        comptroller = master.pool();
        fuseAdmin = TurboAdmin(address(comptroller.admin()));
    
        strategy = new MockERC4626(fei, "xFEI", "xFEI");

        configurePool();
    }

    function configurePool() public {
        hevm.startPrank(feiDAOTimelock);
        fFEI = comptroller.cTokensByUnderlying(fei);
        
        fei.mint(feiDAOTimelock, 10_000_000e18);
        fei.approve(address(fFEI), 10_000_000e18);
        
        require(fFEI.mint(10_000_000e18) == 0, "mint fails");

        booster.setBoostCapForVault(strategy, 2_000_000e18); // 1M boost cap for vault

        core.allocateTribe(address(this), 10_000_000e18);
        hevm.stopPrank();
    }

    function testFailCreationWithoutApproval() public {
        master.createSafe(tribe);
    }

    function testIntegraion() public {
        hevm.prank(authority.owner());
        authority.setPublicCapability(TurboMaster.createSafe.selector, true);

        (TurboSafe safe,) = master.createSafe(tribe);
        
        tribe.approve(address(safe), 2_000_000e18);
        safe.deposit(2_000_000e18, address(this));

        assertEq(safe.balanceOf(address(this)), 2_000_000e18);

        safe.boost(strategy, 100_000e18);

        assertEq(strategy.balanceOf(address(safe)), 100_000e18);

        hevm.prank(feiDAOTimelock);
        fei.mint(address(strategy), 10_000e18);

        require(fei.balanceOf(address(master)) == 0, "no fei");
        safe.slurp(strategy);
        require(fei.balanceOf(address(master)) == 9000e18, "master slurps");

        safe.less(strategy, 101_000e18);

        require(strategy.balanceOf(address(safe)) == 0, "Safe empty");

        safe.redeem(2_000_000e18, address(this), address(this));

        assertEq(safe.balanceOf(address(safe)), 0);
    }

    function testSavior() public {
        hevm.prank(authority.owner());
        authority.setPublicCapability(TurboMaster.createSafe.selector, true);

        (TurboSafe safe,) = master.createSafe(tribe);
        
        tribe.approve(address(safe), 2_000_000e18);
        safe.deposit(2_000_000e18, address(this));

        assertEq(safe.balanceOf(address(this)), 2_000_000e18);

        safe.boost(strategy, 1_100_000e18);
        require(strategy.balanceOf(address(safe)) == 1_100_000e18);

        savior.save(safe, strategy, 1_000_000e18);

        require(strategy.balanceOf(address(safe)) == 100_000e18);
    }
}
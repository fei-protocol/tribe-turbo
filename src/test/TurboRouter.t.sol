// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Authority} from "solmate/auth/Auth.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MockAuthority} from "solmate/test/utils/mocks/MockAuthority.sol";
import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {MockCToken} from "./mocks/MockCToken.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {MockFuseAdmin} from "./mocks/MockFuseAdmin.sol";
import {MockComptroller} from "./mocks/MockComptroller.sol";

import {TurboClerk} from "../modules/TurboClerk.sol";
import {TurboBooster} from "../modules/TurboBooster.sol";

import {TurboSafe} from "../TurboSafe.sol";
import {TurboMaster} from "../TurboMaster.sol";
import {TurboRouter, IWETH9} from "../TurboRouter.sol";

contract TurboRouterTest is DSTestPlus {
    using FixedPointMathLib for uint256;

    TurboMaster master;

    TurboClerk clerk;

    TurboBooster booster;

    MockFuseAdmin fuseAdmin;

    MockComptroller comptroller;

    MockERC20 fei;

    MockERC20 asset;

    MockCToken assetCToken;

    MockCToken feiCToken;

    MockERC4626 vault;

    TurboRouter router;

    function setUp() public {
        fei = new MockERC20("Fei USD", "FEI", 18);

        asset = new MockERC20("Mock Token", "MOCK", 18);

        fuseAdmin = new MockFuseAdmin();

        booster = new TurboBooster(address(this), Authority(address(0)));

        clerk = new TurboClerk(address(this), Authority(address(0)));

        comptroller = new MockComptroller(address(fuseAdmin), new MockPriceFeed());

        master = new TurboMaster(comptroller, fei, address(this), new MockAuthority(true));

        assetCToken = new MockCToken(asset);

        comptroller.mapUnderlyingToCToken(asset, assetCToken);

        feiCToken = new MockCToken(fei);

        comptroller.mapUnderlyingToCToken(fei, feiCToken);

        vault = new MockERC4626(fei, "Mock Fei Vault", "mvFEI");

        master.setBooster(booster);

        master.setClerk(clerk);

        booster.setBoostCapForVault(vault, 1e18);
        booster.setBoostCapForCollateral(asset, 1e18);

        router = new TurboRouter(master, "", IWETH9(address(0))); // empty reverse ens and WETH
    }

    function testSafeCreation() public {
        TurboSafe safe = router.createSafe(asset);
        require(safe.owner() == address(this));
    }

    function testSafeCreationAndDeposit() public {
        asset.mint(address(this), 1e18);

        asset.approve(address(router), 1e18);
        router.pullToken(asset, 1e18, address(router));

        TurboSafe safe = router.createSafeAndDeposit(asset, address(this), 1e18, 0);
        require(safe.owner() == address(this));
        require(safe.totalSupply() == 1e18);
        require(safe.balanceOf(address(this)) == 1e18);
    }

    function testSafeCreationAndDepositAndBoost() public {
        asset.mint(address(this), 1e18);

        asset.approve(address(router), 1e18);
        router.pullToken(asset, 1e18, address(router));

        fei.mint(address(feiCToken), 1e18);

        TurboSafe safe = router.createSafeAndDepositAndBoost(asset, address(this), 1e18, 0, vault, 1e18);

        require(safe.owner() == address(this));
        require(safe.totalSupply() == 1e18);
        require(safe.balanceOf(address(this)) == 1e18);
        require(safe.totalFeiBoosted() == 1e18);
        require(safe.getTotalFeiBoostedForVault(vault) == 1e18);
        require(vault.balanceOf(address(safe)) == 1e18);
    }

    function testFailAuthenticationFromNonUser() public {
        asset.mint(address(this), 1e18);

        asset.approve(address(router), 1e18);
        router.pullToken(asset, 1e18, address(router));

        TurboSafe safe = router.createSafeAndDeposit(asset, address(this), 1e18, 0);
        router.boost(safe, vault, 1e18);
    }

    function testRouter() public {
        asset.mint(address(this), 1e18);

        asset.approve(address(router), 1e18);
        router.pullToken(asset, 1e18, address(router));

        TurboSafe safe = router.createSafeAndDeposit(asset, address(this), 1e18, 0);

        safe.setAuthority(new MockAuthority(true));

        fei.mint(address(feiCToken), 1e18);

        router.boost(safe, vault, 1e18);

        require(safe.totalFeiBoosted() == 1e18);
        require(safe.getTotalFeiBoostedForVault(vault) == 1e18);
        require(vault.balanceOf(address(safe)) == 1e18);

        fei.mint(address(vault), 0.1e18);

        router.slurp(safe, vault);
        require(safe.totalFeiBoosted() == 1.1e18);
        require(safe.getTotalFeiBoostedForVault(vault) == 1.1e18);
        require(vault.balanceOf(address(safe)) == 1e18);

        // less
        router.less(safe, vault, 1.1e18);
        require(safe.totalFeiBoosted() == 0);
        require(safe.getTotalFeiBoostedForVault(vault) == 0);
        require(vault.balanceOf(address(safe)) == 0);
        require(fei.balanceOf(address(safe)) == 0.1e18); 

        // sweep
        router.sweep(safe, address(this), fei, 0.1e18);
        require(fei.balanceOf(address(safe)) == 0); 
        require(fei.balanceOf(address(this)) == 0.1e18); 
    }
}
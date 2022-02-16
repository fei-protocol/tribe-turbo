// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Authority} from "solmate/auth/Auth.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {DSTestPlus} from "solmate/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MockERC4626} from "solmate/test/utils/mocks/MockERC4626.sol";
import {MockAuthority} from "solmate/test/utils/mocks/MockAuthority.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {MockCToken} from "./mocks/MockCToken.sol";
import {MockPriceFeed} from "./mocks/MockPriceFeed.sol";
import {MockFuseAdmin} from "./mocks/MockFuseAdmin.sol";
import {MockComptroller} from "./mocks/MockComptroller.sol";

import {TurboClerk} from "../modules/TurboClerk.sol";
import {TurboSavior} from "../modules/TurboSavior.sol";
import {TurboBooster} from "../modules/TurboBooster.sol";

import {TurboSafe} from "../TurboSafe.sol";
import {TurboMaster} from "../TurboMaster.sol";

contract TurboSaviorTest is DSTestPlus {
    using FixedPointMathLib for uint256;

    TurboMaster master;

    MockPriceFeed oracle;

    TurboBooster booster;

    TurboSavior savior;

    MockFuseAdmin fuseAdmin;

    MockComptroller comptroller;

    MockERC20 fei;

    MockERC20 asset;

    MockCToken assetCToken;

    MockCToken feiCToken;

    MockERC4626 vault;

    TurboSafe safe;

    function setUp() public {
        fei = new MockERC20("Fei USD", "FEI", 18);

        asset = new MockERC20("Mock Token", "MOCK", 18);

        fuseAdmin = new MockFuseAdmin();

        booster = new TurboBooster(address(this), Authority(address(0)));

        oracle = new MockPriceFeed();

        comptroller = new MockComptroller(address(fuseAdmin), oracle);

        master = new TurboMaster(comptroller, fei, address(this), new MockAuthority(true));

        assetCToken = new MockCToken(asset);

        comptroller.mapUnderlyingToCToken(asset, assetCToken);

        feiCToken = new MockCToken(fei);

        comptroller.mapUnderlyingToCToken(fei, feiCToken);

        vault = new MockERC4626(fei, "Mock Fei Vault", "mvFEI");

        master.setBooster(booster);

        (safe, ) = master.createSafe(asset);

        asset.mint(address(this), type(uint256).max);
        asset.approve(address(safe), type(uint256).max);

        savior = new TurboSavior(master, address(this), Authority(address(0)));
    }

    /*///////////////////////////////////////////////////////////////
                              SAVE TESTS
    //////////////////////////////////////////////////////////////*/

    function testImpound(
        uint128 depositAmount,
        uint128 borrowAmount,
        uint128 feiPrice,
        uint128 assetPrice,
        uint128 assetCollateralFactor,
        uint128 minDebtPercentage,
        uint128 feiAmount,
        address to
    ) public {
        // if (depositAmount == 0) depositAmount = 1;
        // if (borrowAmount == 0) borrowAmount = 1;
        // if (feiPrice == 0) feiPrice = 1;
        // if (assetPrice == 0) assetPrice = 1;
        // if (feiAmount == 0) feiAmount = 1;
        // assetCollateralFactor = uint128(bound(assetCollateralFactor, 1, 1e18));
        // minDebtPercentage = uint128(bound(assetCollateralFactor, 1, 1e18));
        // safe.deposit(depositAmount, to);
        // fei.mint(address(feiCToken), borrowAmount);
        // booster.setBoostCapForVault(vault, borrowAmount);
        // booster.setBoostCapForCollateral(asset, borrowAmount);
        // safe.boost(vault, borrowAmount);
        // oracle.setUnderlyingPrice(feiCToken, feiPrice);
        // oracle.setUnderlyingPrice(feiCToken, assetPrice);
        // savior.save(safe, vault, feiAmount);
    }
}

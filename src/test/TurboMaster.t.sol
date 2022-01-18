// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Authority} from "solmate-next/auth/Auth.sol";
import {DSTestPlus} from "solmate-next/test/utils/DSTestPlus.sol";
import {MockERC20} from "solmate-next/test/utils/mocks/MockERC20.sol";

import {MockCToken} from "./mocks/MockCToken.sol";
import {MockComptroller} from "./mocks/MockComptroller.sol";

import {TurboClerk} from "../modules/TurboClerk.sol";
import {TurboBooster} from "../modules/TurboBooster.sol";
import {TurboGibber} from "../modules/TurboGibber.sol";

import {TurboSafe} from "../TurboSafe.sol";
import {TurboMaster} from "../TurboMaster.sol";

contract TurboMasterTest is DSTestPlus {
    TurboMaster master;

    MockComptroller comptroller;

    MockERC20 fei;

    MockERC20 underlying;

    MockCToken mockCToken;

    function setUp() public {
        fei = new MockERC20("Fei USD", "FEI", 18);

        underlying = new MockERC20("Mock Token", "MOCK", 18);

        comptroller = new MockComptroller();

        master = new TurboMaster(comptroller, fei, address(this), Authority(address(0)));
    }

    /*///////////////////////////////////////////////////////////////
                     MODULE CONFIGURATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetBooster(TurboBooster booster) public {
        master.setBooster(booster);

        assertEq(address(master.booster()), address(booster));
    }

    function testSetClerk(TurboClerk clerk) public {
        master.setClerk(clerk);

        assertEq(address(master.clerk()), address(clerk));
    }

    function testSetGibber(TurboGibber gibber) public {
        master.setGibber(gibber);

        assertEq(address(master.gibber()), address(gibber));
    }

    /*///////////////////////////////////////////////////////////////
                 DEFAULT AUTHORITY CONFIGURATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testSetDefaultSafeAuthority(Authority authority) public {
        master.setDefaultSafeAuthority(authority);

        assertEq(address(master.defaultSafeAuthority()), address(authority));
    }

    function testCreateSafeWithCustomDefaultSafeAuthority(Authority defaultSafeAuthority) public {
        master.setDefaultSafeAuthority(defaultSafeAuthority);

        comptroller.mapUnderlyingToCToken(underlying, new MockCToken(underlying));

        (TurboSafe safe, ) = master.createSafe(underlying);

        assertEq(address(safe.authority()), address(defaultSafeAuthority));
    }
}

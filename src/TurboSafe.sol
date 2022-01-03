// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {CERC20} from "./external/CERC20.sol";
import {Comptroller} from "./external/Comptroller.sol";

import {TurboMaster} from "./TurboMaster.sol";

contract TurboSafe is Auth, ERC20 {
    using SafeTransferLib for ERC20;

    //////////////////////////////

    ERC20 immutable fei;

    ERC20 immutable underlying;

    Comptroller immutable boostPool;

    CERC20 immutable feiCToken;

    CERC20 immutable underlyingCToken;

    //////////////////////////////

    uint256 public totalLent;

    uint256 public totalFeiDebt;

    //////////////////////////////

    function totalHoldings() external view returns (uint256) {
        return underlying.balanceOf(address(this)) + totalFeiDebt;
    }

    constructor(address _owner, ERC20 _underlying)
        Auth(_owner, Authority(address(0)))
        ERC20(
            string(abi.encodePacked(_underlying.name(), " Turbo Safe")),
            string(abi.encodePacked("ts", _underlying.symbol())),
            _underlying.decimals()
        )
    {
        underlying = _underlying;

        boostPool = TurboMaster(msg.sender).boostPool();

        underlyingCToken = boostPool.cTokensByUnderlying(underlying);
    }

    function deposit(uint256 underlyingAmount) public requiresAuth returns (uint256 sharesMinted) {
        _mint(msg.sender, sharesMinted = underlyingAmount);

        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        underlying.approve(address(underlyingCToken), underlyingAmount);

        require(underlyingCToken.mint(underlyingAmount) == 0, "MINT_FAILED");
    }

    function withdraw(uint256 underlyingAmount) public requiresAuth returns (uint256 sharesBurnt) {
        _burn(msg.sender, sharesBurnt = underlyingAmount);

        require(underlyingCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");

        underlying.safeTransfer(msg.sender, underlyingAmount);
    }

    function boost(CERC20 cToken, uint256 feiAmount) public requiresAuth {
        // TODO: call out to some auth module and check if cToken is cool

        require(cToken.underlying() == fei, "NOT_FEI");

        require(feiCToken.borrow(feiAmount) == 0, "BORROW_FAILED");

        fei.safeApprove(address(cToken), feiAmount);

        require(cToken.mint(feiAmount) == 0, "MINT_FAILED");
    }

    function less(CERC20 cToken, uint256 feiAmount) public requiresAuth {
        require(cToken.redeemUnderlying(feiAmount) == 0, "REDEEM_FAILED");

        require(feiCToken.repayBorrow(feiAmount) == 0, "REPAY_FAILED");

        // TODO: payback interest
    }

    function gib(CERC20 cToken, uint256 feiAmount) public requiresAuth {
        // TODO: force liquidate
    }
}

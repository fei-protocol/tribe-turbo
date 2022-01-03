// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {CERC20} from "./external/CERC20.sol";
import {Comptroller} from "./external/Comptroller.sol";

import {TurboMaster} from "./TurboMaster.sol";

contract TurboSafe is Auth, ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                          TURBO MASTER STORAGE
    //////////////////////////////////////////////////////////////*/

    TurboMaster public immutable master;

    /*///////////////////////////////////////////////////////////////
                             VAULT STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalHoldings;

    uint256 public immutable baseUnit;

    mapping(CERC20 => uint256) getTotalFeiDeposited;

    /*///////////////////////////////////////////////////////////////
                             TOKEN STORAGE
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable fei;

    ERC20 public immutable underlying;

    /*///////////////////////////////////////////////////////////////
                             FUSE STORAGE
    //////////////////////////////////////////////////////////////*/

    Comptroller public immutable pool;

    CERC20 public immutable feiCToken;

    CERC20 public immutable underlyingCToken;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, ERC20 _underlying)
        Auth(_owner, Authority(address(0)))
        ERC20(
            string(abi.encodePacked(_underlying.name(), " Turbo Safe")),
            string(abi.encodePacked("ts", _underlying.symbol())),
            _underlying.decimals()
        )
    {
        master = TurboMaster(msg.sender);
        baseUnit = 10**decimals;

        fei = master.fei();
        underlying = _underlying;

        pool = master.pool();
        feiCToken = pool.cTokensByUnderlying(underlying);
        underlyingCToken = pool.cTokensByUnderlying(underlying);

        // the provided underlying is not supported by the boost pool
        if (address(underlyingCToken) == address(0)) revert("UNSUPPORTED_UNDERLYING");
    }

    /*///////////////////////////////////////////////////////////////
                             VAULT LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(address to, uint256 underlyingAmount) external requiresAuth returns (uint256 shares) {
        _mint(to, shares = underlyingAmount.fdiv(exchangeRate(), baseUnit));

        totalHoldings += underlyingAmount;

        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        underlying.approve(address(underlyingCToken), underlyingAmount);

        require(underlyingCToken.mint(underlyingAmount) == 0, "MINT_FAILED");
    }

    function withdraw(address to, uint256 underlyingAmount) external requiresAuth returns (uint256 shares) {
        _burn(msg.sender, shares = underlyingAmount.fdiv(exchangeRate(), baseUnit));

        totalHoldings -= underlyingAmount;

        require(underlyingCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");

        underlying.safeTransfer(to, underlyingAmount);
    }

    function redeem(address to, uint256 shareAmount) external requiresAuth returns (uint256 underlyingAmount) {
        _burn(msg.sender, shareAmount);

        totalHoldings -= underlyingAmount = shareAmount.fmul(exchangeRate(), baseUnit);

        underlying.safeTransfer(to, underlyingAmount);
    }

    function exchangeRate() public view returns (uint256) {
        uint256 shareSupply = totalSupply;

        if (shareSupply == 0) return baseUnit;

        return totalHoldings.fdiv(shareSupply, baseUnit);
    }

    /*///////////////////////////////////////////////////////////////
                             BOOST LOGIC
    //////////////////////////////////////////////////////////////*/

    function boost(CERC20 cToken, uint256 feiAmount) external requiresAuth {
        require(master.custodian().isAuthorizedToBoost(this, cToken, feiAmount), "CUSTODIAN_REJECTED");

        getTotalFeiDeposited[cToken] += feiAmount;

        require(cToken.underlying() == fei, "NOT_FEI");

        require(feiCToken.borrow(feiAmount) == 0, "BORROW_FAILED");

        fei.safeApprove(address(cToken), feiAmount);

        require(cToken.mint(feiAmount) == 0, "MINT_FAILED");
    }

    function less(CERC20 cToken, uint256 feiAmount) external requiresAuth {
        slurp(cToken); // aaa im sluuuurping

        getTotalFeiDeposited[cToken] -= feiAmount;

        require(cToken.redeemUnderlying(feiAmount) == 0, "REDEEM_FAILED");

        fei.safeApprove(address(cToken), feiAmount);

        uint256 feiDebt = feiCToken.borrowBalanceCurrent(address(this));

        if (feiAmount > feiDebt) feiAmount = feiDebt; // someone repaid on our behalf

        require(feiCToken.repayBorrow(feiAmount) == 0, "REPAY_FAILED");
    }

    function slurp(CERC20 cToken) public {
        uint256 feesEarned = cToken.balanceOfUnderlying(address(this)) - getTotalFeiDeposited[cToken];

        require(cToken.redeemUnderlying(feesEarned) == 0, "REDEEM_FAILED");

        underlying.safeTransfer(address(master), feesEarned); // master lets wards claim
    }

    /*///////////////////////////////////////////////////////////////
                          EMERGENCY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice someone must repay debt on behalf of the safe first
    function gib(CERC20 cToken, uint256 underlyingAmount) external {
        require(master.custodian().isAuthorizedToImpound(this, cToken, underlyingAmount), "CUSTODIAN_REJECTED");

        totalHoldings -= underlyingAmount; // only spot in the code where the safe can register a loss

        require(underlyingCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");

        underlying.safeTransfer(msg.sender, underlyingAmount);
    }
}

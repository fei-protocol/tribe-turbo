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

    /// @notice The Master contract that created the Safe.
    /// @dev Used to access the current Custodian and send fees.
    TurboMaster public immutable master;

    /*///////////////////////////////////////////////////////////////
                             VAULT STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The total underlying holdings of the Safe.
    /// @dev Increases on deposit and decreases on withdrawal or impound.
    uint256 public totalHoldings;

    /// @notice The base unit of the underlying token and hence tsToken.
    /// @dev Equal to 10 ** decimals. Used for fixed point arithmetic.
    uint256 public immutable baseUnit;

    /// @notice Maps Fei cTokens to the amount of Fei deposited to them.
    /// @dev Used to determine the fees to be paid back to the Master.
    mapping(CERC20 => uint256) getTotalFeiDeposited;

    /*///////////////////////////////////////////////////////////////
                             TOKEN STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Fei token on the network.
    ERC20 public immutable fei;

    /// @notice The underlying token the Safe accepts.
    ERC20 public immutable underlying;

    /*///////////////////////////////////////////////////////////////
                             FUSE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Fuse Pool contract that collateral is held in and Fei is borrowed from.
    Comptroller public immutable pool;

    /// @notice The Fei cToken in the Turbo Fuse Pool that is borrowed from
    CERC20 public immutable feiCToken;

    /// @notice The cToken that accepts the underlying token in the Turbo Fuse Pool.
    CERC20 public immutable underlyingCToken;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Safe that accepts a specific underlying token.
    /// @param _underlying The ERC20 compliant token the Safe should accept.
    constructor(address _owner, ERC20 _underlying)
        Auth(_owner, Authority(address(0)))
        ERC20(
            // ex: Dai Stablecoin Turbo Safe
            string(abi.encodePacked(_underlying.name(), " Turbo Safe")),
            // ex: tsDAI
            string(abi.encodePacked("ts", _underlying.symbol())),
            // ex: 18
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

        // If the provided underlying is not supported by the pool, revert.
        if (address(underlyingCToken) == address(0)) revert("UNSUPPORTED_UNDERLYING");
    }

    /*///////////////////////////////////////////////////////////////
                             VAULT LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted after a successful deposit.
    /// @param user The address that deposited into the Vault.
    /// @param underlyingAmount The amount of underlying tokens that were deposited.
    event Deposit(address indexed user, address indexed to, uint256 underlyingAmount);

    /// @notice Emitted after a successful withdrawal.
    /// @param user The address that withdrew from the Vault.
    /// @param to The destination for withdrawn tokens.
    /// @param underlyingAmount The amount of underlying tokens that were withdrawn.
    event Withdraw(address indexed user, address indexed to, uint256 underlyingAmount);

    /// @notice Deposit a specific amount of underlying tokens.
    /// @param underlyingAmount The amount of the underlying token to deposit.
    /// @dev Automatically supplies the underlying tokens into the Turbo Fuse Pool.
    function deposit(address to, uint256 underlyingAmount) external requiresAuth returns (uint256 shares) {
        // Determine the equivalent amount of tsTokens and mint them.
        _mint(to, shares = underlyingAmount.fdiv(exchangeRate(), baseUnit));

        // Update the total holdings proportionately.
        totalHoldings += underlyingAmount;

        emit Deposit(msg.sender, to, underlyingAmount);

        // Transfer in underlying tokens from the user.
        // This will revert if the user does not have the amount specified.
        underlying.safeTransferFrom(msg.sender, address(this), underlyingAmount);

        // Approve the underlying tokens to the Turbo Fuse Pool.
        underlying.approve(address(underlyingCToken), underlyingAmount);

        // Collateralize the underlying tokens in the Turbo Fuse Pool.
        require(underlyingCToken.mint(underlyingAmount) == 0, "MINT_FAILED");
    }

    /// @notice Withdraw a specific amount of underlying tokens.
    /// @param underlyingAmount The amount of underlying tokens to withdraw.
    /// @dev Withdraws the proper amount of underlying tokens from the Turbo Fuse Pool.
    /// @dev Will revert if not enough of the Safe's debt has been repaid via less or on our behalf.
    function withdraw(address to, uint256 underlyingAmount) external requiresAuth returns (uint256 shares) {
        // Determine the equivalent amount of tsTokens and burn them.
        // This will revert if the user does not have enough tsTokens.
        _burn(msg.sender, shares = underlyingAmount.fdiv(exchangeRate(), baseUnit));

        // Update the total holdings proportionately.
        totalHoldings -= underlyingAmount;

        emit Withdraw(msg.sender, to, underlyingAmount);

        // Withdraw the underlying tokens from the Turbo Fuse Pool.
        require(underlyingCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");

        // Transfer out the underlying tokens to the user.
        underlying.safeTransfer(to, underlyingAmount);
    }

    /// @notice Redeem a specific amount of tsTokens for underlying tokens.
    /// @param shareAmount The amount of tsTokens to redeem for underlying tokens.
    /// @dev Withdraws the proper amount of underlying tokens from the Turbo Fuse Pool.
    /// @dev Will revert if not enough of the Safe's debt has been repaid via less or on our behalf.
    function redeem(address to, uint256 shareAmount) external requiresAuth returns (uint256 underlyingAmount) {
        // Burn the provided amount of tsTokens.
        // This will revert if the user does not have enough tsTokens.
        _burn(msg.sender, shareAmount);

        // Update the total holdings proportionately.
        totalHoldings -= underlyingAmount = shareAmount.fmul(exchangeRate(), baseUnit);

        emit Withdraw(msg.sender, to, underlyingAmount);

        // Withdraw the underlying tokens from the Turbo Fuse Pool.
        require(underlyingCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");

        // Transfer out the underlying tokens to the user.
        underlying.safeTransfer(to, underlyingAmount);
    }

    /// @notice Returns the amount of underlying tokens a tsToken can be redeemed for.
    /// @return The amount of underlying tokens a tsvToken can be redeemed for.
    function exchangeRate() public view returns (uint256) {
        // Get the total supply of tsTokens.
        uint256 shareSupply = totalSupply;

        // If there are no tsTokens in circulation, return an exchange rate of 1:1.
        if (shareSupply == 0) return baseUnit;

        // Calculate the exchange rate by dividing the total holdings by the tsToken supply.
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
        require(
            master.custodian().isAuthorizedToImpound(msg.sender, this, cToken, underlyingAmount),
            "CUSTODIAN_REJECTED"
        );

        totalHoldings -= underlyingAmount; // only spot in the code where the safe can register a loss

        require(underlyingCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");

        underlying.safeTransfer(msg.sender, underlyingAmount);
    }
}

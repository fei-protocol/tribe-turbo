// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {LibFuse} from "libcompound/LibFuse.sol";
import {CERC20} from "libcompound/interfaces/CERC20.sol";

import {Comptroller} from "./interfaces/Comptroller.sol";

import {TurboMaster} from "./TurboMaster.sol";

/// @title Turbo Safe (tsToken)
/// @author Transmissions11
/// @notice Fuse liquidity accelerator.
contract TurboSafe is Auth, ERC4626 {
    using LibFuse for CERC20;
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Master contract that created the Safe.
    /// @dev Fees are paid directly to the Master, where they can be swept.
    TurboMaster public immutable master;

    /// @notice The Fei token on the network.
    ERC20 public immutable fei;

    /// @notice The Turbo Fuse Pool contract that collateral is held in and Fei is borrowed from.
    Comptroller public immutable pool;

    /// @notice The Fei cToken in the Turbo Fuse Pool that Fei is borrowed from.
    CERC20 public immutable feiTurboCToken;

    /// @notice The cToken that accepts the underlying token in the Turbo Fuse Pool.
    CERC20 public immutable underlyingTurboCToken;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Safe that accepts a specific underlying token.
    /// @param _owner The owner of the Safe.
    /// @param _authority The Authority of the Safe.
    /// @param _underlying The ERC20 compliant token the Safe should accept.
    constructor(
        address _owner,
        Authority _authority,
        ERC20 _underlying
    )
        Auth(_owner, _authority)
        ERC4626(
            _underlying,
            // ex: Dai Stablecoin Turbo Safe
            string(abi.encodePacked(_underlying.name(), " Turbo Safe")),
            // ex: tsDAI
            string(abi.encodePacked("ts", _underlying.symbol()))
        )
    {
        master = TurboMaster(msg.sender);

        fei = master.fei();

        // An underlying of Fei makes no sense.
        require(asset != fei, "INVALID_UNDERLYING");

        pool = master.pool();

        feiTurboCToken = pool.cTokensByUnderlying(fei);

        underlyingTurboCToken = pool.cTokensByUnderlying(asset);

        // If the provided underlying is not supported by the Turbo Fuse Pool, revert.
        require(address(underlyingTurboCToken) != address(0), "UNSUPPORTED_UNDERLYING");

        // Construct an array of market(s) to enable as collateral.
        CERC20[] memory marketsToEnter = new CERC20[](1);
        marketsToEnter[0] = underlyingTurboCToken;

        // Enter the market(s) and ensure to properly revert if there is an error.
        require(pool.enterMarkets(marketsToEnter)[0] == 0, "ENTER_MARKETS_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                               SAFE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The current total amount of Fei the Safe is using to boost Vaults.
    uint256 public totalFeiBoosted;

    /// @notice Maps Vaults to the total amount of Fei they've being boosted with.
    /// @dev Used to determine the fees to be paid back to the Master.
    mapping(ERC4626 => uint256) public getTotalFeiBoostedForVault;

    /*///////////////////////////////////////////////////////////////
                             ERC4626 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Called before any type of withdrawal occurs.
    /// @param underlyingAmount The amount of underlying tokens being withdrawn.
    /// @dev Using requiresAuth here prevents unauthorized users from withdrawing.
    function beforeWithdraw(uint256 underlyingAmount) internal override requiresAuth {
        // Withdraw the underlying tokens from the Turbo Fuse Pool.
        require(underlyingTurboCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");
    }

    /// @notice Called before any type of deposit occurs.
    /// @param underlyingAmount The amount of underlying tokens being deposited.
    /// @dev Using requiresAuth here prevents unauthorized users from depositing.
    function afterDeposit(uint256 underlyingAmount) internal override requiresAuth {
        // Approve the underlying tokens to the Turbo Fuse Pool.
        asset.approve(address(underlyingTurboCToken), underlyingAmount);

        // Collateralize the underlying tokens in the Turbo Fuse Pool.
        require(underlyingTurboCToken.mint(underlyingAmount) == 0, "MINT_FAILED");
    }

    /// @notice Returns the total amount of underlying tokens held in the Safe.
    /// @return The total amount of underlying tokens held in the Safe.
    function totalAssets() public view override returns (uint256) {
        return underlyingTurboCToken.viewUnderlyingBalanceOf(address(this));
    }

    /*///////////////////////////////////////////////////////////////
                           BOOST/LESS LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Vault is boosted by the Safe.
    /// @param user The user who slurped the Vault.
    /// @param vault The Vault that was boosted.
    /// @param feiAmount The amount of Fei that was boosted to the Vault.
    event VaultBoosted(address indexed user, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Borrow Fei from the Turbo Fuse Pool and deposit it into an authorized Vault.
    /// @param vault The Vault to deposit the borrowed Fei into.
    /// @param feiAmount The amount of Fei to borrow and supply into the Vault.
    /// @dev Automatically accrues any fees earned by the Safe in the Vault to the Master.
    function boost(ERC4626 vault, uint256 feiAmount) external requiresAuth {
        // Ensure the Vault accepts Fei underlying.
        require(vault.asset() == fei, "NOT_FEI");

        // Call the Master where it will do extra validation
        // and update it's total count of funds used for boosting.
        master.onSafeBoost(asset, vault, feiAmount);

        // Increase the boost total proportionately.
        totalFeiBoosted += feiAmount;

        unchecked {
            // Update the total Fei deposited into the Vault proportionately.
            // Cannot overflow because the total cannot be less than a single Vault.
            getTotalFeiBoostedForVault[vault] += feiAmount;
        }

        emit VaultBoosted(msg.sender, vault, feiAmount);

        // Borrow the Fei amount from the Fei cToken in the Turbo Fuse Pool.
        require(feiTurboCToken.borrow(feiAmount) == 0, "BORROW_FAILED");

        // Approve the borrowed Fei to the specified Vault.
        fei.safeApprove(address(vault), feiAmount);

        // Deposit the Fei into the specified Vault.
        vault.deposit(feiAmount, address(this));
    }

    /// @notice Emitted when a Vault is withdrawn from by the Safe.
    /// @param user The user who slurped the Vault.
    /// @param vault The Vault that was withdrawn from.
    /// @param feiAmount The amount of Fei that was withdrawn from the Vault.
    event VaultLessened(address indexed user, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Withdraw Fei from a deposited Vault and use it to repay debt in the Turbo Fuse Pool.
    /// @param vault The Vault to withdraw the Fei from.
    /// @param feiAmount The amount of Fei to withdraw from the Vault and repay in the Turbo Fuse Pool.
    /// @dev Automatically accrues any fees earned by the Safe in the Vault to the Master.
    function less(ERC4626 vault, uint256 feiAmount) external requiresAuth {
        // Update the total Fei deposited into the Vault proportionately.
        getTotalFeiBoostedForVault[vault] -= feiAmount;

        unchecked {
            // Decrease the boost total proportionately.
            // Cannot underflow because the total cannot be less than a single Vault.
            totalFeiBoosted -= feiAmount;
        }

        emit VaultLessened(msg.sender, vault, feiAmount);

        // Withdraw the specified amount of Fei from the Vault.
        vault.withdraw(feiAmount, address(this), address(this));

        // Approve the specified amount of Fei to Fei cToken in the Turbo Fuse Pool.
        fei.safeApprove(address(feiTurboCToken), feiAmount);

        // Get out current amount of Fei debt in the Turbo Fuse Pool.
        uint256 feiDebt = feiTurboCToken.borrowBalanceCurrent(address(this));

        // If our debt balance decreased, repay the minimum.
        // The surplus Fei will accrue as fees and can be sweeped.
        if (feiAmount > feiDebt) feiAmount = feiDebt;

        // Repay Fei debt in the Turbo Fuse Pool, unless we would repay nothing.
        if (feiAmount != 0) require(feiTurboCToken.repayBorrow(feiAmount) == 0, "REPAY_FAILED");

        // Call the Master to allow it to update its accounting.
        master.onSafeLess(asset, vault, feiAmount);
    }

    /*///////////////////////////////////////////////////////////////
                              SLURP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Vault is slurped from by the Safe.
    /// @param user The user who slurped the Vault.
    /// @param vault The Vault that was slurped.
    /// @param protocolFeeAmount The amount of Fei accrued as fees to the Master.
    /// @param safeInterestAmount The amount of Fei accrued as interest to the Safe.
    event VaultSlurped(
        address indexed user,
        ERC4626 indexed vault,
        uint256 protocolFeeAmount,
        uint256 safeInterestAmount
    );

    /// @notice Accrue any interest earned by the Safe in the Vault.
    /// @param vault The Vault to accrue interest from, if any.
    /// @dev Sends a portion of the interest to the Master, as determined by the Clerk.
    function slurp(ERC4626 vault) external {
        // Ensure the Safe has Fei currently boosting the Vault.
        require(getTotalFeiBoostedForVault[vault] != 0, "NO_FEI_BOOSTED");

        // Compute the amount of Fei interest the Safe generated by boosting the Vault.
        uint256 interestEarned = vault.assetsOf(address(this)) - getTotalFeiBoostedForVault[vault];

        // Compute what percentage of the interest earned will go back to the
        uint256 protocolFeePercent = master.clerk().getFeePercentageForSafe(this, asset);

        // Compute the amount of Fei the protocol will retain as fees.
        uint256 protocolFeeAmount = interestEarned.mulWadDown(protocolFeePercent);

        // Compute the amount of Fei the Safe will retain as interest.
        uint256 safeInterestAmount = interestEarned - protocolFeeAmount;

        // Increase the boost total proportionately.
        totalFeiBoosted += safeInterestAmount;

        unchecked {
            // Update the total Fei held in the Vault proportionately.
            // Cannot overflow because the total cannot be less than a single Vault.
            getTotalFeiBoostedForVault[vault] += safeInterestAmount;
        }

        emit VaultSlurped(msg.sender, vault, protocolFeeAmount, safeInterestAmount);

        // If we have unaccrued fees, withdraw them from the Vault and transfer them to the Master.
        if (protocolFeeAmount != 0) vault.withdraw(protocolFeeAmount, address(this), address(master));
    }

    /*///////////////////////////////////////////////////////////////
                              SWEEP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted a token is sweeped from the Safe.
    /// @param user The user who sweeped the token from the Safe.
    /// @param to The recipient of the sweeped tokens.
    /// @param amount The amount of the token that was sweeped.
    event TokenSweeped(address indexed user, address indexed to, ERC20 indexed token, uint256 amount);

    /// @notice Claim tokens sitting idly in the Safe.
    /// @param to The recipient of the sweeped tokens.
    /// @param token The token to sweep and send.
    /// @param amount The amount of the token to sweep.
    function sweep(
        address to,
        ERC20 token,
        uint256 amount
    ) external requiresAuth {
        // Ensure the caller is not trying to steal Vault shares or collateral cTokens.
        require(
            getTotalFeiBoostedForVault[ERC4626(address(token))] == 0 && token != underlyingTurboCToken,
            "INVALID_TOKEN"
        );

        emit TokenSweeped(msg.sender, to, token, amount);

        // Transfer the sweeped tokens to the recipient.
        token.safeTransfer(to, amount);
    }

    /*///////////////////////////////////////////////////////////////
                               GIB LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a Safe is gibbed.
    /// @param user The user who gibbed the Safe.
    /// @param to The recipient of the impounded collateral.
    /// @param underlyingAmount The amount of underling tokens impounded.
    event SafeGibbed(address indexed user, address indexed to, uint256 underlyingAmount);

    /// @notice Impound a specific amount of a Safe's collateral.
    /// @param to The address to send the impounded collateral to.
    /// @param underlyingAmount The amount of the underlying to impound.
    /// @dev Can only be called by the Gibber, not by the Safe owner.
    /// @dev Debt must be repaid in advance, or the redemption will fail.
    function gib(address to, uint256 underlyingAmount) external {
        // Ensure the caller is the Master's current Gibber.
        require(msg.sender == address(master.gibber()), "NOT_GIBBER");

        emit SafeGibbed(msg.sender, to, underlyingAmount);

        // Withdraw the specified amount of underlying tokens from the Turbo Fuse Pool.
        require(underlyingTurboCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");

        // Transfer the underlying tokens to the authorized caller.
        asset.safeTransfer(to, underlyingAmount);
    }
}

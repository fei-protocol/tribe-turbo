// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {CERC20} from "./interfaces/CERC20.sol";
import {ERC4626} from "./interfaces/ERC4626.sol";
import {Comptroller} from "./interfaces/Comptroller.sol";

import {TurboMaster} from "./TurboMaster.sol";

/// @title Turbo Safe (tsToken)
/// @author Transmissions11
/// @notice Fuse liquidity accelerator.
contract TurboSafe is Auth, ERC20, ERC4626 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*///////////////////////////////////////////////////////////////
                          TURBO MASTER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The Master contract that created the Safe.
    /// @dev Used to access the current Custodian and send fees.
    TurboMaster public immutable master;

    /*///////////////////////////////////////////////////////////////
                               SAFE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The current total amount of Fei the Safe is using to boost vaults.
    uint256 totalFeiBoosted;

    /// @notice Maps vaults to the total amount of Fei they've being boosted with.
    /// @dev Used to determine the fees to be paid back to the Master.
    mapping(ERC4626 => uint256) getTotalFeiBoostedForVault;

    /// @notice The Fei token on the network.
    ERC20 public immutable fei;

    /// @notice The Turbo Fuse Pool contract that collateral is held in and Fei is borrowed from.
    Comptroller public immutable pool;

    /// @notice The Fei cToken in the Turbo Fuse Pool that is borrowed from
    CERC20 public immutable feiTurboCToken;

    /// @notice The vault that accepts the underlying token in the Turbo Fuse Pool.
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
        pool = master.pool();
        feiTurboCToken = pool.cTokensByUnderlying(fei);
        underlyingTurboCToken = pool.cTokensByUnderlying(underlying);

        // If the provided underlying is not supported by the Turbo Fuse Pool, revert.
        if (address(underlyingTurboCToken) == address(0)) revert("UNSUPPORTED_UNDERLYING");
    }

    /*///////////////////////////////////////////////////////////////
                             ERC4626 LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Called before any type of withdrawal occurs.
    /// @param underlyingAmount The amount of underlying tokens being withdrawn.
    function beforeWithdraw(uint256 underlyingAmount) internal override {
        // Withdraw the underlying tokens from the Turbo Fuse Pool.
        require(underlyingTurboCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");
    }

    /// @notice Called before any type of deposit occurs.
    /// @param underlyingAmount The amount of underlying tokens being deposited.
    function afterDeposit(uint256 underlyingAmount) internal override {
        // Approve the underlying tokens to the Turbo Fuse Pool.
        underlying.approve(address(underlyingTurboCToken), underlyingAmount);

        // Collateralize the underlying tokens in the Turbo Fuse Pool.
        require(underlyingTurboCToken.mint(underlyingAmount) == 0, "MINT_FAILED");
    }

    /// @notice Returns the total amount of underlying tokens held in the Safe.
    /// @return The total amount of underlying tokens held in the Safe.
    function totalHoldings() public view override returns (uint256) {
        // TODO: this require libcompound
    }

    /*///////////////////////////////////////////////////////////////
                             SAFE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a vault is boosted by the Safe.
    /// @param user The user who slurped the vault.
    /// @param vault The vault that was boosted.
    /// @param feiAmount The amount of Fei that was boosted to the vault.
    event VaultBoosted(address indexed user, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Borrow Fei from the Turbo Fuse Pool and deposit it into an authorized vault.
    /// @param vault The vault to deposit the borrowed Fei into.
    /// @param feiAmount The amount of Fei to borrow and supply into the vault.
    /// @dev Automatically accrues any fees earned by the Safe in the vault to the Master.
    function boost(ERC4626 vault, uint256 feiAmount) external requiresAuth {
        // Ensure the vault accepts Fei underlying.
        require(vault.underlying() == fei, "NOT_FEI");

        slurp(vault); // Accrue any fees earned by the vault.

        // Call the Master where it will do extra validation
        // and update it's total count of funds used for boosting.
        master.onSafeBoost(vault, feiAmount);

        unchecked {
            // Update the total Fei deposited into the vault proportionately.
            // Overflow is safe because it will be caught when updating the total.
            getTotalFeiBoostedForVault[vault] += feiAmount;
        }

        // Increase the boost total proportionately.
        totalFeiBoosted += feiAmount;

        emit VaultBoosted(msg.sender, vault, feiAmount);

        // Borrow the Fei amount from the Fei cToken in the Turbo Fuse Pool.
        require(feiTurboCToken.borrow(feiAmount) == 0, "BORROW_FAILED");

        // Approve the borrowed Fei to the specified vault.
        fei.safeApprove(address(vault), feiAmount);

        // Deposit the Fei into the specified vault.
        vault.deposit(address(this), feiAmount);
    }

    /// @notice Emitted when a vault is withdrawn from by the Safe.
    /// @param user The user who slurped the vault.
    /// @param vault The vault that was withdrawn from.
    /// @param feiAmount The amount of Fei that was withdrawn from the vault.
    event VaultLessened(address indexed user, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Withdraw Fei from a deposited vault and use it to repay debt in the Turbo Fuse Pool.
    /// @param vault The vault to withdraw the Fei from.
    /// @param feiAmount The amount of Fei to withdraw from the vault and repay in the Turbo Fuse Pool.
    /// @dev Automatically accrues any fees earned by the Safe in the vault to the Master.
    function less(ERC4626 vault, uint256 feiAmount) external requiresAuth {
        slurp(vault); // Accrue any fees earned by the vault.

        // Update the total Fei deposited into the vault proportionately.
        getTotalFeiBoostedForVault[vault] -= feiAmount;

        unchecked {
            // Decrease the boost total proportionately.
            // Cannot underflow because the total cannot be lower than a single vault.
            totalFeiBoosted -= feiAmount;
        }

        emit VaultLessened(msg.sender, vault, feiAmount);

        // Withdraw the specified amount of Fei from the vault.
        vault.withdraw(address(this), feiAmount);

        // Approve the specified amount of Fei to Fei cToken in the Turbo Fuse Pool.
        fei.safeApprove(address(feiTurboCToken), feiAmount);

        // Get out current amount of Fei debt in the Turbo Fuse Pool.
        uint256 feiDebt = feiTurboCToken.borrowBalanceCurrent(address(this));

        // If our debt balance decreased, repay the minimum.
        // The surplus Fei will accrue as fees and can be sweeped.
        if (feiAmount > feiDebt) feiAmount = feiDebt;

        // Repay the specified amount of Fei in the Turbo Fuse Pool.
        require(feiTurboCToken.repayBorrow(feiAmount) == 0, "REPAY_FAILED");

        // Call the Master to allow it to update its accounting.
        master.onSafeLess(vault, feiAmount);
    }

    /// @notice Emitted when a vault is slurped from by the Safe.
    /// @param user The user who slurped the vault.
    /// @param vault The vault that was slurped.
    /// @param protocolFeeAmount The amount of Fei accrued as fees to the Master.
    /// @param safeInterestAmount The amount of Fei accrued as interest to the Safe.
    event VaultSlurped(
        address indexed user,
        ERC4626 indexed vault,
        uint256 protocolFeeAmount,
        uint256 safeInterestAmount
    );

    /// @notice Accrue any fees earned by the Safe in the vault to the Master.
    /// @param vault The vault to accrue fees from and send to the Master.
    function slurp(ERC4626 vault) public {
        // Ensure the Safe has Fei currently boosting the vault.
        require(getTotalFeiBoostedForVault[vault] != 0, "NO_FEI_BOOSTED");

        // Compute the amount of Fei interest the Safe generated by boosting the vault.
        uint256 interestEarned = vault.balanceOfUnderlying(address(this)) - getTotalFeiBoostedForVault[vault];

        // Compute what percentage of the interest earned will go back to the
        uint256 protocolFeePercent = master.clerk().getFeePercentageForSafe(this, underlying);

        // Compute the amount of Fei the protocol will retain as fees.
        uint256 protocolFeeAmount = interestEarned.fmul(protocolFeePercent, 1e18);

        // Compute the amount of Fei the Safe will retain as interest.
        uint256 safeInterestAmount = interestEarned - protocolFeeAmount;

        unchecked {
            // Update the total Fei held in the vault proportionately.
            // Overflow is safe because it will be caught when updating the total.
            getTotalFeiBoostedForVault[vault] += safeInterestAmount;
        }

        // Increase the boost total proportionately.
        totalFeiBoosted += safeInterestAmount;

        emit VaultSlurped(msg.sender, vault, protocolFeeAmount, safeInterestAmount);

        // If we have an accrued fees:
        if (protocolFeeAmount != 0) {
            // Withdraw them from the vault.
            vault.withdraw(address(this), protocolFeeAmount);

            // Transfer the fees owed as Fei to the Master.
            fei.safeTransfer(address(master), protocolFeeAmount);
        }
    }

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
        // Ensure the caller is not trying to steal vault shares or collateral cTokens.
        require(
            getTotalFeiBoostedForVault[ERC4626(address(token))] == 0 &&
                address(token) != address(underlyingTurboCToken),
            "INVALID_TOKEN"
        );

        emit TokenSweeped(msg.sender, to, token, amount);

        token.safeTransfer(to, amount);
    }

    /// @notice Emitted when a Safe is gibbed.
    /// @param user The user who gibbed the Safe.
    /// @param to The recipient of the impounded collateral.
    /// @param underlyingAmount The amount of underling tokens impounded.
    event SafeGibbed(address indexed user, address indexed to, uint256 underlyingAmount);

    /// @notice Impound a specific amount of a Safe's collateral.
    /// @param to The address to send the impounded collateral to.
    /// @param underlyingAmount The amount of the underlying to impound.
    /// @dev Requires special authorization from the Custodian.
    /// @dev Debt must be repaid in advance, or the redemption will fail.
    function gib(address to, uint256 underlyingAmount) external {
        // Ensure the caller is the Master's current Gibber.
        require(msg.sender == address(master.gibber()), "NOT_GIBBER");

        emit SafeGibbed(msg.sender, to, underlyingAmount);

        // Withdraw the specified amount of underlying tokens from the Turbo Fuse Pool.
        require(underlyingTurboCToken.redeemUnderlying(underlyingAmount) == 0, "REDEEM_FAILED");

        // Transfer the underlying tokens to the authorized caller.
        underlying.safeTransfer(to, underlyingAmount);
    }
}

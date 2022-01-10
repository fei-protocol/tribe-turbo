// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate-next/tokens/ERC20.sol";
import {Auth, Authority} from "solmate-next/auth/Auth.sol";

import {CERC20} from "libcompound/interfaces/CERC20.sol";

import {TurboSafe} from "../TurboSafe.sol";

/// @title Fei
/// @author Fei Protocol
/// @notice Minimal interface for the Fei token.
abstract contract Fei is ERC20 {
    function mint(address to, uint256 amount) external virtual;
}

/// @title Turbo Gibber
/// @author Transmissions11
/// @notice Atomic impounder module.
contract TurboGibber is Auth {
    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Clerk contract.
    /// @param _owner The owner of the Clerk.
    /// @param _authority The Authority of the Clerk.
    constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

    /*///////////////////////////////////////////////////////////////
                          ATOMIC IMPOUND LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted an impound is executed.
    /// @param user The user who executed the impound.
    /// @param safe The Safe that was impounded.
    /// @param feiAmount The amount of Fei that was repaid.
    /// @param underlyingAmount The amount of underlying tokens impounded.
    event ImpoundExecuted(address indexed user, TurboSafe indexed safe, uint256 feiAmount, uint256 underlyingAmount);

    /// @notice Impound a safe.
    /// @param safe The Safe to be impounded.
    /// @param feiAmount The amount of Fei to repay the Safe's debt with.
    /// @param underlyingAmount The amount of underlying tokens to impound.
    /// @param to The recipient of the impounded collateral tokens.
    function impound(
        TurboSafe safe,
        uint256 feiAmount,
        uint256 underlyingAmount,
        address to
    ) external requiresAuth {
        // Get the Fei token the Safe uses.
        Fei fei = Fei(address(safe.fei()));

        // Get Fei's cToken in the Turbo Fuse Pool.
        CERC20 feiCToken = safe.feiTurboCToken();

        emit ImpoundExecuted(msg.sender, safe, feiAmount, underlyingAmount);

        // Mint the Fei amount requested.
        fei.mint(address(this), feiAmount);

        // Approve the Fei amount to the Fei cToken.
        fei.approve(address(feiCToken), feiAmount);

        // Repay the safe's Fei debt with the minted Fei.
        feiCToken.repayBorrowBehalf(address(safe), feiAmount);

        // Impound some of the safe's collateral and send it to the chosen recipient.
        safe.gib(to, underlyingAmount);
    }

    /// @notice Impound all of a safe's collateral.
    /// @param safe The Safe to be impounded.
    /// @param to The recipient of the impounded collateral tokens.
    function impoundAll(TurboSafe safe, address to) external requiresAuth {
        // Get the Fei token the Safe uses.
        Fei fei = Fei(address(safe.fei()));

        // Get Fei's cToken in the Turbo Fuse Pool.
        CERC20 feiCToken = safe.feiTurboCToken();

        // Get the underlying cToken in the Turbo Fuse Pool.
        CERC20 underlyingCToken = safe.underlyingTurboCToken();

        // Get the amount of underlying tokens to impound from the Safe.
        uint256 underlyingAmount = underlyingCToken.balanceOfUnderlying(address(safe));

        // Get the amount of Fei debt to repay for the Safe.
        uint256 feiAmount = underlyingCToken.borrowBalanceCurrent(address(safe));

        emit ImpoundExecuted(msg.sender, safe, feiAmount, underlyingAmount);

        // Mint the Fei amount requested.
        fei.mint(address(this), feiAmount);

        // Approve the Fei amount to the Fei cToken.
        fei.approve(address(feiCToken), feiAmount);

        // Repay the safe's Fei debt with the minted Fei.
        feiCToken.repayBorrowBehalf(address(safe), feiAmount);

        // Impound all of the safe's collateral and send it to the chosen recipient.
        safe.gib(to, underlyingAmount);
    }
}

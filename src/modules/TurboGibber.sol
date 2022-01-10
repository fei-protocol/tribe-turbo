// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {CERC20} from "../interfaces/CERC20.sol";

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

    /// @notice Creates a new Turbo Accountant contract.
    /// @param _owner The owner of the Accountant.
    /// @param _authority The Authority of the Accountant.
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

    function impoundAll(
        TurboSafe safe,
        uint256 feiAmount,
        address to
    ) external requiresAuth {
        // Get the Fei token the Safe uses.
        Fei fei = Fei(address(safe.fei()));

        // Get Fei's cToken in the Turbo Fuse Pool.
        CERC20 feiCToken = safe.feiTurboCToken();

        // Get the underlying cToken in the Turbo Fuse Pool.
        CERC20 underlyingCToken = safe.underlyingTurboCToken();

        // Get the amount of underlying tokens to impound from the Safe.
        uint256 underlyingAmount = underlyingCToken.balanceOfUnderlying(address(safe));

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

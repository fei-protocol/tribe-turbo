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

    // TODO: event

    function impoundSafe(
        TurboSafe safe,
        uint256 feiAmount,
        uint256 underlyingAmount,
        address to
    ) external requiresAuth {
        // Get the Fei token the Safe uses.
        Fei fei = Fei(address(safe.fei()));

        CERC20 feiCToken = safe.feiCToken();

        // Mint the Fei amount requested.
        fei.mint(address(this), feiAmount);

        // Approve the Fei amount to the Fei cToken.
        fei.approve(address(feiCToken), feiAmount);

        // Repay the safe's Fei debt with the minted Fei.
        feiCToken.repayBorrowBehalf(address(safe), feiAmount);

        // Impound the safe's collateral and send it to the chosen recipient.
        safe.gib(to, underlyingAmount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {Auth, Authority} from "solmate/auth/Auth.sol";

import {TurboSafe} from "../TurboSafe.sol";

/// @title Turbo Gibber
/// @author Transmissions11
/// @notice Atomic impounder module.
contract Gibber is Auth {
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

    function impoundSafe(
        TurboSafe safe,
        uint256 feiAmount,
        uint256 underlyingAmount
    ) external {
        // TODO: approve.

        safe.feiCToken().repayBorrowBehalf(address(safe), feiAmount);

        safe.gib(underlyingAmount);
    }
}

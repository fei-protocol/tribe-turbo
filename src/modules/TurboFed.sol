// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";

import {TurboSafe} from "../TurboSafe.sol";
import {TurboMaster} from "../TurboMaster.sol";

/// @title Turbo Fed
/// @author Transmissions11
/// @notice Force contraction module.
contract TurboFed is Auth, ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The Master contract.
    /// @dev Used to validate Safes are legitimate.
    TurboMaster public immutable master;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Creates a new Turbo Fed contract.
    /// @param _master The Master of the Fed.
    /// @param _owner The owner of the Fed.
    /// @param _authority The Authority of the Fed.
    constructor(
        TurboMaster _master,
        address _owner,
        Authority _authority
    ) Auth(_owner, _authority) {
        master = _master;
    }

    /*///////////////////////////////////////////////////////////////
                        FORCE CONTRACTION LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted a pucker is executed.
    /// @param user The user who triggered the pucker.
    /// @param safe The Safe that less was called on.
    /// @param vault The Vault that less was called with.
    /// @param feiAmount The amount of Fei less was called with.
    event Puckered(address indexed user, TurboSafe indexed safe, ERC4626 indexed vault, uint256 feiAmount);

    /// @notice Force less a Safe.
    /// @param safe The Safe to call less on.
    /// @param vault The Vault to call less.
    /// @param feiAmount The amount of Fei to call less with.
    function pucker(
        TurboSafe safe,
        ERC4626 vault,
        uint256 feiAmount
    ) external requiresAuth nonReentrant {
        // Ensure the Safe is registered with the Master.
        require(master.getSafeId(safe) != 0);

        emit Puckered(msg.sender, safe, vault, feiAmount);

        // Force the Safe to less, withdrawing Fei and repaying debt.
        safe.less(vault, feiAmount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {TurboMaster} from "./TurboMaster.sol";
import {TurboSafe} from "./TurboSafe.sol";
import {AuthLock} from "./authorities/AuthLock.sol";
import {ERC20} from "solmate-next/tokens/ERC20.sol";
import {Auth, Authority} from "solmate-next/auth/Auth.sol";

contract TurboRouter is AuthLock {

    TurboMaster public immutable master;

    uint256 private constant _NOT_IN_MULTICALL = 0;
    uint256 private constant _IN_MULTICALL = 1;

    uint256 private _multicallStatus;

    TurboSafe private _safe;

    constructor (TurboMaster _master) {
        master = _master;
    }

    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results) {
        require(_multicallStatus == _NOT_IN_MULTICALL, "already in multicall");
        _multicallStatus = _IN_MULTICALL;

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }

        _multicallStatus = _NOT_IN_MULTICALL;
        _safe = TurboSafe(address(0));
    }

    function setSafe(TurboSafe safe) external {
        require(_multicallStatus == _IN_MULTICALL, "not in multicall");
        _safe = safe;
    }

    function createSafe(ERC20 underlying) external {
        require(_multicallStatus == _IN_MULTICALL, "not in multicall");
        (TurboSafe safe, ) = master.createSafe(underlying);

        _safe = safe;
    }

    function setOwner(address newOwner) external authLock(Auth(address(_safe)), msg.sig) {
        _safe.setOwner(newOwner);
    }

    function setAuthority(Authority newAuthority) external authLock(Auth(address(_safe)), msg.sig) {
        _safe.setAuthority(newAuthority);
    }

    function deposit(address to, uint256 value) external authLock(Auth(address(_safe)), msg.sig) {
        _safe.deposit(to, value);
    }
    // TODO add remaining safe functions

    // TODO add https://github.com/Uniswap/v3-periphery/blob/main/contracts/base/SelfPermit.sol
}
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {TurboMaster} from "./TurboMaster.sol";
import {TurboSafe} from "./TurboSafe.sol";

import {ENSReverseRecord} from "ERC4626/ens/ENSReverseRecord.sol";
import {IERC4626, ERC4626RouterBase, IWETH9, PeripheryPayments} from "ERC4626/ERC4626RouterBase.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {ERC4626} from "solmate/mixins/ERC4626.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

/**
 @title a router which can perform multiple Turbo actions between Master and the Safes
 @notice routes custom users flows between actions on the master and safes.
         Accomodates use cases where the Safe and actions on the created Safe happen in the same transaction.
         Supported Flows:
          * creating a safe
          * Auth methods (set owner/authority)
          * ERC-4626 methods (deposit/withdraw/mint/redeem)
          * TurboSafe methods (boost/less/sweep/slurp)
 */
contract TurboRouter is ERC4626RouterBase, ENSReverseRecord {
    using SafeTransferLib for ERC20;

    TurboMaster public immutable master;

    constructor (TurboMaster _master, string memory name, IWETH9 weth) ENSReverseRecord(name) PeripheryPayments(weth) {
        master = _master;
    }

    modifier authenticate(Auth target, bytes4 sig) {
        Authority auth = target.authority();

        require((address(auth) != address(0) && auth.canCall(msg.sender, address(target), sig)) || msg.sender == target.owner(), "not authed");

        _;
    }

    function createSafeAndDeposit(ERC20 underlying) external {
        (TurboSafe safe, ) = master.createSafe(underlying);

        safe.setOwner(msg.sender);
    }

    function deposit(IERC4626 safe, address to, uint256 amount, uint256 minSharesOut) 
        public 
        payable 
        override 
        authenticate(Auth(address(safe)), IERC4626.deposit.selector) 
        returns (uint256) 
    {
        return super.deposit(safe, to, amount, minSharesOut);
    }

    function mint(IERC4626 safe, address to, uint256 shares, uint256 maxAmountIn) 
        public 
        payable 
        override 
        authenticate(Auth(address(safe)), IERC4626.mint.selector) 
        returns (uint256) 
    {
        return super.mint(safe, to, shares, maxAmountIn);
    }

    function withdraw(IERC4626 safe, address to, uint256 amount, uint256 minSharesOut) 
        public 
        payable 
        override 
        authenticate(Auth(address(safe)), IERC4626.withdraw.selector) 
        returns (uint256) 
    {
        return super.withdraw(safe, to, amount, minSharesOut);
    }

    function redeem(IERC4626 safe, address to, uint256 shares, uint256 minAmountOut) 
        public 
        payable 
        override 
        authenticate(Auth(address(safe)), IERC4626.redeem.selector) 
        returns (uint256) 
    {
        return super.redeem(safe, to, shares, minAmountOut);
    }

    function slurp(TurboSafe safe, ERC4626 vault) external {
        safe.slurp(vault);
    }

    function boost(TurboSafe safe, ERC4626 vault, uint256 feiAmount) external authenticate(Auth(address(safe)), TurboSafe.boost.selector) {
        safe.boost(vault, feiAmount);
    }

    function less(TurboSafe safe, ERC4626 vault, uint256 feiAmount) external authenticate(Auth(address(safe)), TurboSafe.less.selector) {
        safe.less(vault, feiAmount);
    }

    function sweep(TurboSafe safe, address to, ERC20 token, uint256 amount) external authenticate(Auth(address(safe)), TurboSafe.sweep.selector) {
        safe.sweep(to, token, amount);
    }

    // TODO cleanup IERC4626 router so we don't need to add the below functions
    function depositToVault(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {}

    function withdrawToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {}

    function redeemToDeposit(
        IERC4626 fromVault,
        IERC4626 toVault,
        address to,
        uint256 shares,
        uint256 minSharesOut
    ) external payable returns (uint256 sharesOut) {}

}
pragma solidity ^0.8.0;

import "../interfaces/Comptroller.sol";
import {TimelockController} from "@openzeppelin/governance/TimelockController.sol";
import {Auth, Authority} from "solmate/auth/Auth.sol";

import {TurboBooster} from "./TurboBooster.sol";
import {TurboClerk} from "./TurboClerk.sol";

interface IMasterOracle {
    function add(address[] calldata underlyings, address[] calldata _oracles)
        external;

    function changeAdmin(address newAdmin) external;

    function admin() external view returns (address);
}

contract TurboAdmin is Auth {

    error ComptrollerError();

    /// @notice the fuse comptroller
    Comptroller public immutable comptroller;

    TimelockController public immutable timelock;

    /// @param _comptroller the fuse comptroller
    constructor(Comptroller _comptroller, TimelockController _timelock, Authority _authority) Auth(address(0), _authority) {
        comptroller = _comptroller;
        timelock = _timelock;
    }

    // ************ BORROW GUARDIAN FUNCTIONS ************
    /**
     * @notice Set the given supply caps for the given cToken markets. Supplying that brings total underlying supply to or above supply cap will revert.
     * @dev Admin or borrowCapGuardian function to set the supply caps. A supply cap of 0 corresponds to unlimited supplying.
     * @param cTokens The addresses of the markets (tokens) to change the supply caps for
     * @param newSupplyCaps The new supply cap values in underlying to be set. A value of 0 corresponds to unlimited supplying.
     */
    function _setMarketSupplyCaps(
        CERC20[] memory cTokens,
        uint256[] calldata newSupplyCaps
    ) external requiresAuth {
        _setMarketSupplyCapsInternal(cTokens, newSupplyCaps);
    }

    function _setMarketSupplyCapsByUnderlying(
        address[] calldata underlyings,
        uint256[] calldata newSupplyCaps
    ) external requiresAuth {
        _setMarketSupplyCapsInternal(
            _underlyingToCTokens(underlyings),
            newSupplyCaps
        );
    }

    function _setMarketSupplyCapsInternal(
        CERC20[] memory cTokens,
        uint256[] calldata newSupplyCaps
    ) internal {
        comptroller._setMarketSupplyCaps(cTokens, newSupplyCaps);
    }

    function _underlyingToCTokens(address[] calldata underlyings)
        internal
        view
        returns (CERC20[] memory)
    {
        CERC20[] memory cTokens = new CERC20[](underlyings.length);
        for (uint256 i = 0; i < underlyings.length; i++) {
            CERC20 cToken = comptroller.cTokensByUnderlying(ERC20(underlyings[i]));
            require(address(cToken) != address(0), "cToken doesn't exist");
            cTokens[i] = CERC20(cToken);
        }
        return cTokens;
    }

    /**
     * @notice Set the given borrow caps for the given cToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev Admin or borrowCapGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing.
     * @param cTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
     */
    function _setMarketBorrowCaps(
        CERC20[] memory cTokens,
        uint256[] calldata newBorrowCaps
    ) external requiresAuth {
        _setMarketBorrowCapsInternal(cTokens, newBorrowCaps);
    }

    function _setMarketBorrowCapsInternal(
        CERC20[] memory cTokens,
        uint256[] calldata newBorrowCaps
    ) internal {
        comptroller._setMarketBorrowCaps(cTokens, newBorrowCaps);
    }

    function _setMarketBorrowCapsByUnderlying(
        address[] calldata underlyings,
        uint256[] calldata newBorrowCaps
    ) external requiresAuth {
        _setMarketBorrowCapsInternal(
            _underlyingToCTokens(underlyings),
            newBorrowCaps
        );
    }

    /**
     * @notice Admin function to change the Borrow Cap Guardian
     * @param newBorrowCapGuardian The address of the new Borrow Cap Guardian
     */
    function _setBorrowCapGuardian(address newBorrowCapGuardian)
        external
        requiresAuth
    {
        comptroller._setBorrowCapGuardian(newBorrowCapGuardian);
    }

    // ************ PAUSE GUARDIAN FUNCTIONS ************
    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian)
        external
        requiresAuth
        returns (uint256)
    {
        return comptroller._setPauseGuardian(newPauseGuardian);
    }

    function _setMintPausedByUnderlying(ERC20 underlying, bool state)
        external
        requiresAuth
        returns (bool)
    {
        CERC20 cToken = comptroller.cTokensByUnderlying(underlying);
        require(address(cToken) != address(0), "cToken doesn't exist");
        _setMintPausedInternal(cToken, state);
    }

    function _setMintPaused(CERC20 cToken, bool state)
        external
        requiresAuth
        returns (bool)
    {
        return _setMintPausedInternal(cToken, state);
    }

    function _setMintPausedInternal(CERC20 cToken, bool state)
        internal
        returns (bool)
    {
        return comptroller._setMintPaused(cToken, state);
    }

    function _setBorrowPausedByUnderlying(ERC20 underlying, bool state)
        external
        requiresAuth
        returns (bool)
    {
        CERC20 cToken = comptroller.cTokensByUnderlying(underlying);
        require(address(cToken) != address(0), "cToken doesn't exist");
        return _setBorrowPausedInternal(cToken, state);
    }

    function _setBorrowPausedInternal(CERC20 cToken, bool state)
        internal
        returns (bool)
    {
        return comptroller._setBorrowPaused(cToken, state);
    }

    function _setBorrowPaused(CERC20 cToken, bool state)
        external
        requiresAuth
        returns (bool)
    {
        return _setBorrowPausedInternal(CERC20(cToken), state);
    }

    function _setTransferPaused(bool state)
        external
        requiresAuth
        returns (bool)
    {
        return comptroller._setTransferPaused(state);
    }

    function _setSeizePaused(bool state)
        external
        requiresAuth
        returns (bool)
    {
        return comptroller._setSeizePaused(state);
    }

    ///// ADMIN functions

    function oracleAdd(
        address[] calldata underlyings,
        address[] calldata _oracles
    ) external requiresAuth {
        IMasterOracle(address(comptroller.oracle())).add(underlyings, _oracles);
    }

    function oracleChangeAdmin(address newAdmin) external requiresAuth {
        IMasterOracle(address(comptroller.oracle())).changeAdmin(newAdmin);
    }

    function _addRewardsDistributor(address distributor)
        external
        requiresAuth
    {
        if (comptroller._addRewardsDistributor(distributor) != 0)
            revert ComptrollerError();
    }

    function _setWhitelistEnforcement(bool enforce)
        external
        requiresAuth
    {
        if (comptroller._setWhitelistEnforcement(enforce) != 0)
            revert ComptrollerError();
    }

    function _setWhitelistStatuses(
        address[] calldata suppliers,
        bool[] calldata statuses
    ) external requiresAuth {
        if (comptroller._setWhitelistStatuses(suppliers, statuses) != 0)
            revert ComptrollerError();
    }

    function _setPriceOracle(address newOracle) public requiresAuth {
        if (comptroller._setPriceOracle(newOracle) != 0)
            revert ComptrollerError();
    }

    function _setCloseFactor(uint256 newCloseFactorMantissa)
        external
        requiresAuth
    {
        if (comptroller._setCloseFactor(newCloseFactorMantissa) != 0)
            revert ComptrollerError();
    }

    function _setCollateralFactor(
        CERC20 cToken,
        uint256 newCollateralFactorMantissa
    ) public requiresAuth {
        if (
            comptroller._setCollateralFactor(
                cToken,
                newCollateralFactorMantissa
            ) != 0
        ) revert ComptrollerError();
    }

    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external
        requiresAuth
    {
        if (
            comptroller._setLiquidationIncentive(
                newLiquidationIncentiveMantissa
            ) != 0
        ) revert ComptrollerError();
    }

    // TODO replace
    function _deployMarket(
        address underlying,
        address irm,
        string calldata name,
        string calldata symbol,
        address impl,
        bytes calldata data,
        uint256 reserveFactor,
        uint256 adminFee,
        uint256 collateralFactorMantissa
    ) external requiresAuth {
        bytes memory constructorData = abi.encode(
            underlying,
            address(comptroller),
            irm,
            name,
            symbol,
            impl,
            data,
            reserveFactor,
            adminFee
        );

        if (
            comptroller._deployMarket(
                false,
                constructorData,
                collateralFactorMantissa
            ) != 0
        ) revert ComptrollerError();
    }

    function _unsupportMarket(CERC20 cToken) external requiresAuth {
        if (comptroller._unsupportMarket(cToken) != 0)
            revert ComptrollerError();
    }

    function _toggleAutoImplementations(bool enabled)
        public
        requiresAuth
    {
        if (comptroller._toggleAutoImplementations(enabled) != 0)
            revert ComptrollerError();
    }

    function scheduleSetPendingAdmin(address newPendingAdmin) public requiresAuth {
        _schedule(address(this), abi.encodeWithSelector(this._setPendingAdmin.selector, newPendingAdmin));
    }

    function _setPendingAdmin(address newPendingAdmin)
        public
    {
        require(msg.sender == address(timelock), "timelock");

        if (comptroller._setPendingAdmin(newPendingAdmin) != 0)
            revert ComptrollerError();
    }

    function _acceptAdmin() public {
        if (comptroller._acceptAdmin() != 0) revert ComptrollerError();
    }

    ///// Timelock helpers
    function schedule(address target, bytes memory data) public requiresAuth {
        _schedule(target, data);
    }

    function _schedule(address target, bytes memory data) internal {
        timelock.schedule(target, 0, data, bytes32(0), keccak256(abi.encodePacked(block.timestamp)), 15 days);
    }

    function cancel(bytes32 id) public requiresAuth {
        timelock.cancel(id);
    }

    function execute(address target, bytes memory data, bytes32 salt) public requiresAuth {
        timelock.execute(target, 0, data, bytes32(0), salt);
    }
}

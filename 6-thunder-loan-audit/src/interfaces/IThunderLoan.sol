// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

// @audit-info the IThunderLoan contract should be implemented by the ThunderLoan contract
interface IThunderLoan {
    // @audit-low/infoformational ?? should be fixed
    function repay(address token, uint256 amount) external;
}

// @audit-checked

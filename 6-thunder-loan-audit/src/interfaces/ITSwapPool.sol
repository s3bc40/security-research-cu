// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

// @audit-qanswered why are we only using the price of one pool token in WETH?
// we should not! it is a bug
interface ITSwapPool {
    function getPriceOfOnePoolTokenInWeth() external view returns (uint256);
}

// @audit-checked

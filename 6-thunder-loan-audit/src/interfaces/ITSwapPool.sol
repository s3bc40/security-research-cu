// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

// @audit-q why are we only using the price of one pool token in WETH?
interface ITSwapPool {
    function getPriceOfOnePoolTokenInWeth() external view returns (uint256);
}

// @audit-checked

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

// @audit-e This interface defines a function to get the pool address from TSwap
// @answered Why are we using TSwap? Relation wiht flash loans?
// being used to get the value of a token to calculate flash loan fees!
interface IPoolFactory {
    function getPool(address tokenAddress) external view returns (address);
}

// @audit-checked

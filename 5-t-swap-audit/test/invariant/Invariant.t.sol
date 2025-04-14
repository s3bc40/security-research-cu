// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {ERC20Mock} from "../mocks/ERC20Mock.sol";
import {PoolFactory} from "../../src/PoolFactory.sol";
import {TSwapPool} from "../../src/TSwapPool.sol";

int256 constant STARTING_X = 100e18; // Starting pool token balance
int256 constant STARTING_Y = 50e18; // Starting WETH balance

contract Invariant is StdInvariant, Test {
    // these pools have two assets
    ERC20Mock poolToken;
    ERC20Mock weth;

    // we need the contracts
    PoolFactory factory;
    TSwapPool pool; // poolToken / WETH

    // only one pool for the invariant test for now

    function setUp() public {
        weth = new ERC20Mock();
        poolToken = new ERC20Mock();
        factory = new PoolFactory(address(weth));
        pool = TSwapPool(factory.createPool(address(poolToken)));

        //create those initial x & y balances
        poolToken.mint(address(this), uint256(STARTING_X));
        weth.mint(address(this), uint256(STARTING_Y));

        poolToken.approve(address(pool), type(uint256).max);
        weth.approve(address(pool), type(uint256).max);

        // Deposit to the pools
        pool.deposit(
            uint256(STARTING_Y),
            uint256(STARTING_Y),
            uint256(STARTING_X),
            uint64(block.timestamp)
        );
    }

    function statefulFuzz_testConstantProductFormulasStaysTheSame() public {
        // the change in the pool size of WETH should follow
        // Handler better to use to avoid messing with the contracts!
    }
}

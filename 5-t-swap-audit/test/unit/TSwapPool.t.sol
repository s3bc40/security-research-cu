// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {TSwapPool} from "../../src/PoolFactory.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TSwapPoolTest is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(
            address(poolToken),
            address(weth),
            "LTokenA",
            "LA"
        );

        weth.mint(liquidityProvider, 200e18);
        poolToken.mint(liquidityProvider, 200e18);

        weth.mint(user, 10e18);
        poolToken.mint(user, 10e18);
    }

    function testDeposit() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.balanceOf(liquidityProvider), 100e18);
        assertEq(weth.balanceOf(liquidityProvider), 100e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 100e18);

        assertEq(weth.balanceOf(address(pool)), 100e18);
        assertEq(poolToken.balanceOf(address(pool)), 100e18);
    }

    function testDepositSwap() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        // After we swap, there will be ~110 tokenA, and ~91 WETH
        // 100 * 100 = 10,000
        // 110 * ~91 = 10,000
        uint256 expected = 9e18;

        pool.swapExactInput(
            poolToken,
            10e18,
            weth,
            expected,
            uint64(block.timestamp)
        );
        assert(weth.balanceOf(user) >= expected);
    }

    function testWithdraw() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.totalSupply(), 0);
        assertEq(weth.balanceOf(liquidityProvider), 200e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 200e18);
    }

    function testCollectFees() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        uint256 expected = 9e18;
        poolToken.approve(address(pool), 10e18);
        pool.swapExactInput(
            poolToken,
            10e18,
            weth,
            expected,
            uint64(block.timestamp)
        );
        vm.stopPrank();

        vm.startPrank(liquidityProvider);
        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 90e18, 100e18, uint64(block.timestamp));
        assertEq(pool.totalSupply(), 0);
        assert(
            weth.balanceOf(liquidityProvider) +
                poolToken.balanceOf(liquidityProvider) >
                400e18
        );
    }

    function testGetInputAmountBasedOnOutputMiscalculateFees(
        uint256 outputAmount
    ) public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        // Arrange
        uint256 inputReserves = poolToken.balanceOf(address(pool));
        uint256 outputReserves = weth.balanceOf(address(pool));
        // We are applying a 0.03% fee
        outputAmount = bound(outputAmount, 1e18, outputReserves);
        uint256 numerator = ((inputReserves * outputAmount) * 1_000);
        uint256 denominator = ((outputReserves - outputAmount) * 997);
        vm.assume(denominator > 0); // Avoid division by zero
        uint256 expectedInputAmount = (numerator / denominator);

        // Act
        uint256 inputAmount = pool.getInputAmountBasedOnOutput(
            outputAmount,
            inputReserves,
            outputReserves
        );

        // Assert
        assertGt(inputAmount, expectedInputAmount);
    }

    function testSwapExactInputAlwaysReturnZero(
        uint256 inputAmount,
        uint256 minOutputAmount
    ) public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        // Arrange
        // Bound max to the user balance for allowance
        inputAmount = bound(inputAmount, 1e18, poolToken.balanceOf(user));
        minOutputAmount = bound(minOutputAmount, 1e18, weth.balanceOf(user));
        // Check if we do not trigger TSwapPool__OutputTooLow error
        uint256 inputReserves = poolToken.balanceOf(address(pool));
        uint256 outputReserves = weth.balanceOf(address(pool));
        uint256 outputAmount = pool.getOutputAmountBasedOnInput(
            inputAmount,
            inputReserves,
            outputReserves
        );
        vm.assume(outputAmount > minOutputAmount); // Avoid triggering the revert

        // Act
        // Pranking user to swap exact input
        vm.startPrank(user);
        poolToken.approve(address(pool), 100e18);
        uint256 outputReturned = pool.swapExactInput(
            poolToken,
            inputAmount,
            weth,
            minOutputAmount,
            uint64(block.timestamp)
        );
        vm.stopPrank();

        // Assert
        assertEq(outputReturned, 0);
    }

    function testSellPoolTokensReturnsTheWrongAmount(
        uint256 poolTokensAmount
    ) public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        // Arrange
        uint256 maxUserPoolTokenToSwap = poolToken.balanceOf(user) - 1e18; // To handle the fees of 0.03%
        poolTokensAmount = bound(
            poolTokensAmount,
            1e18,
            maxUserPoolTokenToSwap
        );
        vm.startPrank(user); // Prank as user before approval
        poolToken.approve(address(pool), poolToken.balanceOf(user)); // Approve the pool to spend user's poolToken
        uint256 inputReserves = poolToken.balanceOf(address(pool));
        uint256 outputReserves = weth.balanceOf(address(pool));
        uint256 expectedOutputAmount = pool.getOutputAmountBasedOnInput(
            poolTokensAmount,
            inputReserves,
            outputReserves
        );

        // Act
        uint256 outputAmount = pool.auditFixedSellPoolTokens(poolTokensAmount);
        vm.stopPrank();

        // Assert
        assert(outputAmount != expectedOutputAmount);
    }

    function testInvariantBroken() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        // Arrange
        uint256 outputWeth = 1e17;
        int256 startingY = int256(weth.balanceOf(address(pool)));
        int256 expectedDeltaY = int256(-1) * int256(outputWeth);
        poolToken.mint(user, 1e18);

        // Act
        // Swap 10 times to trigger the invariant
        vm.startPrank(user);
        poolToken.approve(address(pool), type(uint256).max);
        for (uint i = 0; i < 10; i++) {
            pool.swapExactOutput(
                poolToken,
                weth,
                outputWeth,
                uint64(block.timestamp)
            );
        }
        vm.stopPrank();

        // Assert
        // Check if the invariant is broken
        uint256 endingY = weth.balanceOf(address(pool));
        int256 actualDeltaY = int256(endingY) - int256(startingY);
        assertEq(actualDeltaY, expectedDeltaY);
    }
}

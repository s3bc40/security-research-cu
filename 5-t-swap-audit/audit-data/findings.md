## Informational

### [I-1] `PoolFactory__PoolDoesNotExist` is not used and should be removed

```diff
- error PoolFactory__PoolDoesNotExist(address tokenAddress);
```

### [I-2] Lacking zero address checks

```diff
constructor(address wethToken) {
+   if (wethToken == address(0)) {
+       revert();
+   } 
    i_wethToken = wethToken;
}
```

### [I-3] `PoolFactory::createPool` should use `.symbol()` instead of `.name()`

```diff
string memory liquidityTokenSymbol = string.concat(
    "ts",
-    IERC20(tokenAddress).name()
+    IERC20(tokenAddress).symbol()
);
```

## Medium

### [M-1] `TSwapPoll::deposit` is missing deadline check causing transactions to complete even after the deadline

**Description:** The `deposit` function accepts a `deadline` parameter which according to the documentation "The deadline for the transaction to be completed by". However, the parameter is not used in the function. This means that the transaction can be completed even after the deadline has passed, which could lead to unexpected behavior.So a user can add liquidity to the pool might be executed at unexpected times, in market conditions that are not favorable to the user.

<!-- MEV attacks -->

**Impact:** Transactions could be sent when the market conditions are not favorable to the deposit, even if the `deadline` is set.

**Proof of Concept:** The `deadline` parameter is unused.

**Recommended Mitigation:** Consider making the following change to the function.

```diff
function deposit(
        uint256 wethToDeposit,
        uint256 minimumLiquidityTokensToMint,
        uint256 maximumPoolTokensToDeposit,
        // @audit-issue HIGH param is not used but potentially crucial
        // if someone sets a deadline next block, they could still deposit
        uint64 deadline
    )
        external
+       revertIfDeadlinePassed(deadline) 
        revertIfZero(wethToDeposit)
        returns (uint256 liquidityTokensToMint)
    {
```

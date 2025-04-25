# Solidity metrics

> To add in a notion or google sheet et order by nSLOC

| 🔍  	| 6-thunder-loan-audit/src/interfaces/ITSwapPool.sol                	|   	| 1 	| 6   	| 5   	| 3   	| 1   	| 3   	| 🔆  	|
|----	|-------------------------------------------------------------------	|---	|---	|-----	|-----	|-----	|-----	|-----	|----	|
| 🔍  	| 6-thunder-loan-audit/src/interfaces/IPoolFactory.sol              	|   	| 1 	| 6   	| 5   	| 3   	| 1   	| 3   	| 🔆  	|
| 🔍  	| 6-thunder-loan-audit/src/interfaces/IFlashLoanReceiver.sol        	|   	| 1 	| 20  	| 11  	| 4   	| 5   	| 3   	| 🔆  	|
| 🔍  	| 6-thunder-loan-audit/src/interfaces/IThunderLoan.sol              	|   	| 1 	| 6   	| 5   	| 3   	| 1   	| 3   	|    	|
| 📝  	| 6-thunder-loan-audit/src/upgradedProtocol/ThunderLoanUpgraded.sol 	| 1 	|   	| 288 	| 258 	| 143 	| 90  	| 127 	| 🌀  	|
| 📝  	| 6-thunder-loan-audit/src/protocol/AssetToken.sol                  	| 1 	|   	| 105 	| 105 	| 65  	| 24  	| 41  	|    	|
| 📝  	| 6-thunder-loan-audit/src/protocol/ThunderLoan.sol                 	| 1 	|   	| 351 	| 318 	| 193 	| 98  	| 129 	| 🌀  	|
| 📝  	| 6-thunder-loan-audit/src/protocol/OracleUpgradeable.sol           	| 1 	|   	| 36  	| 32  	| 23  	| 2   	| 18  	|    	|
| 📝🔍 	| Totals                                                            	| 4 	| 4 	| 818 	| 739 	| 437 	| 222 	| 327 	| 🌀🔆 	|

~350 nSLOC/Complexity

# Terms

Liquidity Provider: A user who deposits assets into the protocol to earn interest.
- Where the interest is coming from?
    - TSwap: Interest from the swap.
    - ThunderLoan: feeas from flashloans? 
    > deposit -> assets tokens -> interest


# About

Write the protocol in my own words

Diagrams here


# Potential attack vectors

## OracleUpgradeable.sol

### [getPriceInWeth(address token)](../src/protocol/OracleUpgradeable.sol#L33-L34)
external call to a contract -> attack vector
price may be manipulated?
reentrancy attack? -> Check the code even external
check tests? @audit-info you should use forked tests for this

# Ideas

// The underlying per asset exchange rate
// ie: s_exchangeRate = 2
// means 1 asset token is worth 2 underlying tokens
// @audit-note underlying == USDC
// @audit-note assetToken == shares
// % shares == compound finance
// underlyingAmount = cTokenAmount * exchangeRate / EXCHANGE_RATE_PRECISION
// EXAMPLE:
// Suppose you supply 1,000 USDC to the Compound protocol when the exchange rate is 0.020070.
// You would receive approximately 49,825.61 cUSDC (1,000 / 0.020070).
// Later, if the exchange rate increases to 0.021591 due to accrued interest,
// your 49,825.61 cUSDC would be redeemable for approximately 1,075 USDC (49,825.61 * 0.021591)

# Questions

- Why are we using TSwap? Relation wiht flash loans? 
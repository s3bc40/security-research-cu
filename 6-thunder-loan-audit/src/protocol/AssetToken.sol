// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AssetToken is ERC20 {
    error AssetToken__onlyThunderLoan();
    error AssetToken__ExhangeRateCanOnlyIncrease(
        uint256 oldExchangeRate,
        uint256 newExchangeRate
    );
    error AssetToken__ZeroAddress();

    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IERC20 private immutable i_underlying;
    address private immutable i_thunderLoan;

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
    uint256 private s_exchangeRate;
    uint256 public constant EXCHANGE_RATE_PRECISION = 1e18;
    uint256 private constant STARTING_EXCHANGE_RATE = 1e18;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event ExchangeRateUpdated(uint256 newExchangeRate);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyThunderLoan() {
        if (msg.sender != i_thunderLoan) {
            revert AssetToken__onlyThunderLoan();
        }
        _;
    }

    modifier revertIfZeroAddress(address someAddress) {
        if (someAddress == address(0)) {
            revert AssetToken__ZeroAddress();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    constructor(
        address thunderLoan,
        IERC20 underlying, // @audit-note underlying == USDC
        // @audit-question ERC20s stored in AssetToken.sol instead of ThunderLoan?
        string memory assetName,
        string memory assetSymbol
    )
        ERC20(assetName, assetSymbol)
        revertIfZeroAddress(thunderLoan)
        revertIfZeroAddress(address(underlying))
    {
        i_thunderLoan = thunderLoan;
        i_underlying = underlying;
        s_exchangeRate = STARTING_EXCHANGE_RATE;
    }

    // @audit-note only thunderloan can mint asset
    function mint(address to, uint256 amount) external onlyThunderLoan {
        _mint(to, amount);
    }

    function burn(address account, uint256 amount) external onlyThunderLoan {
        _burn(account, amount);
    }

    function transferUnderlyingTo(
        address to,
        uint256 amount
    ) external onlyThunderLoan {
        // @audit-question weird ERC20s , what happens if USDC blacklists the contract?
        // @audit-follow weird ERC20s to check
        i_underlying.safeTransfer(to, amount);
    }

    // @audit-note responsible for updating the exchange rate of AsseToken to the underlying
    function updateExchangeRate(uint256 fee) external onlyThunderLoan {
        // 1. Get the current exchange rate
        // 2. How big the fee is should be divided by the total supply
        // 3. So if the fee is 1e18, and the total supply is 2e18, the exchange rate be multiplied by 1.5
        // if the fee is 0.5 ETH, and the total supply is 4, the exchange rate should be multiplied by 1.125
        // it should always go up, never down -> @audit-note INVARIANT
        // @audit-question why should always go up?
        // newExchangeRate = oldExchangeRate * (totalSupply + fee) / totalSupply
        // newExchangeRate = 1 (4 + 0.5) / 4
        // newExchangeRate = 1.125

        // @audit-question what if totalSupply is 0? -> could break
        // @audit-follow try breaking it with 0 totalSupply
        // @audit-gas too many storage reads -> memory var
        uint256 newExchangeRate = (s_exchangeRate * (totalSupply() + fee)) /
            totalSupply();

        if (newExchangeRate <= s_exchangeRate) {
            revert AssetToken__ExhangeRateCanOnlyIncrease(
                s_exchangeRate,
                newExchangeRate
            );
        }
        s_exchangeRate = newExchangeRate;
        emit ExchangeRateUpdated(s_exchangeRate);
    }

    function getExchangeRate() external view returns (uint256) {
        return s_exchangeRate;
    }

    function getUnderlying() external view returns (IERC20) {
        return i_underlying;
    }
}

// @audit-checked

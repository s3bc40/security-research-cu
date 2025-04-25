// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.20;

// @audit-info unused import
// bad pratice to edit live code for test
// should be removed from mock MockFlashLoanReceiver
import {IThunderLoan} from "./IThunderLoan.sol";

/**
 * @dev Inspired by Aave:
 * https://github.com/aave/aave-v3-core/blob/master/contracts/flashloan/interfaces/IFlashLoanReceiver.sol
 */
interface IFlashLoanReceiver {
    // @audit-question is the token, the token that is being borrowed?
    // natspec?
    // @audit-question the amount is the amount of tokens?
    // @audit-question is the fee, the fee that is being paid for the loan?
    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata params
    ) external returns (bool);
}

// @audit-checked

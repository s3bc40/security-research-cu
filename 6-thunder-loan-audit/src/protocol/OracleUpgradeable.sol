// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.20;

import {ITSwapPool} from "../interfaces/ITSwapPool.sol";
import {IPoolFactory} from "../interfaces/IPoolFactory.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract OracleUpgradeable is Initializable {
    address private s_poolFactory;

    // can not have constructor
    // storage is in the proxy
    // logic is in the implementation

    function __Oracle_init(
        address poolFactoryAddress
    ) internal onlyInitializing {
        __Oracle_init_unchained(poolFactoryAddress);
    }

    // @audit-info Check for address(0)
    function __Oracle_init_unchained(
        address poolFactoryAddress
    ) internal onlyInitializing {
        // @audit-info Check for address(0)
        s_poolFactory = poolFactoryAddress;
    }

    // @audit-note external call to a contract -> attack vector
    // price may be manipulated?
    // reentrancy attack? -> Check the code even external
    // check tests? @audit-info you should use forked tests for this
    function getPriceInWeth(address token) public view returns (uint256) {
        address swapPoolOfToken = IPoolFactory(s_poolFactory).getPool(token);
        return ITSwapPool(swapPoolOfToken).getPriceOfOnePoolTokenInWeth();
    }

    // @audit-note redundant function
    function getPrice(address token) external view returns (uint256) {
        return getPriceInWeth(token);
    }

    function getPoolFactoryAddress() external view returns (address) {
        return s_poolFactory;
    }
}

// @audit-checked

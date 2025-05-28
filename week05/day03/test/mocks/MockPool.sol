// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../../src/interfaces/IPool.sol";
import "./MockAToken.sol";

contract MockPool is IPool {
    address public immutable aToken;

    constructor(address _aToken) {
        aToken = _aToken;
    }

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external payable {
        MockAToken(aToken).mint(onBehalfOf, amount);
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        MockAToken(aToken).burn(msg.sender, amount);
        payable(to).transfer(amount);
        return amount;
    }

    receive() external payable {}
} 
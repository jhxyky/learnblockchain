// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../src/interfaces/IAToken.sol";

contract MockAToken is ERC20, IAToken {
    constructor() ERC20("Mock Aave Token", "aETH") {}

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function balanceOf(address user) public view override(ERC20, IAToken) returns (uint256) {
        return super.balanceOf(user);
    }
} 
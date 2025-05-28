// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC20/IERC20.sol";

interface IAToken is IERC20 {
    function balanceOf(address user) external view returns (uint256);
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external payable;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
} 
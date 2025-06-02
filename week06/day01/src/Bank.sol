// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Bank is Ownable {
    // 记录存款事件
    event Deposit(address indexed sender, uint256 amount);
    // 记录提款事件
    event Withdrawal(address indexed recipient, uint256 amount);

    constructor() Ownable(msg.sender) {}

    // 接收ETH存款
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // 管理员提取资金
    function withdraw(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        emit Withdrawal(recipient, amount);
    }

    // 查看合约余额
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
} 
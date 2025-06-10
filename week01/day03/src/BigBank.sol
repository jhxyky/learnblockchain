// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Bank.sol";

contract BigBank is Bank {
    // 最小存款金额
    uint256 public constant MIN_DEPOSIT = 0.001 ether;

    // 检查最小存款金额
    modifier minDeposit() {
        require(msg.value >= MIN_DEPOSIT, "Deposit amount must be greater than 0.001 ether");
        _;
    }

    // 重写存款函数，添加最小存款限制
    function deposit() public payable override minDeposit {
        super.deposit();
    }

    // 转移管理员权限
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }
} 
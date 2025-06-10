// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IBank.sol";

contract Admin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 从Bank合约提取资金到Admin合约
    function adminWithdraw(IBank bank) external onlyOwner {
        uint256 bankBalance = bank.getContractBalance();
        require(bankBalance > 0, "Bank has no balance");
        bank.withdraw(bankBalance);
    }

    // 接收ETH的回退函数
    receive() external payable {}
} 
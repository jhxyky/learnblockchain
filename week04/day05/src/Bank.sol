// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Bank is AutomationCompatibleInterface, Ownable {
    uint256 public constant THRESHOLD = 1 ether; // 设置阈值为1 ETH
    
    event Deposit(address indexed sender, uint256 amount);
    event AutoTransfer(uint256 amount, address indexed to);

    // 存款功能
    function deposit() external payable {
        require(msg.value > 0, "Must deposit some ETH");
        emit Deposit(msg.sender, msg.value);
    }

    // Chainlink Automation 检查函数
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = address(this).balance >= THRESHOLD;
    }

    // Chainlink Automation 执行函数
    function performUpkeep(bytes calldata /* performData */) external override {
        uint256 balance = address(this).balance;
        require(balance >= THRESHOLD, "Balance below threshold");
        
        uint256 transferAmount = balance / 2;
        (bool success, ) = owner().call{value: transferAmount}("");
        require(success, "Transfer failed");
        
        emit AutoTransfer(transferAmount, owner());
    }

    // 查询合约余额
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 接收ETH
    receive() external payable {}
    fallback() external payable {}
} 
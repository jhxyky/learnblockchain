// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        
        vm.prank(owner);
        bank = new Bank();
        
        // 给测试账户一些 ETH
        vm.deal(user1, 2 ether);
        vm.deal(user2, 2 ether);
    }

    function test_Deposit() public {
        vm.prank(user1);
        bank.deposit{value: 0.5 ether}();
        
        assertEq(bank.totalDeposits(), 0.5 ether);
        assertEq(bank.getBalance(), 0.5 ether);
    }

    function test_AutomationTrigger() public {
        // 存入低于阈值的金额
        vm.prank(user1);
        bank.deposit{value: 0.5 ether}();
        
        (bool needsUpkeep,) = bank.checkUpkeep("");
        assertFalse(needsUpkeep, "Should not need upkeep below threshold");

        // 存入超过阈值的金额
        vm.prank(user2);
        bank.deposit{value: 0.6 ether}();
        
        (needsUpkeep,) = bank.checkUpkeep("");
        assertTrue(needsUpkeep, "Should need upkeep above threshold");
    }

    function test_PerformUpkeep() public {
        // 存入超过阈值的金额
        vm.prank(user1);
        bank.deposit{value: 1.5 ether}();
        
        uint256 initialOwnerBalance = owner.balance;
        
        // 执行自动化任务
        bank.performUpkeep("");
        
        // 验证一半的资金已转移到所有者账户
        assertEq(bank.totalDeposits(), 0.75 ether);
        assertEq(bank.getBalance(), 0.75 ether);
        assertEq(owner.balance, initialOwnerBalance + 0.75 ether);
    }
} 
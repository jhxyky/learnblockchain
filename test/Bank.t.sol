// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    function setUp() public {
        // 部署合约
        bank = new Bank();
        owner = address(this);
        
        // 创建测试账户
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        
        // 给测试账户一些ETH
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
        vm.deal(charlie, 10 ether);
    }

    function testDeposit() public {
        // 测试存款
        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        assertEq(bank.getBalance(alice), 1 ether);
        
        vm.prank(bob);
        bank.deposit{value: 2 ether}();
        assertEq(bank.getBalance(bob), 2 ether);
        
        vm.prank(charlie);
        bank.deposit{value: 3 ether}();
        assertEq(bank.getBalance(charlie), 3 ether);
    }

    function testTopDepositors() public {
        // 测试排名功能
        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        
        vm.prank(bob);
        bank.deposit{value: 2 ether}();
        
        vm.prank(charlie);
        bank.deposit{value: 3 ether}();

        Bank.Depositor[3] memory topDepositors = bank.getTopDepositors();
        
        // 验证第一名
        assertEq(topDepositors[0].addr, charlie);
        assertEq(topDepositors[0].amount, 3 ether);
        
        // 验证第二名
        assertEq(topDepositors[1].addr, bob);
        assertEq(topDepositors[1].amount, 2 ether);
        
        // 验证第三名
        assertEq(topDepositors[2].addr, alice);
        assertEq(topDepositors[2].amount, 1 ether);
    }

    function testWithdraw() public {
        // 测试提款功能
        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        
        uint256 initialBalance = address(owner).balance;
        bank.withdraw(2 ether);
        assertEq(address(owner).balance, initialBalance + 2 ether);
        assertEq(bank.getContractBalance(), 3 ether);
    }

    function testFailWithdrawNotOwner() public {
        // 测试非管理员提款失败
        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        
        vm.prank(alice);
        bank.withdraw(2 ether); // 应该失败
    }

    function testDirectDeposit() public {
        // 测试直接转账
        vm.prank(alice);
        (bool success,) = address(bank).call{value: 1 ether}("");
        require(success, "Direct deposit failed");
        assertEq(bank.getBalance(alice), 1 ether);
    }
} 
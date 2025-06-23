// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Token.sol";
import "../src/TokenBank.sol";

contract TokenBankTest is Test {
    Token public token;
    TokenBank public bank;
    
    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);
    
    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;
    
    function setUp() public {
        vm.startPrank(owner);
        
        // 部署代币合约
        token = new Token("Test Token", "TT");
        
        // 部署银行合约
        bank = new TokenBank(address(token));
        
        // 转移一些代币给测试用户
        token.transfer(user1, 10000 * 10**18);
        token.transfer(user2, 5000 * 10**18);
        
        vm.stopPrank();
    }
    
    function testDeposit() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = 1000 * 10**18;
        
        // 授权银行合约
        token.approve(address(bank), depositAmount);
        
        // 存款前余额
        uint256 balanceBefore = token.balanceOf(user1);
        
        // 执行存款
        bool success = bank.deposit(depositAmount);
        assertTrue(success, "Deposit should succeed");
        
        // 验证存款后余额
        assertEq(token.balanceOf(user1), balanceBefore - depositAmount, "User token balance should decrease");
        assertEq(bank.balances(user1), depositAmount, "Bank should record deposit");
        
        vm.stopPrank();
    }
    
    function testWithdraw() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = 1000 * 10**18;
        uint256 withdrawAmount = 600 * 10**18;
        
        // 先存款
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        
        // 取款前余额
        uint256 balanceBefore = token.balanceOf(user1);
        
        // 执行取款
        bool success = bank.withdraw(withdrawAmount);
        assertTrue(success, "Withdraw should succeed");
        
        // 验证取款后余额
        assertEq(token.balanceOf(user1), balanceBefore + withdrawAmount, "User token balance should increase");
        assertEq(bank.balances(user1), depositAmount - withdrawAmount, "Bank should update balance");
        
        vm.stopPrank();
    }
    
    function testFailWithdrawInsufficientBalance() public {
        vm.startPrank(user1);
        
        uint256 depositAmount = 1000 * 10**18;
        
        // 先存款
        token.approve(address(bank), depositAmount);
        bank.deposit(depositAmount);
        
        // 尝试取出超过存款的金额
        bank.withdraw(depositAmount + 1);
        
        vm.stopPrank();
    }
    
    function testMultipleUsers() public {
        // 用户1存款
        vm.startPrank(user1);
        token.approve(address(bank), 2000 * 10**18);
        bank.deposit(2000 * 10**18);
        vm.stopPrank();
        
        // 用户2存款
        vm.startPrank(user2);
        token.approve(address(bank), 1000 * 10**18);
        bank.deposit(1000 * 10**18);
        vm.stopPrank();
        
        // 验证两个用户的余额
        assertEq(bank.balances(user1), 2000 * 10**18, "User1 balance should be correct");
        assertEq(bank.balances(user2), 1000 * 10**18, "User2 balance should be correct");
        
        // 用户1取款
        vm.prank(user1);
        bank.withdraw(500 * 10**18);
        
        // 用户2取款
        vm.prank(user2);
        bank.withdraw(300 * 10**18);
        
        // 再次验证余额
        assertEq(bank.balances(user1), 1500 * 10**18, "User1 balance should be updated");
        assertEq(bank.balances(user2), 700 * 10**18, "User2 balance should be updated");
    }
} 
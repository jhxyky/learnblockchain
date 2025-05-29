// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "../src/DeflationaryToken.sol";

contract DeflationaryTokenTest is Test {
    DeflationaryToken public token;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        token = new DeflationaryToken();
    }

    function test_InitialState() public {
        assertEq(token.name(), "Deflationary Token");
        assertEq(token.symbol(), "DFT");
        assertEq(token.totalSupply(), 100_000_000 * 1e18);
        assertEq(token.balanceOf(owner), 100_000_000 * 1e18);
    }

    function test_Transfer() public {
        uint256 amount = 1000 * 1e18;
        token.transfer(user1, amount);
        assertEq(token.balanceOf(user1), amount);
    }

    function test_Rebase() public {
        // 转移一些代币给用户
        uint256 amount = 1000 * 1e18;
        token.transfer(user1, amount);
        
        // 确认初始余额
        assertEq(token.balanceOf(user1), amount);
        
        // 快进一年
        vm.warp(block.timestamp + 365 days);
        
        // 执行 rebase
        token.rebase();
        
        // 检查通缩后的余额（应该是原来的99%）
        uint256 expectedBalance = amount * 99 / 100;
        assertEq(token.balanceOf(user1), expectedBalance);
        
        // 检查总供应量也应该减少了1%
        uint256 expectedTotalSupply = (100_000_000 * 1e18) * 99 / 100;
        assertEq(token.totalSupply(), expectedTotalSupply);
    }

    function test_MultipleRebase() public {
        uint256 amount = 1000 * 1e18;
        token.transfer(user1, amount);
        
        // 第一年 rebase
        vm.warp(block.timestamp + 365 days);
        token.rebase();
        uint256 balance1 = token.balanceOf(user1);
        assertEq(balance1, amount * 99 / 100);
        
        // 第二年 rebase
        vm.warp(block.timestamp + 365 days);
        token.rebase();
        uint256 balance2 = token.balanceOf(user1);
        assertEq(balance2, balance1 * 99 / 100);
    }

    function test_RebaseTooEarly() public {
        vm.warp(block.timestamp + 364 days);
        vm.expectRevert("Too early for rebase");
        token.rebase();
    }

    function test_RawBalance() public {
        uint256 amount = 1000 * 1e18;
        token.transfer(user1, amount);
        
        // rebase 前后原始余额应该保持不变
        assertEq(token.rawBalanceOf(user1), amount);
        
        vm.warp(block.timestamp + 365 days);
        token.rebase();
        
        assertEq(token.rawBalanceOf(user1), amount);
    }
} 
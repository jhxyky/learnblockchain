// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenVesting.sol";
import "../src/TestToken.sol";

contract TokenVestingTest is Test {
    TokenVesting public vesting;
    TestToken public token;
    address public beneficiary;
    uint256 public constant TOTAL_AMOUNT = 1_000_000 * 1e18; // 100万代币
    
    function setUp() public {
        // 设置受益人地址
        beneficiary = makeAddr("beneficiary");
        
        // 部署测试代币
        token = new TestToken();
        
        // 部署Vesting合约
        vesting = new TokenVesting(beneficiary, address(token), TOTAL_AMOUNT);
        
        // 转移代币到Vesting合约
        token.transfer(address(vesting), TOTAL_AMOUNT);
    }

    function testInitialState() public {
        assertEq(vesting.beneficiary(), beneficiary);
        assertEq(address(vesting.token()), address(token));
        assertEq(vesting.totalAmount(), TOTAL_AMOUNT);
        assertEq(token.balanceOf(address(vesting)), TOTAL_AMOUNT);
    }

    function testNoReleaseBeforeCliff() public {
        // 11个月后
        vm.warp(block.timestamp + 330 days);
        
        assertEq(vesting.vestedAmount(), 0);
        assertEq(vesting.releasable(), 0);
        
        vm.expectRevert("TokenVesting: no tokens are due");
        vesting.release();
    }

    function testReleaseAfterCliff() public {
        // 13个月后（1个月的线性释放期）
        vm.warp(block.timestamp + 395 days);
        
        uint256 expectedAmount = TOTAL_AMOUNT / 24; // 第一个月的释放量
        
        assertEq(vesting.vestedAmount(), expectedAmount);
        assertEq(vesting.releasable(), expectedAmount);
        
        vm.prank(beneficiary);
        vesting.release();
        
        assertEq(token.balanceOf(beneficiary), expectedAmount);
        assertEq(vesting.released(), expectedAmount);
    }

    function testFullVestingSchedule() public {
        // 测试整个归属计划
        uint256 monthlyAmount = TOTAL_AMOUNT / 24;
        
        // 先到cliff
        vm.warp(vesting.cliff());
        
        // 测试24个月的释放
        for (uint256 i = 0; i < 24; i++) {
            // 移动到下一个月
            vm.warp(vesting.cliff() + (i + 1) * 30 days);
            
            if (vesting.releasable() > 0) {
                vm.prank(beneficiary);
                vesting.release();
            }
        }

        // 最后确保所有代币都已释放
        vm.warp(vesting.end());
        if (vesting.releasable() > 0) {
            vm.prank(beneficiary);
            vesting.release();
        }
        
        assertEq(vesting.released(), TOTAL_AMOUNT, "Total released amount should match total amount");
        assertEq(token.balanceOf(beneficiary), TOTAL_AMOUNT, "Beneficiary should receive all tokens");
        assertEq(token.balanceOf(address(vesting)), 0, "Vesting contract should have no tokens left");
    }

    function testAfterVestingEnd() public {
        // 37个月后（完全归属后）
        vm.warp(block.timestamp + 1095 days);
        
        assertEq(vesting.vestedAmount(), TOTAL_AMOUNT);
        assertEq(vesting.releasable(), TOTAL_AMOUNT);
        
        vm.prank(beneficiary);
        vesting.release();
        
        assertEq(token.balanceOf(beneficiary), TOTAL_AMOUNT);
        assertEq(vesting.released(), TOTAL_AMOUNT);
    }
} 
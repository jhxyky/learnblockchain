// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "../src/StakingPool.sol";
import "../src/KKToken.sol";
import "./mocks/MockPool.sol";
import "./mocks/MockAToken.sol";

contract StakingPoolTest is Test {
    StakingPool public stakingPool;
    KKToken public kkToken;
    MockPool public mockPool;
    MockAToken public mockAToken;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);
        
        // 部署合约
        kkToken = new KKToken();
        mockAToken = new MockAToken();
        mockPool = new MockPool(address(mockAToken));
        stakingPool = new StakingPool(
            address(kkToken),
            address(mockPool),
            address(mockAToken)
        );

        // 设置权限
        kkToken.transferOwnership(address(stakingPool));

        // 给测试用户一些 ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function test_Stake() public {
        uint256 stakeAmount = 1 ether;
        
        vm.startPrank(user1);
        stakingPool.stake{value: stakeAmount}();
        vm.stopPrank();

        assertEq(stakingPool.balanceOf(user1), stakeAmount);
        assertEq(address(mockPool).balance, stakeAmount);
    }

    function test_Unstake() public {
        uint256 stakeAmount = 1 ether;
        
        // 先质押
        vm.startPrank(user1);
        stakingPool.stake{value: stakeAmount}();
        
        // 等待一些区块
        vm.roll(block.number + 10);
        
        // 赎回一半
        uint256 unstakeAmount = stakeAmount / 2;
        stakingPool.unstake(unstakeAmount);
        vm.stopPrank();

        assertEq(stakingPool.balanceOf(user1), stakeAmount - unstakeAmount);
    }

    function test_Rewards() public {
        uint256 stakeAmount = 1 ether;
        
        // user1 质押
        vm.startPrank(user1);
        stakingPool.stake{value: stakeAmount}();
        vm.stopPrank();

        // 前进 10 个区块
        vm.roll(block.number + 10);
        
        // 检查奖励
        uint256 expectedReward = 10 * 10 ether; // 10个区块 * 每区块10代币
        assertEq(stakingPool.earned(user1), expectedReward);

        // 领取奖励
        vm.prank(user1);
        stakingPool.claim();
        
        assertEq(kkToken.balanceOf(user1), expectedReward);
    }

    function test_MultipleStakers() public {
        // user1 质押 1 ETH
        vm.prank(user1);
        stakingPool.stake{value: 1 ether}();

        // 前进 5 个区块
        vm.roll(block.number + 5);

        // user2 质押 3 ETH
        vm.prank(user2);
        stakingPool.stake{value: 3 ether}();

        // 再前进 5 个区块
        vm.roll(block.number + 5);

        // 检查奖励
        // user1: 前5个区块独享50个代币，后5个区块分享25%，得12.5个代币
        assertApproxEqAbs(stakingPool.earned(user1), 62.5 ether, 0.1 ether);
        
        // user2: 后5个区块分享75%，得37.5个代币
        assertApproxEqAbs(stakingPool.earned(user2), 37.5 ether, 0.1 ether);
    }
} 
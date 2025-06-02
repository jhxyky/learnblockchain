// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import "../src/CallOptionToken.sol";
import "./mocks/MockUSDT.sol";

contract CallOptionTokenTest is Test {
    CallOptionToken public optionToken;
    MockUSDT public usdt;
    
    address public owner;
    address public user1;
    address public user2;

    uint256 public constant STRIKE_PRICE = 2000 * 10**18;  // 2000 USDT per ETH
    uint256 public constant EXPIRATION_DAYS = 30;

    function setUp() public {
        owner = address(this);
        user1 = address(0x1);
        user2 = address(0x2);

        // 部署 USDT 和期权合约
        usdt = new MockUSDT();
        optionToken = new CallOptionToken(
            STRIKE_PRICE,
            EXPIRATION_DAYS,
            address(usdt)
        );

        // 给测试用户一些 ETH 和 USDT
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        usdt.mint(user1, 1000000 * 10**18);
        usdt.mint(user2, 1000000 * 10**18);
    }

    function test_InitialState() public {
        assertEq(optionToken.name(), "ETH Call Option");
        assertEq(optionToken.symbol(), "ETHCALL");
        assertEq(optionToken.strikePrice(), STRIKE_PRICE);
        assertEq(address(optionToken.USDT()), address(usdt));
    }

    function test_IssueOptions() public {
        uint256 issueAmount = 1 ether;
        
        vm.startPrank(user1);
        optionToken.issueOptions{value: issueAmount}();
        vm.stopPrank();

        assertEq(optionToken.balanceOf(user1), issueAmount);
        assertEq(address(optionToken).balance, issueAmount);
    }

    function test_Exercise() public {
        // 先发行期权
        uint256 issueAmount = 1 ether;
        vm.prank(user1);
        optionToken.issueOptions{value: issueAmount}();

        // 转移期权给 user2
        vm.prank(user1);
        optionToken.transfer(user2, issueAmount);

        // user2 授权 USDT
        vm.startPrank(user2);
        usdt.approve(address(optionToken), type(uint256).max);

        // 行权
        uint256 exerciseAmount = 0.5 ether;
        uint256 usdtRequired = optionToken.getExerciseUSDTAmount(exerciseAmount);
        
        uint256 user2UsdtBefore = usdt.balanceOf(user2);
        uint256 user2EthBefore = user2.balance;
        
        optionToken.exercise(exerciseAmount);
        vm.stopPrank();

        // 验证结果
        assertEq(optionToken.balanceOf(user2), issueAmount - exerciseAmount);
        assertEq(usdt.balanceOf(user2), user2UsdtBefore - usdtRequired);
        assertEq(user2.balance, user2EthBefore + exerciseAmount);
    }

    function test_Expire() public {
        // 发行期权
        uint256 issueAmount = 1 ether;
        vm.deal(user1, issueAmount);  // 确保 user1 有足够的 ETH
        vm.prank(user1);
        optionToken.issueOptions{value: issueAmount}();

        // 快进到过期时间
        vm.warp(block.timestamp + (EXPIRATION_DAYS + 1) * 1 days);

        // 确认已过期
        assertTrue(optionToken.isExpired());

        // 执行过期销毁
        uint256 ownerEthBefore = owner.balance;
        optionToken.expire();

        // 验证结果
        assertEq(owner.balance, ownerEthBefore + issueAmount);
    }

    function test_RevertWhen_ExerciseAfterExpiration() public {
        // 发行期权
        uint256 issueAmount = 1 ether;
        vm.prank(user1);
        optionToken.issueOptions{value: issueAmount}();

        // 快进到过期时间
        vm.warp(block.timestamp + (EXPIRATION_DAYS + 1) * 1 days);

        // 尝试行权（应该失败）
        vm.prank(user1);
        vm.expectRevert("Option expired");
        optionToken.exercise(issueAmount);
    }

    function test_RevertWhen_IssueAfterExpiration() public {
        // 快进到过期时间
        vm.warp(block.timestamp + (EXPIRATION_DAYS + 1) * 1 days);

        // 尝试发行（应该失败）
        vm.prank(user1);
        vm.expectRevert("Option expired");
        optionToken.issueOptions{value: 1 ether}();
    }

    function test_ExercisePartial() public {
        // 发行期权
        uint256 issueAmount = 2 ether;
        vm.prank(user1);
        optionToken.issueOptions{value: issueAmount}();

        // 授权 USDT
        vm.prank(user1);
        usdt.approve(address(optionToken), type(uint256).max);

        // 分两次行权
        vm.startPrank(user1);
        optionToken.exercise(1 ether);
        optionToken.exercise(0.5 ether);
        vm.stopPrank();

        assertEq(optionToken.balanceOf(user1), 0.5 ether);
    }

    receive() external payable {}
} 
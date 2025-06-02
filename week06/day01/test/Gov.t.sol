// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {Gov} from "../src/Gov.sol";
import {VoteToken} from "../src/VoteToken.sol";
import {Bank} from "../src/Bank.sol";

contract GovTest is Test {
    Gov public gov;
    VoteToken public token;
    Bank public bank;
    
    address public admin = makeAddr("admin");
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    
    function setUp() public {
        vm.startPrank(admin);
        
        // 部署投票代币
        token = new VoteToken();
        
        // 部署Bank合约
        bank = new Bank();
        
        // 部署治理合约
        gov = new Gov(address(token), payable(address(bank)));
        
        // 将Bank合约的所有权转移给Gov合约
        bank.transferOwnership(address(gov));
        
        // 给Bank合约转入一些ETH
        vm.deal(address(bank), 100 ether);
        
        // 给测试用户一些代币
        token.mint(alice, 200 ether); // 200个代币
        token.mint(bob, 150 ether);   // 150个代币
        
        vm.stopPrank();
    }

    function test_ProposalCreation() public {
        // 让Alice创建提案
        vm.startPrank(alice);
        
        // 首先需要delegate投票权
        token.delegate(alice);
        
        // 创建提案：提取1 ETH到alice地址
        uint256 proposalId = gov.propose(payable(alice), 1 ether);
        
        // 验证提案创建成功
        (
            uint256 id,
            address proposer,
            address payable recipient,
            uint256 amount,
            ,
            ,
            uint256 forVotes,
            uint256 againstVotes,
            bool executed
        ) = gov.proposals(proposalId);
        
        assertEq(id, 1, "Proposal ID should be 1");
        assertEq(proposer, alice, "Proposer should be alice");
        assertEq(recipient, alice, "Recipient should be alice");
        assertEq(amount, 1 ether, "Amount should be 1 ether");
        assertEq(forVotes, 0, "Initial forVotes should be 0");
        assertEq(againstVotes, 0, "Initial againstVotes should be 0");
        assertEq(executed, false, "Proposal should not be executed");
        
        vm.stopPrank();
    }

    function test_Voting() public {
        // 设置场景
        vm.startPrank(alice);
        token.delegate(alice);
        uint256 proposalId = gov.propose(payable(alice), 1 ether);
        vm.stopPrank();

        // Bob投赞成票
        vm.startPrank(bob);
        token.delegate(bob);
        gov.castVote(proposalId, true);
        vm.stopPrank();

        // 验证投票结果
        (,,,,,,uint256 forVotes, uint256 againstVotes,) = gov.proposals(proposalId);
        assertEq(forVotes, 150 ether, "For votes should be 150 tokens");
        assertEq(againstVotes, 0, "Against votes should be 0");
    }

    function test_ProposalExecution() public {
        // 设置场景
        vm.startPrank(alice);
        token.delegate(alice);
        uint256 proposalId = gov.propose(payable(alice), 1 ether);
        vm.stopPrank();

        // Bob投赞成票
        vm.startPrank(bob);
        token.delegate(bob);
        gov.castVote(proposalId, true);
        vm.stopPrank();

        // 等待投票期结束
        vm.warp(block.timestamp + 3 days + 1);

        // 执行提案
        uint256 balanceBefore = alice.balance;
        gov.executeProposal(proposalId);
        uint256 balanceAfter = alice.balance;

        assertEq(balanceAfter - balanceBefore, 1 ether, "Proposal execution should transfer 1 ether");
    }

    function test_RevertWhen_InsufficientVotingPower() public {
        // Bob尝试创建提案（没有足够的投票权）
        vm.startPrank(bob);
        vm.expectRevert("Insufficient voting power");
        gov.propose(payable(bob), 1 ether);
        vm.stopPrank();
    }

    function test_RevertWhen_DoubleVoting() public {
        // 设置场景
        vm.startPrank(alice);
        token.delegate(alice);
        uint256 proposalId = gov.propose(payable(alice), 1 ether);
        vm.stopPrank();

        // Bob尝试投票两次
        vm.startPrank(bob);
        token.delegate(bob);
        gov.castVote(proposalId, true);
        vm.expectRevert("Already voted");
        gov.castVote(proposalId, true);
        vm.stopPrank();
    }
} 
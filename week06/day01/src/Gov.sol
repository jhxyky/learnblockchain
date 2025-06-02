// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VoteToken.sol";
import "./Bank.sol";

contract Gov {
    // 提案状态
    enum ProposalState { Pending, Active, Succeeded, Defeated, Executed }
    
    // 提案结构
    struct Proposal {
        uint256 id;              // 提案ID
        address proposer;        // 提案人
        address payable recipient;// 提款接收地址
        uint256 amount;         // 提款金额
        uint256 startTime;      // 开始时间
        uint256 endTime;        // 结束时间
        uint256 forVotes;       // 赞成票
        uint256 againstVotes;   // 反对票
        bool executed;          // 是否已执行
        mapping(address => bool) hasVoted; // 投票记录
    }

    // 投票代币合约
    VoteToken public token;
    // Bank合约
    Bank public bank;
    // 提案映射
    mapping(uint256 => Proposal) public proposals;
    // 提案计数器
    uint256 public proposalCount;
    // 投票期限（3天）
    uint256 public constant VOTING_PERIOD = 3 days;
    // 提案阈值（100代币）
    uint256 public constant PROPOSAL_THRESHOLD = 100 * 10**18;

    // 事件
    event ProposalCreated(uint256 proposalId, address proposer, address recipient, uint256 amount);
    event Voted(uint256 proposalId, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 proposalId);

    constructor(address _token, address payable _bank) {
        token = VoteToken(_token);
        bank = Bank(_bank);
    }

    // 创建提案
    function propose(address payable recipient, uint256 amount) external returns (uint256) {
        uint256 votes = token.getVotes(msg.sender);
        require(votes >= PROPOSAL_THRESHOLD, "Insufficient voting power");

        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.id = proposalCount;
        proposal.proposer = msg.sender;
        proposal.recipient = recipient;
        proposal.amount = amount;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + VOTING_PERIOD;

        emit ProposalCreated(proposalCount, msg.sender, recipient, amount);
        return proposalCount;
    }

    // 投票
    function castVote(uint256 proposalId, bool support) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.endTime, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 votes = token.getVotes(msg.sender);
        require(votes > 0, "No voting power");

        proposal.hasVoted[msg.sender] = true;
        
        if (support) {
            proposal.forVotes += votes;
        } else {
            proposal.againstVotes += votes;
        }

        emit Voted(proposalId, msg.sender, support, votes);
    }

    // 执行提案
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp > proposal.endTime, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        require(proposal.forVotes > proposal.againstVotes, "Proposal not passed");

        proposal.executed = true;
        
        // 执行Bank合约的withdraw函数
        bank.withdraw(proposal.recipient, proposal.amount);
        
        emit ProposalExecuted(proposalId);
    }

    // 获取提案状态
    function getProposalState(uint256 proposalId) public view returns (ProposalState) {
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        
        if (block.timestamp <= proposal.endTime) {
            return ProposalState.Active;
        }
        
        if (proposal.forVotes > proposal.againstVotes) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }
} 
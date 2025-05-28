// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/security/ReentrancyGuard.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IToken.sol";
import "./interfaces/IAToken.sol";
import "./interfaces/IPool.sol";

contract StakingPool is IStaking, ReentrancyGuard {
    // 用户质押信息
    struct UserInfo {
        uint256 amount;          // 质押数量
        uint256 rewardDebt;      // 已结算的奖励
        uint256 lastStakeTime;   // 最后质押时间
    }

    // 状态变量
    IToken public immutable kkToken;              // KK Token 合约
    IPool public immutable lendingPool;           // Aave lending pool
    IAToken public immutable aToken;              // Aave aToken
    uint256 public constant REWARD_PER_BLOCK = 10 ether;  // 每区块产出10个代币
    uint256 public lastRewardBlock;               // 最后更新奖励的区块
    uint256 public accRewardPerShare;             // 每份额累计奖励
    uint256 public totalStaked;                   // 总质押量

    // 用户信息映射
    mapping(address => UserInfo) public userInfo;

    constructor(
        address _kkToken,
        address _lendingPool,
        address _aToken
    ) {
        kkToken = IToken(_kkToken);
        lendingPool = IPool(_lendingPool);
        aToken = IAToken(_aToken);
        lastRewardBlock = block.number;
    }

    // 更新奖励
    function updatePool() public {
        if (block.number <= lastRewardBlock) {
            return;
        }

        if (totalStaked == 0) {
            lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = block.number - lastRewardBlock;
        uint256 reward = multiplier * REWARD_PER_BLOCK;
        accRewardPerShare += (reward * 1e18) / totalStaked;
        lastRewardBlock = block.number;
    }

    // 质押 ETH
    function stake() external payable override nonReentrant {
        require(msg.value > 0, "Cannot stake 0");
        UserInfo storage user = userInfo[msg.sender];
        
        updatePool();

        // 如果用户已经有质押，先结算之前的奖励
        if (user.amount > 0) {
            uint256 pending = (user.amount * accRewardPerShare / 1e18) - user.rewardDebt;
            if (pending > 0) {
                kkToken.mint(msg.sender, pending);
            }
        }

        // 更新用户信息
        user.amount += msg.value;
        user.rewardDebt = user.amount * accRewardPerShare / 1e18;
        user.lastStakeTime = block.timestamp;
        totalStaked += msg.value;

        // 将 ETH 存入 Aave
        lendingPool.supply{value: msg.value}(address(this), msg.value, address(this), 0);
    }

    // 赎回质押的 ETH
    function unstake(uint256 amount) external override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= amount, "Insufficient balance");
        
        updatePool();

        // 计算待领取的奖励
        uint256 pending = (user.amount * accRewardPerShare / 1e18) - user.rewardDebt;
        if (pending > 0) {
            kkToken.mint(msg.sender, pending);
        }

        // 更新用户信息
        user.amount -= amount;
        user.rewardDebt = user.amount * accRewardPerShare / 1e18;
        totalStaked -= amount;

        // 从 Aave 取回 ETH
        lendingPool.withdraw(address(this), amount, msg.sender);
    }

    // 领取奖励
    function claim() external override nonReentrant {
        UserInfo storage user = userInfo[msg.sender];
        updatePool();

        uint256 pending = (user.amount * accRewardPerShare / 1e18) - user.rewardDebt;
        if (pending > 0) {
            user.rewardDebt = user.amount * accRewardPerShare / 1e18;
            kkToken.mint(msg.sender, pending);
        }
    }

    // 查询质押余额
    function balanceOf(address account) external view override returns (uint256) {
        return userInfo[account].amount;
    }

    // 查询待领取奖励
    function earned(address account) external view override returns (uint256) {
        UserInfo storage user = userInfo[account];
        uint256 _accRewardPerShare = accRewardPerShare;
        
        if (block.number > lastRewardBlock && totalStaked != 0) {
            uint256 multiplier = block.number - lastRewardBlock;
            uint256 reward = multiplier * REWARD_PER_BLOCK;
            _accRewardPerShare += (reward * 1e18) / totalStaked;
        }
        
        return (user.amount * _accRewardPerShare / 1e18) - user.rewardDebt;
    }

    // 接收 ETH
    receive() external payable {}
} 
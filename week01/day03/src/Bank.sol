// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./IBank.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Bank is IBank {
    // 定义存款人信息结构体
    struct Depositor {
        address addr;
        uint256 amount;
    }
    
    // 合约拥有者地址
    address public owner;
    
    // 记录每个地址的ETH存款金额
    mapping(address => uint256) public balances;
    
    // 记录每个地址的代币存款金额
    mapping(address => mapping(address => uint256)) public tokenBalances;
    
    // 存储前三名用户地址
    address[3] public topDepositors;
    uint256[3] public topAmounts;

    // 事件声明
    event Deposit(address indexed depositor, uint256 amount);
    event TokenDeposit(address indexed depositor, address indexed token, uint256 amount);
    event Withdrawal(uint256 amount);
    event TokenWithdrawal(address indexed token, uint256 amount);
    event TopDepositorUpdated(address indexed depositor, uint256 amount, uint256 rank);

    constructor() {
        owner = msg.sender;
    }

    // 检查是否是合约拥有者
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 接收以太币的回退函数
    receive() external payable {
        deposit();
    }

    // ETH存款函数
    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
        
        // 更新用户余额
        balances[msg.sender] += msg.value;
        
        // 更新前三名排名
        updateTopDepositors(msg.sender, balances[msg.sender]);
        
        emit Deposit(msg.sender, msg.value);
    }

    // ERC20代币存款函数
    function depositToken(address token, uint256 amount) public {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(token != address(0), "Invalid token address");
        
        // 1. 首先需要approve
        IERC20(token).approve(address(this), amount);
        
        // 2. 然后才能存款
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        require(success, "Token transfer failed");
        
        // 更新用户代币余额
        tokenBalances[token][msg.sender] += amount;
        
        emit TokenDeposit(msg.sender, token, amount);
    }

    // 更新前三名存款人
    function updateTopDepositors(address depositor, uint256 amount) internal {
        // 遍历前三名，找到合适的插入位置
        for (uint256 i = 0; i < 3; i++) {
            if (amount > topAmounts[i]) {
                // 将当前位置及之后的元素后移
                for (uint256 j = 2; j > i; j--) {
                    topDepositors[j] = topDepositors[j-1];
                    topAmounts[j] = topAmounts[j-1];
                }
                // 插入新的存款人
                topDepositors[i] = depositor;
                topAmounts[i] = amount;
                emit TopDepositorUpdated(depositor, amount, i + 1);
                break;
            }
        }
    }

    // ETH提款函数（仅管理员可调用）
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient contract balance");
        
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed");
        
        emit Withdrawal(amount);
    }

    // ERC20代币提款函数（仅管理员可调用）
    function withdrawToken(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        
        bool success = IERC20(token).transferFrom(address(this), owner, amount);
        require(success, "Token withdrawal failed");
        
        emit TokenWithdrawal(token, amount);
    }

    // 查询合约ETH余额
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // 查询用户ETH余额
    function getBalance(address user) public view returns (uint256) {
        return balances[user];
    }

    // 查询用户代币余额
    function getTokenBalance(address token, address user) public view returns (uint256) {
        return tokenBalances[token][user];
    }

    // 获取前三名存款人信息
    function getTopDepositors() public view returns (Depositor[3] memory) {
        Depositor[3] memory result;
        for(uint i = 0; i < 3; i++) {
            result[i] = Depositor({
                addr: topDepositors[i],
                amount: topAmounts[i]
            });
        }
        return result;
    }
} 
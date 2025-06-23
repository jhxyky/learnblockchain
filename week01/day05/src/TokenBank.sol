// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Token.sol";

/**
 * @title TokenBank
 * @dev 一个简单的代币银行合约，允许用户存入和取出 ERC20 代币
 */
contract TokenBank {
    // 代币合约
    Token public token;
    
    // 用户余额映射
    mapping(address => uint256) public balances;
    
    // 事件
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    
    /**
     * @dev 构造函数
     * @param _tokenAddress 代币合约地址
     */
    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Invalid token address");
        token = Token(_tokenAddress);
    }
    
    /**
     * @dev 存款函数
     * @param _amount 存款金额
     * @return 是否成功
     */
    function deposit(uint256 _amount) external returns (bool) {
        require(_amount > 0, "Amount must be greater than 0");
        
        // 检查用户是否已经授权给本合约
        require(token.allowance(msg.sender, address(this)) >= _amount, "Insufficient allowance");
        
        // 从用户账户转移代币到本合约
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");
        
        // 更新用户余额
        balances[msg.sender] += _amount;
        
        // 触发存款事件
        emit Deposit(msg.sender, _amount);
        
        return true;
    }
    
    /**
     * @dev 取款函数
     * @param _amount 取款金额
     * @return 是否成功
     */
    function withdraw(uint256 _amount) external returns (bool) {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        
        // 更新用户余额
        balances[msg.sender] -= _amount;
        
        // 从合约转移代币到用户账户
        bool success = token.transfer(msg.sender, _amount);
        require(success, "Token transfer failed");
        
        // 触发取款事件
        emit Withdraw(msg.sender, _amount);
        
        return true;
    }
    
    /**
     * @dev 查询用户在银行的余额
     * @param _user 用户地址
     * @return 用户余额
     */
    function balanceOf(address _user) external view returns (uint256) {
        return balances[_user];
    }
} 
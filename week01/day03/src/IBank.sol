// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IBank {
    // 存款相关
    function deposit() external payable;
    function depositToken(address token, uint256 amount) external;
    
    // 提款相关
    function withdraw(uint256 amount) external;
    function withdrawToken(address token, uint256 amount) external;
    
    // 查询余额
    function getContractBalance() external view returns (uint256);
    function getBalance(address user) external view returns (uint256);
    function getTokenBalance(address token, address user) external view returns (uint256);
    
    // 管理员相关
    function owner() external view returns (address);
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title VaultLogic
 * @notice 这是一个包含密码验证和所有权管理的逻辑合约
 * @dev 这个合约将被 Vault 合约通过 delegatecall 调用
 */
contract VaultLogic {
    // 存储槽 0：合约所有者地址
    address public owner;
    // 存储槽 1：用于验证的密码
    bytes32 private password;

    /**
     * @notice 构造函数，设置初始密码和所有者
     * @param _password 初始密码
     */
    constructor(bytes32 _password) {
        owner = msg.sender;
        password = _password;
    }

    /**
     * @notice 更改合约所有者
     * @dev 通过密码验证来更改所有者，这个函数会被 delegatecall 调用
     * @param _password 验证密码
     * @param newOwner 新的所有者地址
     */
    function changeOwner(bytes32 _password, address newOwner) public {
        if (password == _password) {
            owner = newOwner;
        } else {
            revert("password error");
        }
    }
}

/**
 * @title Vault
 * @notice 这是一个有漏洞的金库合约，包含多个安全问题
 * @dev 主要漏洞：
 * 1. 重入攻击漏洞（withdraw 函数）
 * 2. 不安全的余额检查（deposites[msg.sender] >= 0）
 * 3. 不安全的 delegatecall 使用
 */
contract Vault {
    // 存储槽 0：合约所有者地址
    address public owner;
    // 存储槽 1：逻辑合约实例
    VaultLogic logic;
    // 存储槽 2：用户存款映射
    mapping(address => uint) deposites;
    // 存储槽 3：提款开关
    bool public canWithdraw = false;

    /**
     * @notice 构造函数
     * @param _logicAddress 逻辑合约地址
     */
    constructor(address _logicAddress) {
        logic = VaultLogic(_logicAddress);
        owner = msg.sender;
    }

    /**
     * @notice 回退函数，用于处理对未定义函数的调用
     * @dev 使用 delegatecall 调用逻辑合约，这可能导致存储布局问题
     */
    fallback() external {
        (bool result,) = address(logic).delegatecall(msg.data);
        if (result) {
            this;
        }
    }

    /**
     * @notice 接收 ETH 的函数
     */
    receive() external payable {}

    /**
     * @notice 存款函数
     * @dev 将发送的 ETH 记录到用户的存款余额中
     */
    function deposite() public payable {
        deposites[msg.sender] += msg.value;
    }

    /**
     * @notice 检查合约是否被攻破
     * @dev 如果合约余额为 0，则认为攻击成功
     * @return bool 是否成功攻破合约
     */
    function isSolve() external view returns (bool) {
        if (address(this).balance == 0) {
            return true;
        }
    }

    /**
     * @notice 开启提款功能
     * @dev 只有合约所有者可以调用
     */
    function openWithdraw() external {
        if (owner == msg.sender) {
            canWithdraw = true;
        } else {
            revert("not owner");
        }
    }

    /**
     * @notice 提款函数
     * @dev 存在以下漏洞：
     * 1. 不安全的余额检查 (deposites[msg.sender] >= 0 总是为真)
     * 2. 重入攻击漏洞 (先发送 ETH 后更新状态)
     */
    function withdraw() public {
        if (canWithdraw && deposites[msg.sender] >= 0) {
            (bool result,) = msg.sender.call{value: deposites[msg.sender]}("");
            if (result) {
                deposites[msg.sender] = 0;
            }
        }
    }
} 
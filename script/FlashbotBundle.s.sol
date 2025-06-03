// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/OpenspaceNFT.sol";

contract FlashbotBundleScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 NFT 合约
        OpenspaceNFT nft = new OpenspaceNFT();
        console.log("NFT Contract deployed at:", address(nft));

        // 2. 准备交易数据
        bytes memory enablePresaleData = abi.encodeWithSignature("enablePresale()");
        bytes memory presaleData = abi.encodeWithSignature("presale(uint256)", 1);

        // 3. 获取 Flashbots 中继地址
        address flashbotsRelay = vm.envAddress("FLASHBOTS_RELAY");
        console.log("Using Flashbots Relay:", flashbotsRelay);
        
        // 4. 发送第一个交易：开启预售
        console.log("Sending enablePresale transaction...");
        vm.broadcast();
        (bool success1,) = flashbotsRelay.call(enablePresaleData);
        require(success1, "Enable presale failed");

        // 5. 发送第二个交易：购买 NFT
        console.log("Sending presale transaction...");
        vm.broadcast();
        (bool success2,) = flashbotsRelay.call{ value: 0.01 ether }(presaleData);
        require(success2, "Presale failed");

        // 6. 输出状态信息
        console.log("Transactions completed!");
        console.log("NFT Contract:", address(nft));
        console.log("Flashbots Relay:", flashbotsRelay);
        console.log("Current Block:", block.number);

        vm.stopBroadcast();
    }
} 
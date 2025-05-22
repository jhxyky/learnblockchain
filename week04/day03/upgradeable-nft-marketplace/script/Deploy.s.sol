// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarketplaceV1.sol";
import "../src/NFTMarketplaceV2.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署 NFT 合约
        MyNFT nftImpl = new MyNFT();
        ERC1967Proxy nftProxy = new ERC1967Proxy(
            address(nftImpl),
            abi.encodeWithSelector(MyNFT.initialize.selector, "MyNFT", "MNFT")
        );
        
        // 部署市场合约 V1
        NFTMarketplaceV1 marketplaceImpl = new NFTMarketplaceV1();
        bytes memory initData = abi.encodeWithSelector(
            NFTMarketplaceV1.initialize.selector
        );
        ERC1967Proxy marketplaceProxy = new ERC1967Proxy(
            address(marketplaceImpl),
            initData
        );

        // 部署市场合约 V2（但暂时不升级）
        NFTMarketplaceV2 marketplaceV2 = new NFTMarketplaceV2();

        console.log("Deployment Addresses:");
        console.log("NFT Proxy:", address(nftProxy));
        console.log("NFT Implementation:", address(nftImpl));
        console.log("Marketplace Proxy:", address(marketplaceProxy));
        console.log("Marketplace V1 Implementation:", address(marketplaceImpl));
        console.log("Marketplace V2 Implementation:", address(marketplaceV2));

        vm.stopBroadcast();
    }
} 
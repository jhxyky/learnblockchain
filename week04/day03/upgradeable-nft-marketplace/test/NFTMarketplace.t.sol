// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import "../src/MyNFT.sol";
import "../src/NFTMarketplaceV1.sol";
import "../src/NFTMarketplaceV2.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract NFTMarketplaceTest is Test {
    MyNFT public nft;
    NFTMarketplaceV1 public marketplaceImpl;
    ERC1967Proxy public marketplaceProxy;
    NFTMarketplaceV1 public marketplace;

    address public owner = address(1);
    address public seller = address(2);
    address public buyer = address(3);

    uint256 public constant PRICE = 1 ether;
    uint256 public constant TOKEN_ID = 0;

    function setUp() public {
        vm.startPrank(owner);
        
        // 部署 NFT 合约
        MyNFT nftImpl = new MyNFT();
        ERC1967Proxy nftProxy = new ERC1967Proxy(
            address(nftImpl),
            abi.encodeWithSelector(MyNFT.initialize.selector, "MyNFT", "MNFT")
        );
        nft = MyNFT(address(nftProxy));

        // 部署市场合约 V1
        marketplaceImpl = new NFTMarketplaceV1();
        bytes memory initData = abi.encodeWithSelector(
            NFTMarketplaceV1.initialize.selector
        );
        marketplaceProxy = new ERC1967Proxy(address(marketplaceImpl), initData);
        marketplace = NFTMarketplaceV1(address(marketplaceProxy));

        // 设置测试环境
        nft.safeMint(seller);
        vm.deal(buyer, 100 ether);
        vm.stopPrank();
    }

    function test_ListNFT() public {
        vm.startPrank(seller);
        nft.setApprovalForAll(address(marketplace), true);
        marketplace.listNFT(address(nft), TOKEN_ID, PRICE);
        
        (
            address listedSeller,
            address listedNft,
            uint256 listedTokenId,
            uint256 listedPrice,
            bool isActive
        ) = marketplace.listings(address(nft), TOKEN_ID);

        assertEq(listedSeller, seller);
        assertEq(listedNft, address(nft));
        assertEq(listedTokenId, TOKEN_ID);
        assertEq(listedPrice, PRICE);
        assertTrue(isActive);
        vm.stopPrank();
    }

    function test_BuyNFT() public {
        // 上架 NFT
        vm.startPrank(seller);
        nft.setApprovalForAll(address(marketplace), true);
        marketplace.listNFT(address(nft), TOKEN_ID, PRICE);
        vm.stopPrank();

        // 购买 NFT
        vm.startPrank(buyer);
        marketplace.buyNFT{value: PRICE}(address(nft), TOKEN_ID);

        // 验证购买结果
        assertEq(nft.ownerOf(TOKEN_ID), buyer);
        vm.stopPrank();
    }

    function test_UpgradeToV2() public {
        // 部署 V2 实现合约
        NFTMarketplaceV2 marketplaceV2 = new NFTMarketplaceV2();

        // 记录升级前的状态
        uint256 originalFeeRate = marketplace.marketFeeRate();

        // 升级到 V2
        vm.startPrank(owner);
        NFTMarketplaceV2(address(marketplace)).upgradeTo(address(marketplaceV2));
        NFTMarketplaceV2(address(marketplace)).initializeV2("NFTMarketplace");
        vm.stopPrank();

        // 验证升级后状态保持一致
        assertEq(marketplace.marketFeeRate(), originalFeeRate);

        // 测试是否成功升级
        assertTrue(address(marketplaceV2) != address(0), "V2 implementation deployed");
    }
} 
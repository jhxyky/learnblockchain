// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/forge-std/src/Test.sol";
import "../src/MyNFT.sol";
import "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract MyNFTTest is Test {
    MyNFT public implementation;
    ERC1967Proxy public proxy;
    MyNFT public nft;

    address public owner = address(1);
    address public user1 = address(2);
    address public user2 = address(3);

    function setUp() public {
        vm.startPrank(owner);
        
        // 部署实现合约
        implementation = new MyNFT();
        
        // 部署代理合约
        bytes memory initData = abi.encodeWithSelector(
            MyNFT.initialize.selector,
            "MyNFT",
            "MNFT"
        );
        proxy = new ERC1967Proxy(address(implementation), initData);
        
        // 创建代理合约的接口
        nft = MyNFT(address(proxy));

        // 设置测试环境
        vm.deal(owner, 100 ether);
        vm.stopPrank();
    }

    function test_Initialize() public {
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
        assertEq(nft.owner(), owner);
    }

    function test_SafeMint() public {
        vm.startPrank(owner);
        uint256 tokenId = nft.safeMint(user1);
        assertEq(nft.ownerOf(tokenId), user1);
        assertEq(tokenId, 0);
        vm.stopPrank();
    }

    function test_SafeMintOnlyOwner() public {
        vm.startPrank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.safeMint(user2);
        vm.stopPrank();
    }

    function test_Upgrade() public {
        // 部署新版本实现合约
        MyNFT implementationV2 = new MyNFT();
        
        vm.startPrank(owner);
        // 升级到新版本
        nft.upgradeTo(address(implementationV2));
        vm.stopPrank();

        // 验证升级后的状态
        assertEq(nft.name(), "MyNFT");
        assertEq(nft.symbol(), "MNFT");
    }

    function test_UpgradeOnlyOwner() public {
        MyNFT implementationV2 = new MyNFT();
        
        vm.startPrank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.upgradeTo(address(implementationV2));
        vm.stopPrank();
    }
} 
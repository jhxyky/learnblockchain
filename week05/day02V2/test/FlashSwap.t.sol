// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/FlashSwap.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";
import "v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract FlashSwapTest is Test {
    FlashSwap public flashSwap;
    TokenA public tokenA;
    TokenB public tokenB;
    IUniswapV2Factory public factory;
    IUniswapV2Pair public pair;
    
    address public constant FACTORY_ADDRESS = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    address public user = makeAddr("user");
    address public owner = makeAddr("owner");

    function setUp() public {
        // 部署代币
        vm.startPrank(owner);
        tokenA = new TokenA();
        tokenB = new TokenB();
        
        // 设置 factory
        factory = IUniswapV2Factory(FACTORY_ADDRESS);
        
        // 部署闪电兑换合约
        flashSwap = new FlashSwap(FACTORY_ADDRESS);
        
        // 创建交易对
        pair = IUniswapV2Pair(factory.createPair(address(tokenA), address(tokenB)));
        
        vm.stopPrank();
    }

    function testFlashSwap() public {
        // 添加初始流动性
        vm.startPrank(owner);
        uint amountA = 1000 * 1e18;
        uint amountB = 1000 * 1e18;
        
        tokenA.transfer(address(pair), amountA);
        tokenB.transfer(address(pair), amountB);
        pair.mint(owner);
        
        // 执行闪电兑换
        uint borrowAmount = 100 * 1e18;
        flashSwap.initFlashSwap(
            address(tokenA),
            borrowAmount,
            address(tokenB),
            address(pair)
        );
        
        vm.stopPrank();
    }
} 
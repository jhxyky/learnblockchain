// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MemeToken.sol";
import "../src/MockUniswapV2Pair.sol";
import "../src/TWAPOracle.sol";

contract TWAPOracleTest is Test {
    MemeToken public meme;
    MemeToken public usdc;
    MockUniswapV2Pair public pair;
    TWAPOracle public oracle;
    
    function setUp() public {
        // 部署代币
        meme = new MemeToken();
        usdc = new MemeToken();
        
        // 部署交易对和预言机
        pair = new MockUniswapV2Pair(address(meme), address(usdc));
        oracle = new TWAPOracle(address(pair));
        
        // 初始价格: 1 MEME = 1 USDC
        pair.update(uint112(1000 * 1e18), uint112(1000 * 1e18));
    }
    
    function testInitialPrice() public {
        uint price = oracle.getCurrentPrice(true); // MEME to USDC
        assertEq(price, 1 * 2**112); // 价格应该是1（以Q112格式）
    }
    
    function testPriceChange() public {
        // 初始时间
        vm.warp(block.timestamp + 1 hours);
        
        // 更新价格: 1 MEME = 2 USDC
        pair.update(uint112(1000 * 1e18), uint112(2000 * 1e18));
        oracle.updateCheckpoint();
        
        // 等待30分钟
        vm.warp(block.timestamp + 30 minutes);
        
        // 更新价格: 1 MEME = 3 USDC
        pair.update(uint112(1000 * 1e18), uint112(3000 * 1e18));
        
        // 再等待30分钟
        vm.warp(block.timestamp + 30 minutes);
        
        // 更新价格: 1 MEME = 2.5 USDC
        pair.update(uint112(1000 * 1e18), uint112(2500 * 1e18));
        
        // 计算TWAP
        uint twapPrice = oracle.computeTWAP(true);
        uint expectedPrice = uint(2.5 * 2**112);
        
        // 输出价格进行调试
        emit log_named_uint("TWAP Price", twapPrice / 2**112);
        emit log_named_uint("Expected Price", expectedPrice / 2**112);
        
        // TWAP应该接近2.5（因为是最后一小时的平均价格）
        assertApproxEqRel(twapPrice, expectedPrice, 0.1e18); // 允许10%的误差
    }
    
    function testVolatilePrices() public {
        // 模拟高波动性的价格变化
        uint[] memory prices = new uint[](6);
        prices[0] = 1000; // 1 USDC
        prices[1] = 1500; // 1.5 USDC
        prices[2] = 800;  // 0.8 USDC
        prices[3] = 2000; // 2 USDC
        prices[4] = 1200; // 1.2 USDC
        prices[5] = 1800; // 1.8 USDC
        
        for (uint i = 0; i < prices.length; i++) {
            vm.warp(block.timestamp + 10 minutes);
            pair.update(uint112(1000 * 1e18), uint112(uint(prices[i] * 1e18)));
            if (i == 0) oracle.updateCheckpoint();
        }
        
        // 计算TWAP
        uint twapPrice = oracle.computeTWAP(true);
        
        // 输出结果供分析
        emit log_named_uint("TWAP Price", twapPrice / 2**112);
        emit log_named_uint("Current Price", oracle.getCurrentPrice(true) / 2**112);
    }
    
    function testLongPeriodTWAP() public {
        // 模拟24小时的价格变化
        uint[] memory prices = new uint[](24);
        for (uint i = 0; i < 24; i++) {
            // 生成一个在0.5到1.5之间的随机价格
            uint price = 1000 + (i * 100) % 1000;
            prices[i] = price;
            
            vm.warp(block.timestamp + 1 hours);
            pair.update(uint112(1000 * 1e18), uint112(uint(price * 1e18)));
            
            if (i % 6 == 0) {
                oracle.updateCheckpoint();
            }
        }
        
        // 计算TWAP
        uint twapPrice = oracle.computeTWAP(true);
        emit log_named_uint("24h TWAP Price", twapPrice / 2**112);
    }
} 
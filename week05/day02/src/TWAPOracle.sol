// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./MockUniswapV2Pair.sol";

contract TWAPOracle {
    MockUniswapV2Pair public immutable pair;
    address public immutable token0;
    address public immutable token1;
    
    // 存储价格累加器的检查点
    struct Checkpoint {
        uint32 timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }
    
    Checkpoint public lastCheckpoint;
    
    constructor(address _pair) {
        pair = MockUniswapV2Pair(_pair);
        token0 = pair.token0();
        token1 = pair.token1();
        
        // 初始化检查点
        _updateCheckpoint();
    }
    
    // 更新检查点
    function updateCheckpoint() external {
        _updateCheckpoint();
    }
    
    function _updateCheckpoint() internal {
        lastCheckpoint = Checkpoint({
            timestamp: uint32(block.timestamp),
            price0Cumulative: pair.price0CumulativeLast(),
            price1Cumulative: pair.price1CumulativeLast()
        });
    }
    
    // 计算TWAP价格
    function computeTWAP(bool token0ToToken1) public view returns (uint) {
        require(block.timestamp > lastCheckpoint.timestamp, "Period not elapsed");
        
        uint32 timeElapsed = uint32(block.timestamp - lastCheckpoint.timestamp);
        uint priceCumulativeStart = token0ToToken1 ? 
            lastCheckpoint.price0Cumulative : 
            lastCheckpoint.price1Cumulative;
        uint priceCumulativeEnd = token0ToToken1 ? 
            pair.price0CumulativeLast() : 
            pair.price1CumulativeLast();
            
        // 计算时间加权平均价格
        uint priceAverage = (priceCumulativeEnd - priceCumulativeStart) / timeElapsed;
        
        return priceAverage;
    }
    
    // 获取当前即时价格
    function getCurrentPrice(bool token0ToToken1) public view returns (uint) {
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        if (token0ToToken1) {
            return (uint(reserve1) << 112) / reserve0;
        } else {
            return (uint(reserve0) << 112) / reserve1;
        }
    }
} 
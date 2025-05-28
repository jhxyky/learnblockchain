// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockUniswapV2Pair {
    uint public constant PERIOD = 30 minutes;
    
    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public lastTimestamp;
    
    // 储存token0和token1的数量，用于计算价格
    uint112 private reserve0;
    uint112 private reserve1;
    
    address public immutable token0;
    address public immutable token1;
    
    constructor(address _token0, address _token1) {
        require(_token0 != address(0), "Invalid token0");
        require(_token1 != address(0), "Invalid token1");
        token0 = _token0;
        token1 = _token1;
        lastTimestamp = block.timestamp;
    }
    
    // 更新储备量和累积价格
    function update(uint112 _reserve0, uint112 _reserve1) external {
        require(_reserve0 > 0 && _reserve1 > 0, "Invalid reserves");
        
        uint32 timeElapsed = uint32(block.timestamp - lastTimestamp);
        if (timeElapsed > 0 && reserve0 > 0 && reserve1 > 0) {
            // 使用简单的价格计算方式：price = reserve1 / reserve0 * 2^112
            uint price0 = (uint(reserve1) << 112) / reserve0;
            uint price1 = (uint(reserve0) << 112) / reserve1;
            price0CumulativeLast += price0 * timeElapsed;
            price1CumulativeLast += price1 * timeElapsed;
        }
        
        reserve0 = _reserve0;
        reserve1 = _reserve1;
        lastTimestamp = block.timestamp;
    }
    
    // 获取当前储备量
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _lastTimestamp) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _lastTimestamp = uint32(lastTimestamp);
    }
} 
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract FlashSwap is IUniswapV2Callee {
    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    // 触发闪电兑换的函数
    function initFlashSwap(
        address _tokenBorrow, // 要借入的代币
        uint256 _amount,      // 借入金额
        address _tokenPay,    // 要支付的代币
        address _pairAddress  // UniswapV2 交易对地址
    ) external {
        address pair = _pairAddress;
        require(pair != address(0), "Invalid pair address");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        require(token0 == _tokenBorrow || token1 == _tokenBorrow, "Token not in pair");

        bytes memory data = abi.encode(
            _tokenBorrow,
            _amount,
            _tokenPay,
            msg.sender
        );

        // amount0Out 或 amount1Out 中的一个会是0，另一个是要借的金额
        uint amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint amount1Out = _tokenBorrow == token1 ? _amount : 0;

        // 调用 swap 执行闪电兑换
        IUniswapV2Pair(pair).swap(
            amount0Out,
            amount1Out,
            address(this), // 接收代币的地址
            data          // 携带的数据
        );
    }

    // UniswapV2 回调函数
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external override {
        // 解码数据
        (
            address tokenBorrow,
            uint256 amount,
            address tokenPay,
            address caller
        ) = abi.decode(data, (address, uint256, address, address));

        // 确保调用者是配对合约
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(factory).getPair(token0, token1);
        require(msg.sender == pair, "Not pair");
        require(sender == address(this), "Not sender");

        // 在这里执行套利逻辑
        // 这里我们模拟一个简单的套利：假设我们可以以更好的价格在其他地方交易
        // 在实际场景中，这里应该调用其他 DEX 或交易场所进行套利

        // 计算需要返还的金额（包含0.3%的手续费）
        uint fee = ((amount * 3) / 997) + 1;
        uint amountToRepay = amount + fee;

        // 确保我们有足够的代币来还款
        require(
            IERC20(tokenPay).balanceOf(address(this)) >= amountToRepay,
            "Insufficient token for payback"
        );

        // 将借到的代币还回去
        IERC20(tokenPay).transfer(pair, amountToRepay);

        // 如果有剩余利润，转给调用者
        uint profit = IERC20(tokenBorrow).balanceOf(address(this));
        if (profit > 0) {
            IERC20(tokenBorrow).transfer(caller, profit);
        }

        emit FlashSwap(tokenBorrow, amount, tokenPay, amountToRepay, caller);
    }

    // 事件
    event FlashSwap(
        address tokenBorrow,
        uint256 amount,
        address tokenPay,
        uint256 amountToRepay,
        address caller
    );
} 
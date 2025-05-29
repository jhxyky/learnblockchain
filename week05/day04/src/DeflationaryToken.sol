// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DeflationaryToken is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18; // 1亿初始供应量
    uint256 public constant DEFLATION_RATE = 1; // 1% 年通缩率
    uint256 public constant DEFLATION_DENOMINATOR = 100;
    
    uint256 public lastRebaseTime;
    uint256 public rebaseIndex = 1e18; // 精度为18位小数

    constructor() ERC20("Deflationary Token", "DFT") Ownable(msg.sender) {
        _mint(msg.sender, INITIAL_SUPPLY);
        lastRebaseTime = block.timestamp;
    }

    // 执行通缩 rebase
    function rebase() public {
        require(block.timestamp >= lastRebaseTime + 365 days, "Too early for rebase");
        
        // 计算经过的年数
        uint256 yearsElapsed = (block.timestamp - lastRebaseTime) / 365 days;
        
        // 计算新的 rebaseIndex
        for (uint256 i = 0; i < yearsElapsed; i++) {
            rebaseIndex = rebaseIndex * (DEFLATION_DENOMINATOR - DEFLATION_RATE) / DEFLATION_DENOMINATOR;
        }
        
        lastRebaseTime = block.timestamp;
        
        emit Rebase(rebaseIndex);
    }

    // 重写 balanceOf 以反映通缩后的余额
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) * rebaseIndex / 1e18;
    }

    // 重写 totalSupply 以反映通缩后的总供应量
    function totalSupply() public view override returns (uint256) {
        return super.totalSupply() * rebaseIndex / 1e18;
    }

    // 获取原始余额（未经过通缩计算的）
    function rawBalanceOf(address account) public view returns (uint256) {
        return super.balanceOf(account);
    }

    event Rebase(uint256 newIndex);
} 
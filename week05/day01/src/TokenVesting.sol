// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract TokenVesting is Ownable(msg.sender) {
    using SafeERC20 for IERC20;

    event TokensReleased(address token, uint256 amount);
    event VestingStarted(address beneficiary, address token, uint256 startTime);

    // 受益人地址
    address public immutable beneficiary;
    // ERC20代币地址
    IERC20 public immutable token;
    // 开始时间
    uint256 public start;
    // cliff期结束时间
    uint256 public immutable cliff;
    // 归属期结束时间
    uint256 public immutable end;
    // 已释放的代币数量
    uint256 public released;
    // 总锁定数量
    uint256 public immutable totalAmount;
    // 每月释放数量
    uint256 public immutable monthlyRelease;

    /**
     * @param _beneficiary 受益人地址
     * @param _token ERC20代币地址
     * @param _totalAmount 总锁定数量
     */
    constructor(
        address _beneficiary,
        address _token,
        uint256 _totalAmount
    ) Ownable(msg.sender) {
        require(_beneficiary != address(0), "TokenVesting: beneficiary is zero address");
        require(_token != address(0), "TokenVesting: token is zero address");
        require(_totalAmount > 0, "TokenVesting: amount is 0");

        beneficiary = _beneficiary;
        token = IERC20(_token);
        totalAmount = _totalAmount;
        monthlyRelease = _totalAmount / 24; // 24个月线性释放

        // 设置时间参数
        start = block.timestamp;
        cliff = start + 365 days; // 12个月cliff
        end = cliff + 730 days;   // 24个月线性释放期

        emit VestingStarted(_beneficiary, _token, start);
    }

    /**
     * @dev 计算当前可释放的代币数量
     */
    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        }
        if (block.timestamp >= end) {
            return totalAmount;
        }

        // 计算从cliff开始到现在经过的月数
        uint256 monthsSinceCliff = (block.timestamp - cliff) / 30 days;
        
        // 计算应该释放的总量
        uint256 vested = monthsSinceCliff * monthlyRelease;
        
        // 确保不超过总量
        return Math.min(vested, totalAmount);
    }

    /**
     * @dev 释放当前可释放的代币
     */
    function release() public {
        uint256 vested = vestedAmount();
        require(vested > released, "TokenVesting: no tokens are due");

        uint256 amount;
        if (block.timestamp >= end) {
            // 如果已经到了结束时间，释放所有剩余代币
            amount = totalAmount - released;
        } else {
            amount = vested - released;
        }
        
        released = released + amount;

        token.safeTransfer(beneficiary, amount);
        emit TokensReleased(address(token), amount);
    }

    /**
     * @dev 查看当前可释放的代币数量
     */
    function releasable() public view returns (uint256) {
        if (block.timestamp >= end) {
            return totalAmount - released;
        }
        return vestedAmount() - released;
    }
} 
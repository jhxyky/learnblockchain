// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CallOptionToken is ERC20, Ownable {
    uint256 public strikePrice;        // 行权价格（以 USDT 计价）
    uint256 public expirationDate;     // 到期日时间戳
    uint256 public constant DECIMALS = 18;
    IERC20 public immutable USDT;      // USDT 合约地址

    event OptionIssued(address indexed issuer, uint256 ethAmount, uint256 tokenAmount);
    event OptionExercised(address indexed holder, uint256 ethAmount, uint256 usdtAmount);
    event OptionExpired(address indexed owner, uint256 ethAmount);

    constructor(
        uint256 _strikePrice,
        uint256 _expirationDays,
        address _usdt
    ) ERC20("ETH Call Option", "ETHCALL") Ownable(msg.sender) {
        require(_strikePrice > 0, "Strike price must be positive");
        require(_expirationDays > 0, "Expiration days must be positive");
        require(_usdt != address(0), "Invalid USDT address");

        strikePrice = _strikePrice;
        expirationDate = block.timestamp + _expirationDays * 1 days;
        USDT = IERC20(_usdt);
    }

    // 发行期权
    function issueOptions() external payable {
        require(msg.value > 0, "Must send ETH");
        require(block.timestamp < expirationDate, "Option expired");

        // 每个 ETH 发行 1 个期权 Token
        uint256 tokenAmount = msg.value;
        _mint(msg.sender, tokenAmount);

        emit OptionIssued(msg.sender, msg.value, tokenAmount);
    }

    // 行权
    function exercise(uint256 optionAmount) external {
        require(block.timestamp <= expirationDate, "Option expired");
        require(optionAmount > 0, "Amount must be positive");
        require(balanceOf(msg.sender) >= optionAmount, "Insufficient option tokens");

        uint256 ethAmount = optionAmount;  // 1:1 比例
        uint256 usdtAmount = (optionAmount * strikePrice) / (10 ** DECIMALS);

        require(USDT.balanceOf(msg.sender) >= usdtAmount, "Insufficient USDT");
        require(address(this).balance >= ethAmount, "Insufficient ETH in contract");

        // 转移 USDT 到合约
        require(USDT.transferFrom(msg.sender, address(this), usdtAmount), "USDT transfer failed");

        // 销毁期权 Token
        _burn(msg.sender, optionAmount);

        // 转移 ETH 给用户
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "ETH transfer failed");

        emit OptionExercised(msg.sender, ethAmount, usdtAmount);
    }

    // 过期销毁
    function expire() external onlyOwner {
        require(block.timestamp > expirationDate, "Not expired yet");
        
        uint256 ethBalance = address(this).balance;
        uint256 usdtBalance = USDT.balanceOf(address(this));

        if (ethBalance > 0) {
            (bool success, ) = payable(owner()).call{value: ethBalance}("");
            require(success, "ETH transfer failed");
        }

        if (usdtBalance > 0) {
            require(USDT.transfer(owner(), usdtBalance), "USDT transfer failed");
        }

        emit OptionExpired(owner(), ethBalance);
    }

    // 查看期权是否已过期
    function isExpired() public view returns (bool) {
        return block.timestamp > expirationDate;
    }

    // 获取行权所需的 USDT 数量
    function getExerciseUSDTAmount(uint256 optionAmount) public view returns (uint256) {
        return (optionAmount * strikePrice) / (10 ** DECIMALS);
    }

    receive() external payable {}
} 
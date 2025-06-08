# Bank 智能合约

这是一个基于Solidity的银行智能合约，支持ETH和ERC20代币的存取款功能，并实现了存款排行榜功能。

## 功能特点

1. **ETH存款功能**
   - 支持直接转账ETH到合约地址
   - 通过`deposit()`函数存款
   - 自动记录用户ETH存款余额

2. **ERC20代币支持**
   - 支持任意ERC20代币的存取
   - 需要先授权（approve）才能存款
   - 分别记录每种代币的存款余额

3. **存款排行榜**
   - 实时追踪前三名存款用户
   - 基于ETH存款金额排名
   - 通过事件通知排名变更

4. **管理员功能**
   - 只有合约拥有者可以提取资金
   - 支持提取ETH和ERC20代币
   - 完整的权限控制

## 合约结构

```solidity
contract Bank {
    struct Depositor {
        address addr;    // 存款人地址
        uint256 amount; // 存款金额
    }
    
    // 主要状态变量
    address public owner;                    // 合约拥有者
    mapping(address => uint256) public balances;     // ETH余额
    mapping(address => mapping(address => uint256)) public tokenBalances;  // 代币余额
    address[3] public topDepositors;        // 前三名地址
    uint256[3] public topAmounts;           // 前三名金额
}
```

## 主要函数

### 存款相关
- `deposit()`: ETH存款函数
- `depositToken(address token, uint256 amount)`: ERC20代币存款函数
- `receive()`: 接收ETH转账的回退函数

### 提款相关
- `withdraw(uint256 amount)`: 提取ETH（仅管理员）
- `withdrawToken(address token, uint256 amount)`: 提取ERC20代币（仅管理员）

### 查询功能
- `getBalance(address user)`: 查询用户ETH余额
- `getTokenBalance(address token, address user)`: 查询用户代币余额
- `getContractBalance()`: 查询合约ETH余额
- `getTopDepositors()`: 获取前三名存款人信息

## 事件

- `Deposit`: ETH存款事件
- `TokenDeposit`: 代币存款事件
- `Withdrawal`: ETH提款事件
- `TokenWithdrawal`: 代币提款事件
- `TopDepositorUpdated`: 排名更新事件

## 如何使用

### 1. ETH存款
```solidity
// 方式1：直接转账
address(bank).transfer(1 ether);

// 方式2：调用存款函数
bank.deposit{value: 1 ether}();
```

### 2. ERC20代币存款
```solidity
// 1. 首先授权
IERC20(tokenAddress).approve(bankAddress, amount);

// 2. 存入代币
bank.depositToken(tokenAddress, amount);
```

### 3. 查询排名
```solidity
Bank.Depositor[3] memory topDepositors = bank.getTopDepositors();
```

## 测试

项目使用Foundry框架进行测试。测试文件包含以下测试用例：

- 基本存款功能测试
- 排名系统测试
- 管理员提款测试
- 非管理员提款限制测试
- 直接转账测试

运行测试：
```bash
forge test
```

## 安全特性

1. 权限控制
   - 使用`onlyOwner`修饰符限制关键功能
   - 严格的余额检查

2. 安全转账
   - 使用`call`进行ETH转账
   - 所有操作都有状态检查

3. 输入验证
   - 金额必须大于0
   - 代币地址不能为零地址

## 注意事项

1. 确保在调用`depositToken`之前已经授权足够的代币额度
2. 只有合约拥有者可以提取资金
3. 排名仅基于ETH存款金额，不包含ERC20代币

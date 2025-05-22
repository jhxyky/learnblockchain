# Vault 合约攻击演示

这个项目演示了如何攻击一个有漏洞的 Vault（金库）合约。主要展示了以下漏洞：

1. 重入攻击（Reentrancy Attack）
2. 不安全的存储布局（Unsafe Storage Layout）
3. 不安全的余额检查（Unsafe Balance Check）

## 漏洞分析

### 1. 重入攻击
`Vault` 合约的 `withdraw` 函数在发送 ETH 之前没有更新用户的余额，这允许攻击者在接收 ETH 时再次调用 `withdraw` 函数。

### 2. 不安全的存储布局
合约使用 `delegatecall` 调用 `VaultLogic` 合约，但两个合约的存储布局不同，这可能导致意外的状态变更。

### 3. 不安全的余额检查
`withdraw` 函数中的条件 `deposites[msg.sender] >= 0` 总是为真，因为 `uint` 类型永远大于等于 0。

## 攻击步骤

1. 部署攻击合约
2. 修改 Vault 合约的 owner
3. 打开提款开关
4. 利用重入攻击提取所有资金

## 运行测试

```bash
forge test -vv
```

## 防范措施

1. 使用 Checks-Effects-Interactions 模式
2. 添加重入锁
3. 正确检查余额和权限
4. 确保 delegatecall 的安全使用

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

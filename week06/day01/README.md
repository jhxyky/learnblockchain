# DAO治理合约

这是一个基于代币投票的DAO治理系统，允许代币持有者对提案进行投票和执行。

## 主要功能

- 提案创建和管理
- 基于代币的投票系统
- 提案执行和资金转移
- 权限控制和安全检查

## 合约结构

- `Gov.sol`: 治理合约，处理提案的创建、投票和执行
- `VoteToken.sol`: 投票代币合约，实现ERC20Votes标准
- `Bank.sol`: 资金管理合约，由治理合约控制

## 开发环境

- Solidity ^0.8.20
- Foundry
- OpenZeppelin Contracts

## 安装和测试

1. 克隆仓库
```bash
git clone <repository-url>
cd <repository-name>
```

2. 安装依赖
```bash
forge install
```

3. 运行测试
```bash
forge test
```

## 测试覆盖

- 提案创建
- 投票功能
- 提案执行
- 权限检查
- 重复投票限制

## 许可证

MIT

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

# Automated Bank Contract

这是一个使用 Chainlink Automation 实现自动化功能的银行合约。

## 功能特点

- 用户可以存入 ETH
- 当合约余额超过阈值时，自动将一半的余额转移到指定地址
- 使用 Chainlink Automation 实现自动化操作
- 完整的访问控制

## 技术栈

- Solidity ^0.8.13
- Foundry
- Chainlink Automation
- OpenZeppelin Contracts

## 安装

```bash
forge install
```

## 测试

```bash
forge test
```

## 部署

1. 复制 `.env.example` 到 `.env` 并填写必要的环境变量
2. 运行部署脚本：
```bash
forge script script/Bank.s.sol:BankScript --rpc-url $RPC_URL --broadcast
```

## Chainlink Automation 设置

1. 访问 [Chainlink Automation](https://automation.chain.link/)
2. 注册新的 Upkeep
3. 选择 "Custom Logic"
4. 输入已部署的合约地址
5. 提供必要的 LINK 代币作为执行费用

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

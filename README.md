# Foundry Project

这是一个使用 Foundry 框架的智能合约项目。

## 开发环境设置

```bash
# 安装依赖
forge install

# 编译合约
forge build

# 运行测试
forge test

# 部署合约
forge script script/Deploy.s.sol:Deploy --rpc-url <your_rpc_url> --private-key <your_private_key>
```

## 项目结构

- `src/`: 合约源代码
- `test/`: 测试文件
- `script/`: 部署脚本
- `lib/`: 依赖库 
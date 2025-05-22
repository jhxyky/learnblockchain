➤ 将 NFTMarket 合约改成可升级模式  https://decert.me/quests/ddbdd3c4-a633-49d7-adf9-34a6292ce3a8
➤ 作业 2 (理解合约升级涉及的存储布局)： https://decert.me/quests/8ea21ac0-fc65-414a-8afd-9507c0fa2d90
编写一个可升级的NFT Marketh合约
题目
编写一个可升级的 ERC721 合约.
实现⼀个可升级的 NFT 市场合约：
• 实现合约的第⼀版本和这个挑战 的逻辑一致。
• 逻辑合约的第⼆版本，加⼊离线签名上架 NFT 功能⽅法（签名内容：tokenId， 价格），实现⽤户⼀次性使用 setApproveAll 给 NFT 市场合约，每个 NFT 上架时仅需使⽤签名上架。
部署到测试⽹，并开源到区块链浏览器，在你的Github的 Readme.md 中备注代理合约及两个实现的合约地址。

要求：
包含升级的测试用例（升级前后的状态保持一致）
包含运行测试用例的日志。


# 可升级的 NFT 市场

这是一个基于 Foundry 开发的可升级 NFT 市场项目，包含以下主要功能：

## 功能特点

### MyNFT 合约
- 可升级的 ERC721 NFT 合约
- 支持基本的铸造功能
- 使用 UUPS 模式实现可升级性

### NFT 市场 V1
- 基本的 NFT 上架、下架功能
- NFT 购买功能
- 市场手续费机制
- 紧急暂停功能
- 可升级设计

### NFT 市场 V2
- 继承 V1 的所有功能
- 添加离线签名上架功能
- 支持 EIP-712 签名验证
- 使用 nonce 防止重放攻击

## 开发环境

- Solidity ^0.8.19
- Foundry
- OpenZeppelin Contracts

## 安装和测试

1. 克隆仓库：
```bash
git clone <repository-url>
cd upgradeable-nft-marketplace
```

2. 安装依赖：
```bash
forge install OpenZeppelin/openzeppelin-contracts-upgradeable
forge install OpenZeppelin/openzeppelin-contracts
```

3. 运行测试：
```bash
forge test -vvv
```

## 合约地址（Sepolia 测试网）

- NFT 代理合约：`0xF615F3faf6e55e5673DDa8fd6008886d858e463A`
- NFT 实现合约：`0xc2A35470C84cC498A1E5fC60C0A7E781702Bf6e6`
- 市场代理合约：`0xEC6097dce68465125114FF87Bd62435779B90368`
- 市场 V1 实现合约：`0x6Ef9EDc3A9Ce489f4F066C818dc75919F2650D09`
- 市场 V2 实现合约：`0xedeaD47994d5D7743e69cE990fF6693ee23de6DC`

## 项目结构

```
src/
├── MyNFT.sol              # 可升级的 NFT 合约
├── NFTMarketplaceV1.sol   # NFT 市场基础版本
└── NFTMarketplaceV2.sol   # NFT 市场升级版本（添加签名功能）

test/
├── MyNFT.t.sol           # NFT 合约测试
└── NFTMarketplace.t.sol  # 市场合约测试
```

## 主要功能说明

1. NFT 合约 (`MyNFT.sol`)
   - 实现标准的 ERC721 功能
   - 支持合约升级
   - 只有合约拥有者可以铸造 NFT

2. 市场合约 V1 (`NFTMarketplaceV1.sol`)
   - NFT 上架：卖家可以设定价格上架 NFT
   - NFT 下架：卖家可以随时下架自己的 NFT
   - NFT 购买：买家可以购买上架的 NFT
   - 市场手续费：每笔交易收取一定比例的手续费
   - 紧急暂停：合约拥有者可以暂停市场功能

3. 市场合约 V2 (`NFTMarketplaceV2.sol`)
   - 离线签名上架：卖家可以通过签名授权上架 NFT
   - EIP-712 签名：使用标准的签名格式，提高安全性
   - Nonce 机制：防止签名重放攻击

## 测试覆盖

项目包含完整的测试用例，覆盖：
- 合约初始化
- 基本功能测试
- 权限控制测试
- 升级机制测试
- 签名验证测试

## 安全考虑

1. 使用 OpenZeppelin 的标准合约和升级模式
2. 实现重入攻击防护
3. 使用安全的签名验证机制
4. 实现紧急暂停功能
5. 严格的权限控制

## 许可证

MIT
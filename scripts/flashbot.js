const { ethers } = require('ethers');
const { FlashbotsBundleProvider } = require('@flashbots/ethers-provider-bundle');
require('dotenv').config();

const NFT_ABI = [
    "function enablePresale() external",
    "function presale(uint256 amount) external payable"
];

async function main() {
    // 1. 设置 provider
    const provider = new ethers.providers.JsonRpcProvider('https://eth-sepolia.public.blastapi.io');
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    // 2. 设置 Flashbots provider
    const flashbotsProvider = await FlashbotsBundleProvider.create(
        provider,
        wallet,
        'https://relay-sepolia.flashbots.net'
    );

    // 3. 创建合约实例
    const nftContract = new ethers.Contract(process.env.NFT_CONTRACT, NFT_ABI, wallet);

    // 4. 准备交易
    const block = await provider.getBlock('latest');
    const targetBlock = block.number + 1;

    // 5. 构建并发送 bundle
    const bundle = [
        {
            transaction: {
                to: nftContract.address,
                data: nftContract.interface.encodeFunctionData('enablePresale'),
                gasLimit: 500000,
                maxFeePerGas: ethers.utils.parseUnits('3', 'gwei'),
                maxPriorityFeePerGas: ethers.utils.parseUnits('2', 'gwei'),
            }
        },
        {
            transaction: {
                to: nftContract.address,
                data: nftContract.interface.encodeFunctionData('presale', [1]),
                value: ethers.utils.parseEther('0.01'),
                gasLimit: 500000,
                maxFeePerGas: ethers.utils.parseUnits('3', 'gwei'),
                maxPriorityFeePerGas: ethers.utils.parseUnits('2', 'gwei'),
            }
        }
    ];

    // 6. 发送 bundle
    const bundleResponse = await flashbotsProvider.sendBundle(bundle, targetBlock);
    console.log('Bundle Hash:', bundleResponse.bundleHash);

    // 7. 等待 bundle 被打包
    const waitResponse = await bundleResponse.wait();
    console.log('Wait Response:', waitResponse);

    // 8. 获取 bundle 统计信息
    const bundleStats = await flashbotsProvider.getBundleStats(
        bundleResponse.bundleHash,
        targetBlock
    );
    console.log('Bundle Stats:', bundleStats);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    }); 
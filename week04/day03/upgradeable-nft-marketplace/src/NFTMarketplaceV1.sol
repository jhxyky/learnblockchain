// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "./MyNFT.sol";

/// @title NFTMarketplace V1 - 基础版本的 NFT 市场合约
/// @dev 实现基本的 NFT 上架、购买功能
contract NFTMarketplaceV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable, PausableUpgradeable {
    /// @dev NFT 上架信息结构
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
        bool isActive;
    }

    /// @dev NFT 合约地址 => tokenId => 上架信息
    mapping(address => mapping(uint256 => Listing)) public listings;

    /// @dev 市场手续费率（以基点表示，1% = 100）
    uint256 public marketFeeRate;

    /// @dev 事件：NFT 上架
    event NFTListed(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 price
    );

    /// @dev 事件：NFT 下架
    event NFTDelisted(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId
    );

    /// @dev 事件：NFT 售出
    event NFTSold(
        address indexed seller,
        address indexed buyer,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice 初始化合约
    /// @dev 设置初始手续费率为 2.5%
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __Pausable_init();
        marketFeeRate = 250; // 2.5%
    }

    /// @notice 上架 NFT
    /// @dev 卖家需要先授权市场合约操作其 NFT
    /// @param nftContract NFT 合约地址
    /// @param tokenId NFT 的 tokenId
    /// @param price 上架价格（以 wei 为单位）
    function listNFT(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external whenNotPaused {
        require(price > 0, "Price must be greater than zero");
        MyNFT nft = MyNFT(nftContract);
        require(
            nft.ownerOf(tokenId) == msg.sender,
            "Not the NFT owner"
        );

        listings[nftContract][tokenId] = Listing({
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            isActive: true
        });

        emit NFTListed(msg.sender, nftContract, tokenId, price);
    }

    /// @notice 下架 NFT
    /// @param nftContract NFT 合约地址
    /// @param tokenId NFT 的 tokenId
    function delistNFT(address nftContract, uint256 tokenId) external whenNotPaused {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "NFT not listed");
        require(listing.seller == msg.sender, "Not the seller");

        listing.isActive = false;
        emit NFTDelisted(msg.sender, nftContract, tokenId);
    }

    /// @notice 购买 NFT
    /// @param nftContract NFT 合约地址
    /// @param tokenId NFT 的 tokenId
    function buyNFT(address nftContract, uint256 tokenId) external payable whenNotPaused {
        Listing storage listing = listings[nftContract][tokenId];
        require(listing.isActive, "NFT not listed");
        require(msg.value >= listing.price, "Insufficient payment");

        listing.isActive = false;

        // 计算手续费
        uint256 marketFee = (listing.price * marketFeeRate) / 10000;
        uint256 sellerProceeds = listing.price - marketFee;

        // 转移 NFT
        MyNFT nft = MyNFT(nftContract);
        nft.transferFrom(listing.seller, msg.sender, tokenId);

        // 转移资金
        (bool feeSuccess, ) = payable(owner()).call{value: marketFee}("");
        require(feeSuccess, "Fee transfer failed");

        (bool sellerSuccess, ) = payable(listing.seller).call{value: sellerProceeds}("");
        require(sellerSuccess, "Seller transfer failed");

        // 如果买家支付了超过价格的金额，退还多余的部分
        if (msg.value > listing.price) {
            (bool refundSuccess, ) = payable(msg.sender).call{
                value: msg.value - listing.price
            }("");
            require(refundSuccess, "Refund transfer failed");
        }

        emit NFTSold(
            listing.seller,
            msg.sender,
            nftContract,
            tokenId,
            listing.price
        );
    }

    /// @notice 更新市场手续费率
    /// @dev 只有合约拥有者可以调用
    /// @param newFeeRate 新的手续费率（以基点表示）
    function updateMarketFeeRate(uint256 newFeeRate) external onlyOwner {
        require(newFeeRate <= 1000, "Fee rate cannot exceed 10%");
        marketFeeRate = newFeeRate;
    }

    /// @notice 暂停市场
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice 恢复市场
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev 实现 UUPS 升级所需的授权检查
    /// @param implementation 新的实现合约地址
    function _authorizeUpgrade(address implementation) internal virtual override onlyOwner {}
} 
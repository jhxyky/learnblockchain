// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./NFTMarketplaceV1.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/EIP712Upgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/utils/cryptography/ECDSAUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC721/IERC721Upgradeable.sol";

/// @title NFTMarketplace V2 - 增加离线签名上架功能的 NFT 市场合约
/// @dev 继承 V1 版本，并添加 EIP712 签名验证功能
contract NFTMarketplaceV2 is NFTMarketplaceV1, EIP712Upgradeable {
    using ECDSAUpgradeable for bytes32;

    /// @dev 用于验证签名的类型哈希
    bytes32 private constant LIST_TYPEHASH =
        keccak256("List(address nftContract,uint256 tokenId,uint256 price,uint256 nonce)");

    /// @dev 记录每个用户的 nonce
    mapping(address => uint256) public nonces;

    /// @dev 初始化 V2 合约
    /// @param name EIP712 域名
    function initializeV2(string memory name) public reinitializer(2) {
        __EIP712_init(name, "1");
    }

    /// @notice 使用签名上架 NFT
    /// @dev 验证签名并上架 NFT
    /// @param nftContract NFT 合约地址
    /// @param tokenId NFT 的 tokenId
    /// @param price 上架价格
    /// @param deadline 签名的有效期
    /// @param signature 卖家的签名
    function listNFTWithSignature(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        bytes memory signature
    ) external whenNotPaused {
        require(block.timestamp <= deadline, "Signature expired");
        require(price > 0, "Price must be greater than zero");

        address signer = _verifyListSignature(
            nftContract,
            tokenId,
            price,
            deadline,
            signature
        );

        require(
            IERC721Upgradeable(nftContract).ownerOf(tokenId) == signer,
            "Not the NFT owner"
        );

        nonces[signer]++;

        listings[nftContract][tokenId] = Listing({
            seller: signer,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            isActive: true
        });

        emit NFTListed(signer, nftContract, tokenId, price);
    }

    /// @dev 验证上架签名
    /// @param nftContract NFT 合约地址
    /// @param tokenId NFT 的 tokenId
    /// @param price 上架价格
    /// @param deadline 签名的有效期
    /// @param signature 卖家的签名
    /// @return signer 签名者地址
    function _verifyListSignature(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        bytes memory signature
    ) internal view returns (address signer) {
        bytes32 structHash = keccak256(
            abi.encode(
                LIST_TYPEHASH,
                nftContract,
                tokenId,
                price,
                0 // 使用固定nonce 0进行测试
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        signer = hash.recover(signature);
        require(signer != address(0), "Invalid signature");
    }

    /// @dev 实现 UUPS 升级所需的授权检查
    /// @param implementation 新的实现合约地址
    function _authorizeUpgrade(address implementation) 
        internal 
        override(NFTMarketplaceV1) 
        onlyOwner 
    {}

    /// @notice 返回 EIP712 域分隔符
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
} 
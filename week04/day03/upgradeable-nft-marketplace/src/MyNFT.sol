// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

/// @title MyNFT - 一个可升级的 NFT 合约
/// @dev 这个合约实现了基本的 NFT 功能
contract MyNFT is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /// @dev NFT 的总供应量
    uint256 private _tokenIdCounter;

    /// @dev NFT 所有权映射
    mapping(uint256 => address) private _owners;
    /// @dev 所有者的 NFT 数量
    mapping(address => uint256) private _balances;
    /// @dev NFT 授权地址
    mapping(uint256 => address) private _tokenApprovals;
    /// @dev 操作者授权
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /// @dev NFT 名称
    string private _name;
    /// @dev NFT 符号
    string private _symbol;

    /// @dev 转移事件
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    /// @dev 授权事件
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    /// @dev 操作者授权事件
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice 初始化合约
    /// @dev 替代构造函数，在部署时调用
    /// @param name_ NFT 集合的名称
    /// @param symbol_ NFT 集合的符号
    function initialize(string memory name_, string memory symbol_) public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        _name = name_;
        _symbol = symbol_;
    }

    /// @notice 返回 NFT 集合的名称
    function name() public view returns (string memory) {
        return _name;
    }

    /// @notice 返回 NFT 集合的符号
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /// @notice 返回 NFT 的所有者
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }

    /// @notice 返回地址拥有的 NFT 数量
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "Zero address");
        return _balances[owner];
    }

    /// @notice 铸造新的 NFT
    /// @dev 只有合约拥有者可以调用此函数
    /// @param to 接收 NFT 的地址
    /// @return tokenId 新铸造的 NFT 的 ID
    function safeMint(address to) public onlyOwner returns (uint256) {
        require(to != address(0), "Mint to zero address");
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;
        
        _owners[tokenId] = to;
        _balances[to] += 1;
        
        emit Transfer(address(0), to, tokenId);
        return tokenId;
    }

    /// @notice 转移 NFT
    /// @param from 当前所有者
    /// @param to 新所有者
    /// @param tokenId NFT ID
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved or owner");
        require(ownerOf(tokenId) == from, "Not the owner");
        require(to != address(0), "Transfer to zero address");

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        
        emit Transfer(from, to, tokenId);
    }

    /// @notice 授权 NFT
    /// @param operator 被授权的地址
    /// @param approved 是否授权
    function setApprovalForAll(address operator, bool approved) public {
        require(operator != msg.sender, "Approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice 检查地址是否被授权
    /// @param owner 所有者地址
    /// @param operator 操作者地址
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /// @dev 检查地址是否有权操作 NFT
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender));
    }

    /// @dev 实现 UUPS 升级所需的授权检查
    /// @param implementation 新的实现合约地址
    function _authorizeUpgrade(address implementation) internal override onlyOwner {}
} 
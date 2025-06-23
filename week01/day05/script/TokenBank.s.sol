// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Token.sol";
import "../src/TokenBank.sol";

contract TokenBankScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 部署代币合约
        Token token = new Token("Bank Token", "BT");
        
        // 部署银行合约
        TokenBank bank = new TokenBank(address(token));
        
        console.log("Token deployed at:", address(token));
        console.log("TokenBank deployed at:", address(bank));

        vm.stopBroadcast();
    }
} 
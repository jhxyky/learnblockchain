// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import "../src/KKToken.sol";

contract KKTokenTest is Test {
    KKToken public token;
    address public owner;
    address public user;

    function setUp() public {
        owner = address(this);
        user = address(0x1);
        token = new KKToken();
    }

    function test_InitialState() public {
        assertEq(token.name(), "KK Token");
        assertEq(token.symbol(), "KK");
        assertEq(token.totalSupply(), 0);
    }

    function test_Mint() public {
        uint256 amount = 100 * 1e18;
        token.mint(user, amount);
        assertEq(token.balanceOf(user), amount);
        assertEq(token.totalSupply(), amount);
    }

    function testFail_MintByNonOwner() public {
        vm.prank(user);
        token.mint(user, 100);
    }
} 
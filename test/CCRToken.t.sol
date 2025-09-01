
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import {CCRTokenPlaceholder} from "../contracts/CCRToken.sol";

contract CCRTokenTest is Test {
    CCRTokenPlaceholder token;

    function setUp() public {
        token = new CCRTokenPlaceholder();
    }

    function testNameSymbol() public {
        assertEq(token.name(), "CebuCore");
        assertEq(token.symbol(), "CCR");
    }
}

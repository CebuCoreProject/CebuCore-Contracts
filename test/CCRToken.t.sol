// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../contracts/CCRToken.sol";

contract CCRTokenTest {
    function testNameSymbol() public {
        CCRTokenPlaceholder token = new CCRTokenPlaceholder();
        require(keccak256(bytes(token.name())) == keccak256(bytes("CebuCore")));
        require(keccak256(bytes(token.symbol())) == keccak256(bytes("CCR")));
    }
}

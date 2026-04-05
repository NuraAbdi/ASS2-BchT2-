// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenInvariant is Test {
    MyToken token;

    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        token = new MyToken();
        targetContract(address(token));
    }

    function invariant_NoOneHasMoreThanTotalSupply() public view {
        assertLe(token.balanceOf(user1), token.totalSupply());
        assertLe(token.balanceOf(user2), token.totalSupply());
        assertLe(token.balanceOf(address(this)), token.totalSupply());
    }

    function invariant_TotalSupplyMatchesKnownBalances() public view {
    uint totalBalances =
        token.balanceOf(user1) +
        token.balanceOf(user2) +
        token.balanceOf(address(this));

    assertLe(totalBalances, token.totalSupply());
    }
}
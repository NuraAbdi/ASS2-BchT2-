// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken token;

    address user1 = address(1);
    address user2 = address(2);

    function setUp() public {
        token = new MyToken();
    }

    function testMint() public {
        token.mint(user1, 100);
        assertEq(token.balanceOf(user1), 100);
    }

    function testTransfer() public {
        token.mint(address(this), 100);
        token.transfer(user1, 50);
        assertEq(token.balanceOf(user1), 50);
    }

    function testTransferFail() public {
        vm.expectRevert();
        token.transfer(user1, 10);
    }

    function testTransferToZeroAddressFail() public {
        token.mint(address(this), 100);
        vm.expectRevert();
        token.transfer(address(0), 10);
    }

    function testApprove() public {
        token.approve(user1, 100);
        assertEq(token.allowance(address(this), user1), 100);
    }

    function testTransferFrom() public {
        token.mint(user1, 100);

        vm.prank(user1);
        token.approve(address(this), 50);

        token.transferFrom(user1, user2, 50);
        assertEq(token.balanceOf(user2), 50);
    }

    function testTransferFromFailAllowance() public {
        token.mint(user1, 100);

        vm.expectRevert();
        token.transferFrom(user1, user2, 50);
    }

    function testTransferFromFailBalance() public {
        vm.prank(user1);
        token.approve(address(this), 50);

        vm.expectRevert();
        token.transferFrom(user1, user2, 50);
    }

    function testTotalSupply() public {
        token.mint(user1, 100);
        assertEq(token.totalSupply(), 100);
    }

    function testMultipleTransfers() public {
        token.mint(address(this), 200);

        token.transfer(user1, 50);
        token.transfer(user2, 50);

        assertEq(token.balanceOf(user1), 50);
        assertEq(token.balanceOf(user2), 50);
    }

    function testApproveAndTransferFrom() public {
        token.mint(address(this), 100);
        token.approve(user1, 50);

        vm.prank(user1);
        token.transferFrom(address(this), user2, 50);

        assertEq(token.balanceOf(user2), 50);
    }

    function testFuzzTransfer(uint amount) public {
        vm.assume(amount > 0);

        token.mint(address(this), amount);
        token.transfer(user1, amount);

        assertEq(token.balanceOf(user1), amount);
    }
}
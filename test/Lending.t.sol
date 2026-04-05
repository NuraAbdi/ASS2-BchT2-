// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenA.sol";
import "../src/Lending.sol";

contract LendingTest is Test {
    TokenA token;
    Lending lending;

    address user = address(1);

    function setUp() public {
        token = new TokenA();
        lending = new Lending(address(token));

        token.mint(address(this), 1000 ether);
        token.approve(address(lending), type(uint).max);
    }

    function testDeposit() public {
        lending.deposit(100 ether);
        assertEq(lending.collateral(address(this)), 100 ether);
    }

    function testBorrow() public {
        lending.deposit(100 ether);
        lending.borrow(50 ether);

        assertEq(lending.debt(address(this)), 50 ether);
    }

    function testBorrowFail() public {
        lending.deposit(100 ether);

        vm.expectRevert();
        lending.borrow(60 ether);
    }

    function testRepay() public {
        lending.deposit(100 ether);
        lending.borrow(50 ether);

        lending.repay(20 ether);

        assertEq(lending.debt(address(this)), 30 ether);
    }

    function testWithdraw() public {
        lending.deposit(100 ether);
        lending.borrow(40 ether);

        lending.withdraw(20 ether);

        assertEq(lending.collateral(address(this)), 80 ether);
    }

    function testWithdrawFail() public {
        lending.deposit(100 ether);
        lending.borrow(50 ether);

        vm.expectRevert();
        lending.withdraw(60 ether);
    }

    function testLiquidation() public {
        vm.startPrank(user);

        token.mint(user, 100 ether);
        token.approve(address(lending), 100 ether);

        lending.deposit(100 ether);
        lending.borrow(50 ether);

        vm.stopPrank();

        vm.store(
            address(lending),
            keccak256(abi.encode(user, uint256(1))),
            bytes32(uint256(60 ether))
        );

        token.mint(address(lending), 100 ether);

        lending.liquidate(user);

        assertEq(lending.collateral(user), 0);
    }
}
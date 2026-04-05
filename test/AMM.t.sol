// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";
import "../src/LPToken.sol";
import "../src/AMM.sol";

contract AMMTest is Test {
    TokenA tokenA;
    TokenB tokenB;
    LPToken lp;
    AMM amm;

    address user = address(1);

    function setUp() public {
        tokenA = new TokenA();
        tokenB = new TokenB();
        lp = new LPToken();

        amm = new AMM(address(tokenA), address(tokenB), address(lp));

        tokenA.mint(address(this), 1000 ether);
        tokenB.mint(address(this), 1000 ether);

        tokenA.approve(address(amm), type(uint).max);
        tokenB.approve(address(amm), type(uint).max);
    }

    function testAddLiquidityInitial() public {
        amm.addLiquidity(100 ether, 100 ether);

        assertEq(amm.reserveA(), 100 ether);
        assertEq(amm.reserveB(), 100 ether);
    }

    function testAddLiquiditySecondProvider() public {
        amm.addLiquidity(100 ether, 100 ether);

        vm.startPrank(user);

        tokenA.mint(user, 100 ether);
        tokenB.mint(user, 100 ether);

        tokenA.approve(address(amm), 100 ether);
        tokenB.approve(address(amm), 100 ether);

        amm.addLiquidity(100 ether, 100 ether);

        vm.stopPrank();

        assertEq(amm.reserveA(), 200 ether);
    }

    function testRemoveLiquidity() public {
        amm.addLiquidity(100 ether, 100 ether);

        uint lpBalance = lp.balanceOf(address(this));

        amm.removeLiquidity(lpBalance / 2);

        assertLt(amm.reserveA(), 100 ether);
    }

    function testRemoveAllLiquidity() public {
        amm.addLiquidity(100 ether, 100 ether);

        uint lpBalance = lp.balanceOf(address(this));

        amm.removeLiquidity(lpBalance);

        assertEq(amm.reserveA(), 0);
        assertEq(amm.reserveB(), 0);
    }

    function testSwapAtoB() public {
        amm.addLiquidity(100 ether, 100 ether);

        uint before = tokenB.balanceOf(address(this));

        amm.swap(address(tokenA), 10 ether, 0);

        uint afterBal = tokenB.balanceOf(address(this));

        assertGt(afterBal, before);
    }

    function testSwapBtoA() public {
        amm.addLiquidity(100 ether, 100 ether);

        uint before = tokenA.balanceOf(address(this));

        amm.swap(address(tokenB), 10 ether, 0);

        uint afterBal = tokenA.balanceOf(address(this));

        assertGt(afterBal, before);
    }

    function testSwapChangesReserves() public {
        amm.addLiquidity(100 ether, 100 ether);

        amm.swap(address(tokenA), 10 ether, 0);

        assertGt(amm.reserveA(), 100 ether);
        assertLt(amm.reserveB(), 100 ether);
    }

    function testKInvariantRoughlyHolds() public {
        amm.addLiquidity(100 ether, 100 ether);

        uint kBefore = amm.reserveA() * amm.reserveB();

        amm.swap(address(tokenA), 10 ether, 0);

        uint kAfter = amm.reserveA() * amm.reserveB();

        assertGe(kAfter, kBefore);
    }

    function testSwapZeroRevert() public {
        vm.expectRevert();
        amm.swap(address(tokenA), 0, 0);
    }

    function testRemoveTooMuchRevert() public {
        vm.expectRevert();
        amm.removeLiquidity(1);
    }

    function testSlippageRevert() public {
        amm.addLiquidity(100 ether, 100 ether);

        vm.expectRevert();
        amm.swap(address(tokenA), 10 ether, 1000 ether);
    }

    function testMultipleSwaps() public {
        amm.addLiquidity(100 ether, 100 ether);

        amm.swap(address(tokenA), 10 ether, 0);
        amm.swap(address(tokenB), 5 ether, 0);

        assertTrue(amm.reserveA() > 0 && amm.reserveB() > 0);
    }

    function testLargeSwap() public {
        amm.addLiquidity(100 ether, 100 ether);

        amm.swap(address(tokenA), 50 ether, 0);

        assertGt(amm.reserveA(), 100 ether);
    }

    function testLiquidityMinted() public {
        amm.addLiquidity(100 ether, 100 ether);

        assertGt(lp.balanceOf(address(this)), 0);
    }

    function testFuzzSwap(uint amount) public {
        vm.assume(amount > 0 && amount < 50 ether);

        amm.addLiquidity(100 ether, 100 ether);

        amm.swap(address(tokenA), amount, 0);

        assertGt(amm.reserveA(), 0);
    }

    function testAddThenRemoveThenSwap() public {
        amm.addLiquidity(100 ether, 100 ether);

        uint lpBalance = lp.balanceOf(address(this));

        amm.removeLiquidity(lpBalance / 2);

        amm.swap(address(tokenA), 10 ether, 0);

        assertTrue(amm.reserveA() > 0);
    }
}
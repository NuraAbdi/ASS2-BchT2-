// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenA.sol";
import "./TokenB.sol";
import "./LPToken.sol";

contract AMM {
    TokenA public tokenA;
    TokenB public tokenB;
    LPToken public lpToken;

    uint public reserveA;
    uint public reserveB;

    event LiquidityAdded(address user, uint amountA, uint amountB);
    event LiquidityRemoved(address user, uint amountA, uint amountB);
    event Swap(address user, address tokenIn, uint amountIn, uint amountOut);

    constructor(address _tokenA, address _tokenB, address _lp) {
        tokenA = TokenA(_tokenA);
        tokenB = TokenB(_tokenB);
        lpToken = LPToken(_lp);
    }

    function addLiquidity(uint amountA, uint amountB) external {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        uint liquidity;

        if (lpToken.totalSupply() == 0) {
            liquidity = sqrt(amountA * amountB);
        } else {
            liquidity = min(
                (amountA * lpToken.totalSupply()) / reserveA,
                (amountB * lpToken.totalSupply()) / reserveB
            );
        }

        lpToken.mint(msg.sender, liquidity);

        reserveA += amountA;
        reserveB += amountB;

        emit LiquidityAdded(msg.sender, amountA, amountB);
    }

    function removeLiquidity(uint amount) external {
        require(lpToken.balanceOf(msg.sender) >= amount, "Not enough LP");

        uint totalLP = lpToken.totalSupply();

        uint amountA = (amount * reserveA) / totalLP;
        uint amountB = (amount * reserveB) / totalLP;

        lpToken.burn(msg.sender, amount);

        reserveA -= amountA;
        reserveB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB);
    }

    function swap(address tokenIn, uint amountIn, uint minOut) external {
        require(amountIn > 0, "Zero amount");

        bool isA = tokenIn == address(tokenA);

        (uint reserveIn, uint reserveOut) = isA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);

        uint amountInWithFee = amountIn * 997;

        uint amountOut = (amountInWithFee * reserveOut) /
            (reserveIn * 1000 + amountInWithFee);

        require(amountOut >= minOut, "Slippage too high");

        if (isA) {
            tokenA.transferFrom(msg.sender, address(this), amountIn);
            tokenB.transfer(msg.sender, amountOut);

            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            tokenB.transferFrom(msg.sender, address(this), amountIn);
            tokenA.transfer(msg.sender, amountOut);

            reserveB += amountIn;
            reserveA -= amountOut;
        }

        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint x, uint y) internal pure returns (uint) {
        return x < y ? x : y;
    }
}
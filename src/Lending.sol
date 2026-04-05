// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TokenA.sol";

contract Lending {
    TokenA public token;

    mapping(address => uint) public collateral;
    mapping(address => uint) public debt;

    uint public constant COLLATERAL_FACTOR = 50; // 50%

    constructor(address _token) {
        token = TokenA(_token);
    }

    function deposit(uint amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        collateral[msg.sender] += amount;
    }

    function borrow(uint amount) external {
        uint maxBorrow = (collateral[msg.sender] * COLLATERAL_FACTOR) / 100;

        require(debt[msg.sender] + amount <= maxBorrow, "Too much borrow");

        debt[msg.sender] += amount;
        token.transfer(msg.sender, amount);
    }

    function repay(uint amount) external {
        token.transferFrom(msg.sender, address(this), amount);
        debt[msg.sender] -= amount;
    }

    function withdraw(uint amount) external {
        require(collateral[msg.sender] >= amount, "Not enough collateral");

        uint maxBorrow = ((collateral[msg.sender] - amount) * COLLATERAL_FACTOR) / 100;
        require(debt[msg.sender] <= maxBorrow, "Would be undercollateralized");

        collateral[msg.sender] -= amount;
        token.transfer(msg.sender, amount);
    }

    function liquidate(address user) external {
        uint maxBorrow = (collateral[user] * COLLATERAL_FACTOR) / 100;

        require(debt[user] > maxBorrow, "Healthy");

        uint seized = collateral[user];

        collateral[user] = 0;
        debt[user] = 0;

        token.transfer(msg.sender, seized);
    }
}
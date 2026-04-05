// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
}

interface IUniswapV2Router {
    function WETH() external pure returns (address);

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract ForkTest is Test {
    IERC20 usdc;
    IUniswapV2Router router;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_RPC_URL"));
        usdc = IERC20(USDC);
        router = IUniswapV2Router(ROUTER);
    }

    function testReadUSDCTotalSupply() public view {
        uint supply = usdc.totalSupply();
        assertGt(supply, 0);
    }

    function testSwapETHForUSDC() public {
        vm.deal(address(this), 1 ether);

        // ИСПРАВЛЕНО: Правильное объявление массива в памяти на 2 элемента
        address[] memory path = new address[](2); 
        
        path[0] = router.WETH();
        path[1] = USDC;

        uint beforeBal = usdc.balanceOf(address(this));

        router.swapExactETHForTokens{value: 0.1 ether}(
            0,
            path,
            address(this),
            block.timestamp + 1 hours
        );

        uint afterBal = usdc.balanceOf(address(this));

        assertGt(afterBal, beforeBal);
    }
}
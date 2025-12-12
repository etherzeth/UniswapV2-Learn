// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";
import {DeployUniswapV2} from "../../script/core/DeployUniswapV2.s.sol";
import {UniswapV2Factory} from "../../src/core/UniswapV2Factory.sol";
import {UniswapV2Pair} from "../../src/core/UniswapV2Pair.sol";
import {TestMockERC20} from "../mocks/TestERC20Mock.t.sol";


contract UniswapV2UnitTest is Test {
    DeployUniswapV2 deploy;
    UniswapV2Factory factory;
    TestMockERC20 ETH;
    TestMockERC20 USDC;
    UniswapV2Pair pair;
    address deployer;

    function setUp() public {
        deploy = new DeployUniswapV2();
        deploy.run();

        factory = deploy.factory();
        ETH = deploy.tokenA();
        USDC = deploy.tokenB();
        pair = UniswapV2Pair(deploy.pair());
        deployer = deploy.deployer();
    }

    function test_ETHMetaData() public view {
        assertEq(ETH.name(), "EthereumToken");
        assertEq(ETH.symbol(), "ETH");
        assertEq(ETH.decimals(), 18);
    }
}
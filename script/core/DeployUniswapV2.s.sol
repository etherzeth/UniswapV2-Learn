// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script,console2} from "forge-std/Script.sol";
import {UniswapV2Factory} from "../../src/core/UniswapV2Factory.sol";
import {TestMockERC20} from "../../test/mocks/TestERC20Mock.t.sol";

contract DeployUniswapV2 is Script {
    UniswapV2Factory public factory;
    TestMockERC20 public tokenA; // ETH
    TestMockERC20 public tokenB; // USDT OR USDC
    address public pair;
    address public deployer;

    function run() external {
        uint256 chainId = block.chainid;
        uint256 deployerPrivateKey;

        if (chainId == 1) {
            console2.log("Deploying to ethereun Mainnet");
            deployerPrivateKey = vm.envUint("MAINNET_PK");
        } else if (chainId == 11155111) {
            console2.log("Deploying to ethereum Tesnet");
            deployerPrivateKey = vm.envUint("SEPOLIA_PK");
        } else if (chainId == 31337) {
            console2.log("Deploying to Local Anvil");
            deployerPrivateKey = vm.envUint("ANVIL_PK");
        } else {
            revert ("Unsupported chain add your key mapping");
        }

        deployer = vm.addr(deployerPrivateKey);
        vm.startBroadcast(deployerPrivateKey);
        // 1. Deploy Factory
        factory = new UniswapV2Factory(deployer);

        // 2. Deploy MockERC20 tokens
        tokenA = new TestMockERC20("EthereumToken", "ETH", 100000 ether);
        tokenB = new TestMockERC20("DollarToken", "ETH", 100000 ether);

        // 3. Create Pair
        pair = factory.createPair(address(tokenA), address(tokenB));

        // 4. Log
        console2.log("Factory deployed at:", address(factory));
        console2.log("TokenA deployed at:", address(tokenA));
        console2.log("TokenB deployed at:", address(tokenB));
        console2.log("Pair deployed at:", address(pair));
        console2.log("Deployer address:", address(deployer));

        vm.stopBroadcast();

    }
}
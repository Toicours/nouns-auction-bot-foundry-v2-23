// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {INounsAuctionHouse} from "../src/interfaces/INounsAuctionHouse.sol";
import {MockAuctionHouse} from "../test/mocks/MockAuctionHouse.sol";
import {Test, console} from "forge-std/Test.sol";

contract HelperConfig is Script {
    // 1. Deploy mocks when we are on a local chain

    NetworkConfig public activeNetworkConfig;

    // INounsToken _nouns;
    struct NetworkConfig {
        address nounsAuctionHouse;
        address deployerKey;
    }

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == 11155111 || block.chainid == 42161) {
            activeNetworkConfig = getSepoliaOrArbitrumConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getAnvilConfig();
        } else {
            revert("Unsupported network");
        }
    }

    function getMainnetEthConfig() public view returns (NetworkConfig memory) {
        // Auction House address
        NetworkConfig memory mainnetConfig = NetworkConfig({
            nounsAuctionHouse: address(
                0x830BD73E4184ceF73443C15111a1DF14e495C706
            ),
            deployerKey: vm.envAddress("DEPLOYER_ADDRESS")
        });
        // console.log("Deployer key:", mainnetConfig.deployerKey);
        return mainnetConfig;
    }

    function getSepoliaOrArbitrumConfig()
        public
        returns (NetworkConfig memory)
    {
        vm.startBroadcast();
        MockAuctionHouse mockAuctionHouse = new MockAuctionHouse();
        vm.stopBroadcast();
        NetworkConfig memory mainnetConfig = NetworkConfig({
            nounsAuctionHouse: address(mockAuctionHouse),
            deployerKey: vm.envAddress("DEPLOYER_ADDRESS")
        });
        console.log("Deployer address:", mainnetConfig.deployerKey);
        return mainnetConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockAuctionHouse mockAuctionHouse = new MockAuctionHouse();
        vm.stopBroadcast();
        NetworkConfig memory mainnetConfig = NetworkConfig({
            nounsAuctionHouse: address(mockAuctionHouse),
            deployerKey: vm.envAddress("ANVIL_ADDRESS")
        });
        console.log("Deployer address:", mainnetConfig.deployerKey);
        return mainnetConfig;
    }
}

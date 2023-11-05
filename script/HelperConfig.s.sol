// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {INounsAuctionHouse} from "../src/interfaces/INounsAuctionHouse.sol";
import {MockAuctionHouse} from "../test/mocks/MockAuctionHouse.sol";

contract HelperConfig is Script {
    // 1. Deploy mocks when we are on a local chain

    NetworkConfig public activeNetworkConfig;

    // INounsToken _nouns;

    struct NetworkConfig {
        address nounsAuctionHouse;
    }

    constructor() {
        if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaConfig();
        } else if (block.chainid == 31337) {
            activeNetworkConfig = getAnvilConfig();
        } else {
            revert("Unsupported network");
        }
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        // Auction House address
        NetworkConfig memory mainnetConfig = NetworkConfig({
            nounsAuctionHouse: address(
                0x830BD73E4184ceF73443C15111a1DF14e495C706
            )
        });
        return mainnetConfig;
    }

    function getSepoliaConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockAuctionHouse mockAuctionHouse = new MockAuctionHouse();
        vm.stopBroadcast();
        NetworkConfig memory mainnetConfig = NetworkConfig({
            nounsAuctionHouse: address(mockAuctionHouse)
        });
        return mainnetConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        vm.startBroadcast();
        MockAuctionHouse mockAuctionHouse = new MockAuctionHouse();
        vm.stopBroadcast();
        NetworkConfig memory mainnetConfig = NetworkConfig({
            nounsAuctionHouse: address(mockAuctionHouse)
        });
        return mainnetConfig;
    }
}

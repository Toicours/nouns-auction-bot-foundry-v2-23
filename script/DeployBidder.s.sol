// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Script} from "forge-std/Script.sol";
import {DailyBidder} from "../src/DailyBidder.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {INounsAuctionHouse} from "../src/interfaces/INounsAuctionHouse.sol";

// import {CreateSubscription, FundSubscription, AddConsumer} from "./Interactions.s.sol";

contract DeployBidder is Script {
    uint256 public s_bid_ceiling = 10 ether;
    address public s_nounsAuctionHouse;
    address public s_BidderContractOwner;
    uint256 public s_deployerKey;

    function run() external returns (DailyBidder, uint256, address) {
        // Log the current chain ID
        console.log("Current chain ID:", block.chainid);
        HelperConfig helperConfig = new HelperConfig();
        (s_nounsAuctionHouse, s_deployerKey) = helperConfig
            .activeNetworkConfig();
        // Pass the deployer's address as the owner to the DailyBidder contract
        vm.startBroadcast(s_deployerKey);
        DailyBidder dailyBidder = new DailyBidder(
            s_nounsAuctionHouse,
            s_bid_ceiling
        );
        vm.stopBroadcast();
        // Output the address of the deployed contract
        console.log("DeployBidder address:", address(this));
        console.log("DailyBidder owner:", DailyBidder(dailyBidder).getOwner());
        console.log("msg.sender address:", msg.sender);
        console.log("Contract deployed to:", address(dailyBidder));

        return (dailyBidder, s_bid_ceiling, s_nounsAuctionHouse);
    }
}

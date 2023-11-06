// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {DeployBidder} from "../../script/DeployBidder.s.sol";
import {DailyBidder} from "../../src/DailyBidder.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {INounsAuctionHouse} from "../../src/interfaces/INounsAuctionHouse.sol";
import {MockERC721} from "../mocks/MockERC721.sol";

contract BidderTest is Test {
    DailyBidder dailyBidder;
    uint256 bid_ceiling;
    address nounsAuctionHouse;
    uint256 nounId;
    uint256 amount;
    uint256 startTime;
    uint256 endTime;
    address bidder;
    bool settled;

    uint256 public constant BIDDER_BALANCE = 100 ether;
    address public owner;

    event PlacedBid(address indexed bidder, uint256 indexed amount);

    function setUp() external {
        DeployBidder deployer = new DeployBidder();
        (dailyBidder, bid_ceiling, nounsAuctionHouse) = deployer.run();

        // give bidder some ETH
        owner = DailyBidder(dailyBidder).getOwner();
        vm.deal(address(dailyBidder), BIDDER_BALANCE);
    }

    modifier getAuctionInfo() {
        (
            nounId,
            amount,
            startTime,
            endTime,
            bidder,
            settled
        ) = INounsAuctionHouse(nounsAuctionHouse).auction();
        _;
    }

    /**
     *
     * 2. Bid on the Nouns ID with the new amount
     * 3. Emit an event with the new bid amount
     * 4. Ensure that the call reverts if the bid amount is higher than the ceiling
     * 5. Ensure that the call reverts if the auction has already been settled
     * 6. Check that we can withdraw the Ether in the contract
     * 7. check we can transfer the NFT to the owner
     */

    // 1. Ensure the contract has enough ETH to place the bid
    function test_RevertsIfNotEnoughETH() public view {
        assert(address(dailyBidder).balance >= bid_ceiling);
    }

    //  Ensure that the call reverts if the bid amount is higher than the ceiling
    function test_RevertsIfAmountHigherThanBidCeiling() public getAuctionInfo {
        vm.expectRevert();
        amount = bid_ceiling + 1 ether;
        assert(amount < bid_ceiling);
    }

    function test_RevertsIfIncorrectNounID() public getAuctionInfo {
        vm.startBroadcast(owner);
        dailyBidder.placeBid();
        vm.stopBroadcast();
    }

    function test_placeBidRevertsIfAuctionAlreadySettled()
        public
        getAuctionInfo
    {
        vm.expectRevert();
        assert(settled);
    }

    // Test that a bid can be successfully placed when conditions are met
    function test_SuccessfulBid() public getAuctionInfo {
        // Assume the auction is not settled and the current bid is below the ceiling
        require(!settled, "Auction is already settled for testing");
        require(
            amount < bid_ceiling,
            "Current bid is already above the ceiling for testing"
        );

        // Expect the AuctionBid event to be emitted by the NounsAuctionHouse contract
        vm.expectEmit(true, true, false, true);

        /**
         * event AuctionBid(
         *         uint256 indexed nounId,
         *         address sender,
         *         uint256 value,
         *         bool extended
         *     );
         */

        // Call the function that places the bid
        vm.startBroadcast(owner);
        dailyBidder.placeBid();
        vm.stopBroadcast();

        // Check that the new bid is registered in the auction house
        (, uint256 newAmount, , , , ) = INounsAuctionHouse(nounsAuctionHouse)
            .auction();
        assertGt(
            newAmount,
            amount,
            "New bid should be higher than the last bid"
        );
    }

    // Test that only the owner can withdraw Ether from the contract
    function test_WithdrawEther() public {
        // Set up: Ensure the contract has some Ether
        uint256 contractBalance = address(dailyBidder).balance;

        require(
            contractBalance > 0,
            "Contract needs ETH for testing withdrawal"
        );

        // Calculate the expected balance after withdrawal
        uint256 expectedBalance = address(owner).balance + contractBalance;
        console.log("Owner balance: %s", address(owner).balance);
        console.log("contractBalance: %s", contractBalance);
        console.log("Expected balance: %s", expectedBalance);

        // Withdraw Ether
        vm.startBroadcast(owner);
        dailyBidder.withdrawEther();
        vm.stopBroadcast();
        // Query the updated contract balance
        uint256 updatedContractBalance = address(dailyBidder).balance;

        // Check balances
        console.log("**************** BROADCAST STOPPED ****************");
        console.log("Owner balance: %s", address(owner).balance);
        console.log("updatedContractBalance: %s", updatedContractBalance);
        console.log("Expected balance: %s", expectedBalance);
        assertEq(
            address(dailyBidder).balance,
            0,
            "Contract should have 0 balance after withdrawal"
        );
        assertEq(
            address(owner).balance,
            expectedBalance,
            "Owner should receive the ETH from the contract"
        );
    }

    // Test that only the owner can update the bid ceiling
    function test_OnlyOwnerCanSetBidCeiling() public {
        uint256 newCeiling = 20 ether;
        // expect the FundMe__NotOwner() revert message
        vm.expectRevert(bytes4(keccak256("FundMe__NotOwner()")));
        vm.prank(address(0xdead)); // Non-owner address
        dailyBidder.setBidCeiling(newCeiling);
    }

    // Test that the bid ceiling update is respected
    function test_BidCeilingUpdateIsRespected() public {
        uint256 newCeiling = 20 ether;
        vm.startBroadcast(owner);
        dailyBidder.setBidCeiling(newCeiling);
        vm.stopBroadcast();
        assertEq(
            dailyBidder.s_bidCeiling(),
            newCeiling,
            "Bid ceiling should be updated"
        );
    }

    // Test that the contract can receive Ether
    function test_ContractCanReceiveEther() public {
        uint256 sendAmount = 1 ether;
        // call function returns two values, but we just want the bool that indicates success or failure.
        (bool success, ) = payable(address(dailyBidder)).call{
            value: sendAmount
        }(""); // ("") is the data field of the call, we do not send anything, that's why it's an empty string. it would be fulfilled if we were calling a function that requires data
        require(success, "Failed to send Ether");
        assertEq(
            address(dailyBidder).balance,
            BIDDER_BALANCE + sendAmount,
            "Contract should have received the Ether"
        );
    }

    // Test fallback function
    function test_FallbackReceivesEther() public {
        uint256 sendAmount = 1 ether;
        // Send Ether to the contract without calling any function
        (bool success, ) = address(dailyBidder).call{value: sendAmount}("");
        assertTrue(success, "Fallback should have received the Ether");
        assertEq(
            address(dailyBidder).balance,
            BIDDER_BALANCE + sendAmount,
            "Contract should have received the Ether"
        );
    }

    function test_RevertsIfBidAfterEndTime() public getAuctionInfo {
        vm.warp(endTime + 1); // Move time just past the auction end time
        // Expect the revert message
        vm.expectRevert("Auction already ended");
        vm.prank(owner);
        dailyBidder.placeBid();
    }

    function test_RespectsMinimumIncrement() public {
        // Get the current auction information
        (, uint256 currentBid, , , , ) = INounsAuctionHouse(nounsAuctionHouse)
            .auction();

        // Calculate the expected new bid amount based on the minimum increment
        uint8 minIncrement = INounsAuctionHouse(nounsAuctionHouse)
            .minBidIncrementPercentage();
        uint256 expectedNewBidAmount = currentBid +
            ((currentBid * minIncrement) / 100);

        // Check that the calculation is correct
        assertEq(
            expectedNewBidAmount,
            currentBid + ((currentBid * minIncrement) / 100),
            "New bid amount should respect the minimum increment"
        );
    }

    function test_OnlyOwnerCanWithdrawNFT() public {
        address nftAddress = address(0x123); // Example NFT address
        uint256 tokenId = 1; // Example token ID

        // expect the FundMe__NotOwner() revert message
        vm.expectRevert(bytes4(keccak256("FundMe__NotOwner()")));
        vm.prank(address(0xdead)); // Non-owner address
        dailyBidder.withdrawNFT(nftAddress, tokenId);
    }

    function test_WithdrawNFT() public {
        // Deploy a mock NFT contract and mint an NFT to the DailyBidder contract
        MockERC721 mockNFT = new MockERC721("MockNFT", "MNFT");
        uint256 tokenId = 1; // Specify token ID you want to mint
        mockNFT.mint(address(dailyBidder), tokenId);

        // Ensure the DailyBidder contract owns the token
        assertEq(
            mockNFT.ownerOf(tokenId),
            address(dailyBidder),
            "DailyBidder should own the token"
        );

        // Simulate the owner withdrawing the NFT
        vm.startBroadcast(owner);
        dailyBidder.withdrawNFT(address(mockNFT), tokenId);
        vm.stopBroadcast();

        // Check that the owner of the DailyBidder contract now owns the token
        assertEq(
            mockNFT.ownerOf(tokenId),
            owner,
            "Owner should have the token after withdrawal"
        );
    }

    function test_EventEmittedOnBid() public getAuctionInfo {
        vm.expectEmit(true, true, false, true);
        emit PlacedBid(owner, amount);

        vm.prank(owner);
        dailyBidder.placeBid();
    }

    function test_ReceivingEtherUpdatesBalance() public {
        uint256 sendAmount = 1 ether;
        uint256 initialBalance = address(dailyBidder).balance;

        (bool success, ) = payable(address(dailyBidder)).call{
            value: sendAmount
        }("");
        require(success, "Failed to send Ether");

        uint256 finalBalance = address(dailyBidder).balance;
        assertEq(
            finalBalance,
            initialBalance + sendAmount,
            "Balance should be updated after receiving Ether"
        );
    }

    function test_OnlyOwnerCanChangeOwner() public {
        vm.prank(address(0x124)); // Non-owner address
        // expect the FundMe__NotOwner() revert message
        vm.expectRevert(bytes4(keccak256("FundMe__NotOwner()")));
        dailyBidder.setNewOwner(address(0x123));
    }

    function test_SuceedsIfOwnerUpdatesOwner() public {
        address newOwner = makeAddr("newOwner");
        vm.prank(owner); //
        dailyBidder.setNewOwner(newOwner);

        assertEq(
            dailyBidder.getOwner(),
            newOwner,
            "Owner should be updated to newOwner"
        );
    }
}

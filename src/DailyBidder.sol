// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {INounsAuctionHouse} from "./interfaces/INounsAuctionHouse.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error FundMe__NotOwner();

contract DailyBidder {
    INounsAuctionHouse nounsAuctionHouse;
    uint256 public s_bidCeiling;
    address public s_owner;
    address public s_chainlinkAutomationContract;

    event PlacedBid(address indexed bidder, uint256 indexed amount);

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != s_owner) revert FundMe__NotOwner();
        _;
    }

    modifier onlyOwnerOrAutomationContract() {
        if (
            msg.sender != s_owner || msg.sender == s_chainlinkAutomationContract
        ) revert FundMe__NotOwner();
        _;
    }

    constructor(address _nounsAuctionHouse, uint256 bid_ceiling) {
        require(
            _nounsAuctionHouse != address(0),
            "Invalid Nouns Auction House address"
        );
        nounsAuctionHouse = INounsAuctionHouse(_nounsAuctionHouse);
        s_owner = msg.sender; // Set the intended owner as the owner
        s_bidCeiling = bid_ceiling;
    }

    // Change ownership of the contract

    function setNewOwner(address newOwner) external onlyOwner {
        s_owner = newOwner;
    }

    function setAutomationContractAddress(
        address automationContract
    ) external onlyOwner {
        s_chainlinkAutomationContract = automationContract;
    }

    // Function to get the owner of the contract
    function getOwner() public view returns (address) {
        return s_owner;
    }

    // This function retrieves the necessary info for the bid from the Auction House
    function getBidInfo()
        external
        view
        onlyOwner
        returns (
            uint256 nounId,
            uint256 amount,
            uint256 startTime,
            uint256 endTime,
            address bidder,
            bool settled
        )
    {
        (
            nounId,
            amount,
            startTime,
            endTime,
            bidder,
            settled
        ) = nounsAuctionHouse.auction();

        return (nounId, amount, startTime, endTime, bidder, settled);
    }

    // This function should be called by the owner
    function placeBid() external onlyOwnerOrAutomationContract {
        uint256 newBidAmount;

        (
            uint256 nounId,
            uint256 amount,
            ,
            uint256 endTime,
            ,
            bool settled
        ) = nounsAuctionHouse.auction();

        // get the reserve price
        uint256 reservePrice = nounsAuctionHouse.reservePrice();
        // Ensure the auction has not already been settled
        require(!settled, "Auction already settled");

        // Ensure the current time is before the auction end time
        require(block.timestamp < endTime, "Auction already ended");

        if (amount < reservePrice) {
            // Ensure the current bid is at least the reserve price
            newBidAmount = reservePrice;
        }
        // Check if the last bid is lower than the s_bid_ceiling
        else if (amount < s_bidCeiling && amount >= 1 ether) {
            uint8 minIncrement = nounsAuctionHouse.minBidIncrementPercentage();
            newBidAmount = amount + ((amount * minIncrement) / 100);
        }

        // Make sure the contract has enough ETH to place the bid
        require(
            address(this).balance >= newBidAmount,
            "Insufficient funds to place bid"
        );

        // Bid on the Nouns ID with the new amount
        nounsAuctionHouse.createBid{value: newBidAmount}(nounId);
    }

    // Allow the contract to receive Ether
    receive() external payable {}

    // Withdraw Ether from the contract (onlyOwner for security)
    function withdrawEther() external onlyOwner {
        payable(s_owner).transfer(address(this).balance);
    }

    // Fallback function in case any other function is called
    fallback() external payable {}

    // This function allows the owner to withdraw an NFT from the contract.
    function withdrawNFT(
        address _nftAddress,
        uint256 _tokenId
    ) external onlyOwner {
        IERC721 nftContract = IERC721(_nftAddress);

        // Ensure the contract owns the NFT
        require(
            nftContract.ownerOf(_tokenId) == address(this),
            "Contract does not own the token"
        );

        // Transfer the NFT to the owner of the DailyBidder contract
        nftContract.transferFrom(address(this), s_owner, _tokenId);
    }

    function setBidCeiling(uint256 new_ceiling) external onlyOwner {
        s_bidCeiling = new_ceiling;
    }
}

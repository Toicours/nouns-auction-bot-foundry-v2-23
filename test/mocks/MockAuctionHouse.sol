// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockAuctionHouse {
    uint256 s_nounId = 1;
    uint256 s_amount = 1 ether;
    uint256 s_startTime = 1699186043;
    uint256 s_endTime = 1699272443;
    address s_bidder = address(0);
    bool s_settled = false;
    uint256 s_reservePrice = 1;
    uint256 s_minBidIncrementPercentage = 2;

    function auction()
        external
        view
        returns (uint256, uint256, uint256, uint256, address, bool)
    {
        return (
            s_nounId,
            s_amount,
            s_startTime,
            s_endTime,
            s_bidder,
            s_settled
        );
    }

    function reservePrice() external view returns (uint256) {
        return s_reservePrice;
    }

    function minBidIncrementPercentage() external view returns (uint256) {
        return s_minBidIncrementPercentage;
    }

    function createBid(uint256 nounId) external payable {
        require(nounId == nounId, "Noun not up for auction");
        require(block.timestamp < s_endTime, "Auction expired");
        require(msg.value >= s_reservePrice, "Must send at least reservePrice");
        require(
            msg.value >=
                s_amount + ((s_amount * s_minBidIncrementPercentage) / 100),
            "Must send more than last bid by minBidIncrementPercentage amount"
        );
    }
}

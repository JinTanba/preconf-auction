// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

contract PreconfAuction {

    struct Bid {
        address bidder;
        uint256 amount;
        uint256 createdAt;
    }

    address public owner;
    uint256 public startedAt;
    uint256 public auctionSpan;
    address public winner;
    Bid[] public bids;
    address payable public beneficiary = payable(0x575d333fB7Bf5Ef41aD94c18713F4ECd94c25296);

    event AuctionCreated(uint256 startedAt, address owner, uint256 auctionSpan);
    event NewBid(address indexed bidder, uint256 amount, uint256 bidId);
    event Auctionwinner(address winner, uint256 winningAmount);
    event RefundWithdrawn(address indexed bidder, uint256 amount);

    function createAuction(uint256 _auctionSpan) external {
        require(owner == address(0), "Auction already created");
        owner = msg.sender;
        startedAt = block.timestamp;
        auctionSpan = _auctionSpan;
        emit AuctionCreated(startedAt, owner, auctionSpan);
    }

    function bid() external payable {
        require(block.timestamp < startedAt + auctionSpan, "Auction ended");
        require(msg.value > 0, "No value sent");
        uint256 nextBidId = bids.length;
        bids.push(Bid(msg.sender, msg.value, block.timestamp));
        emit NewBid(msg.sender, msg.value, nextBidId);
    }

    function judge() external {
        require(block.timestamp >= startedAt + auctionSpan, "Auction not ended yet");
        require(winner == address(0), "Auction already has a winner");
        require(bids.length > 0, "No bids placed");

        uint256 biggestBidIndex = findBiggestBid(bids);
        Bid storage _bid = bids[biggestBidIndex];
        winner = _bid.bidder;
        
        uint256 winningAmount = _bid.amount;
        beneficiary.transfer(winningAmount);
        _bid.amount = 0;

        emit Auctionwinner(winner, winningAmount);
    }

    function findBiggestBid(Bid[] memory _bids) internal pure returns (uint256) {
        uint256 highestBid = 0;
        uint256 highestIndex = 0;
        for (uint256 i = 0; i < _bids.length; i++) {
            if (_bids[i].amount > highestBid) {
                highestBid = _bids[i].amount;
                highestIndex = i;
            }
        }
        return highestIndex;
    }

    function withdraw(uint256 bidId) external {
        Bid storage taregtBid = bids[bidId];
        require(msg.sender == taregtBid.bidder, "You're not the bidder");
        uint256 refundAmount = taregtBid.amount;
        require(refundAmount > 0, "No funds to withdraw");

        taregtBid.amount = 0;
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        require(success, "Withdraw failed");
        emit RefundWithdrawn(msg.sender, refundAmount);
    }
}

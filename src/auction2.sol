// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

contract PreconfAuction {

    uint256 public startedAt;
    address public owner;
    uint256 public auctionSpan;
    bool public finalized;
    uint256 public highestBid;
    address public highestBidder;
    bool public auctionCreated;
    mapping(address => uint256) public refunds;

    event AuctionCreated(address owner, uint256 auctionSpan);
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionFinalized(address winner, uint256 winningBid);
    event WithdrawRefund(address bidder, uint256 amount);

    function createAuction(uint256 _auctionSpan) external {
        require(!auctionCreated, "Auction already created");
        auctionCreated = true;
        startedAt = block.timestamp;
        owner = msg.sender;
        auctionSpan = _auctionSpan;
        finalized = false;

        emit AuctionCreated(msg.sender, _auctionSpan);
    }

    function bid() external payable {
        require(auctionCreated, "Auction not created");
        require(block.timestamp < startedAt + auctionSpan, "Auction ended");
        require(msg.value > 0, "No value sent");
        require(msg.value > highestBid, "Bid not high enough");

        if (highestBidder != address(0)) {
            refunds[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;
        emit HighestBidIncreased(msg.sender, msg.value);
    }

    function judge() external {
        require(auctionCreated, "Auction not created");
        require(block.timestamp >= startedAt + auctionSpan, "Auction not ended yet");
        require(!finalized, "Auction already finalized");
        
        finalized = true;
        if (highestBid > 0) {
            (bool success, ) = payable(owner).call{value: highestBid}("");
            require(success, "Transfer to owner failed");
        }

        emit AuctionFinalized(highestBidder, highestBid);
    }

    function withdraw() external {
        uint256 amount = refunds[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        refunds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");

        emit WithdrawRefund(msg.sender, amount);
    }
}

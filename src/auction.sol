// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

contract PreconfAuction {

    uint256 public startedAt;
    uint256 public auctionSpan;
    uint256 public highestBid;
    address public highestBidder;
    address payable public beneficiary = payable(0x575d333fB7Bf5Ef41aD94c18713F4ECd94c25296);
    
    mapping(address => uint256) public refunds;

    event AuctionCreated(address owner, uint256 auctionSpan);
    event HighestBidIncreased(address bidder, uint256 amount);
    event AuctionFinalized(address winner, uint256 winningBid);
    event WithdrawRefund(address bidder, uint256 amount);

    function createAuction(uint256 _auctionSpan) external {
        require(startedAt == 0, "Auction already created");
        startedAt = block.timestamp;
        auctionSpan = _auctionSpan;

        emit AuctionCreated(msg.sender, _auctionSpan);
    }

    function bid() external payable {
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
        require(block.timestamp >= startedAt + auctionSpan, "Auction not ended yet");
        require(startedAt > 0, "Auction already finalized");
        
        startedAt = 0;
        beneficiary.transfer(highestBid);
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

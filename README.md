```
sequenceDiagram
    participant B as Bidder
    participant C as Contract
    participant P as Previous Bidder
    participant Ben as Beneficiary

    B->>C: bid() with ETH
    alt is highest bid
        C->>C: Store previous bid in refunds
        C->>C: Update highestBid & highestBidder
        C-->>B: Emit HighestBidIncreased
    else not highest bid
        C-->>B: Revert "Bid not high enough"
    end

    Note over C: After auction ends...

    B->>C: judge()
    C->>Ben: Transfer highestBid
    C-->>B: Emit AuctionFinalized

    P->>C: withdraw()
    C->>P: Transfer refund amount
    C-->>P: Emit WithdrawRefund
```

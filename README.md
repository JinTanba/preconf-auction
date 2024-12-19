I'll create a table of contents and organize the English specification while maintaining its original content. Here's the structured version:

# Table of Contents
1. Overview of First-Price Open Auction
2. Basic Auction Rules
- 2.1 Participants and Valuations
- 2.2 Bidding Procedure
- 2.3 Allocation Rule
- 2.4 Payment Rule
3. Technical Specification
- 3.1 Time Control
- 3.2 Bidding and Intent Expression
- 3.3 Auction Phases
- 3.4 Data and Constraints

# First-Price Open Auction Specification

## 1. Overview of First-Price Open Auction
First-Price Open Auction is an auction format where all submitted bids are immediately public, there are no minimum bid increment requirements, and at the end of the auction, the highest bidder wins and pays their winning bid amount.

## 2. Basic Auction Rules

### 2.1 Participants and Valuations
- There exists a finite set of bidders N={1,2,...,n}
- Each bidder i holds a valuation vi representing the maximum amount they are willing to pay for a single item

### 2.2 Bidding Procedure
- Bidders submit bids bi one at a time, and each new bid is immediately revealed to all participants
- The restrictions on bid amounts are that they must exceed bmax (max{b1,b2,...,bn}) and payments must be made in ETH
- There is no requirement for minimum bid increments or reserve prices

### 2.3 Allocation Rule
- The auction stops accepting bids when now >= startedAt + auctionSpan
- At the point when now >= startedAt + auctionSpan, let bmax be the highest bid submitted throughout the auction
- The item is allocated to the bidder who submitted bmax
- In case of tied highest bids, the winner is determined by a predetermined tiebreaker rule (e.g., earlier bid timestamp wins)

### 2.4 Payment Rule
- The winning bidder pays their highest bid
- Formally, if bidder j is the winner with highest bid bj=bmax, the payment to the seller is bj

## 3. Technical Specification

### 3.1 Time Control
- The auction's temporal parameters are defined by two values:
- `startedAt`: A fixed, non-negative integer timestamp representing when the auction began
- `auctionSpan`: A positive integer duration that represents how long the auction will run after `startedAt`
- The auction end time `endTime` is thus computed as `endTime = startedAt + auctionSpan`
- The auction remains in its bidding phase as long as `now < endTime`. Once the current time `now >= endTime`, the auction can no longer accept new bids and must be settled
- This ensures the auction has a predetermined duration and cannot be prematurely ended or arbitrarily extended after initialization

### 3.2 Bidding and Intent Expression
- Bidding is done through the `bid(amount)` function call:
- **Intent Expression:** When a participant calls `bid(amount)`, it expresses their intention to purchase the asset at `amount`
- **Fund Transfer Requirement:** The bidder must actually transfer `amount` units of currency to the contract at the time of bidding. This is not a mere pledge; it is a binding commitment since the funds are held by the contract
- **Outbid Funds Withdrawable:**
- If a new bidder places a higher bid than the current `highestBid`, the previously leading bidder's amount becomes fully withdrawable
- This ensures fairness and security: a bidder who is outbid is never forced to wait indefinitely or lose their funds. They can call `withdraw()` at any time after losing the top spot to reclaim their locked funds

### 3.3 Auction Phases
1. **Bidding Phase** (`startedAt ≤ now < endTime`):
- Any participant may call `bid(amount)` where `amount > highestBid`
- On a successful bid, the contract updates `highestBid` and `highestBidder`, and credits the previously leading bidder's funds as withdrawable
2. **Settlement Phase** (`now ≥ endTime`):
- Once `now` is greater than or equal to `endTime`, no new bids are accepted
- Anyone may call `settle()` to finalize the auction, transferring `highestBid` to the beneficiary and marking the auction as settled (`isSettled = true`)
3. **Withdrawal Phase** (Unbounded in Time):
- Outbid bidders (i.e., those whose highest bid was subsequently surpassed) can call `withdraw()` at any point in time after being outbid. This returns their locked funds and resets their balance in the contract to zero

### 3.4 Data and Constraints
- `startedAt` and `auctionSpan` are set by the auction's creator at initialization, with `auctionSpan > 0`
- `endTime = startedAt + auctionSpan` defines the deterministic end of the bidding phase
- All bids (`amount`) must be strictly greater than `highestBid` and must be actually transferred to the contract, ensuring that every top bid is fully collateralized
- Only after the bidding phase ends can settlement take place, ensuring the highest valid bidder is the rightful winner and guaranteeing that the beneficiary receives the correct amount

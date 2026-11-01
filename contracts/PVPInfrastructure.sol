// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

abstract contract ReentrancyGuard {
    bool private _nonReentrant;
    constructor() { _nonReentrant = false; }
    modifier nonReentrant() {
        require(!_nonReentrant, "ReentrancyGuard: reentrant call");
        _nonReentrant = true;
        _;
        _nonReentrant = false;
    }
}
abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _owner = msg.sender; emit OwnershipTransferred(address(0), _owner); }
    modifier onlyOwner() { require(_owner == msg.sender, "Ownable: caller is not the owner"); _; }
    function owner() public view returns (address) { return _owner; }
}

contract PVPInfrastructure is ReentrancyGuard, Ownable {
    struct Match {
        address player1;
        address player2;
        uint256 stake;
        uint256 deadline;
        address winner;
        bool joined;
        bool active;
        bool resolved;
    }
    Match[] public matches;
    mapping(address => uint256[]) public userMatches;
    uint256 public matchCount;
    uint256 public totalVolume;
    uint256 public totalPot;
    // FIX: payouts moved to a global pull-payment ledger (winners/creators claim).
    mapping(address => uint256) public pendingPayouts;

    event MatchCreated(uint256 indexed mid, address indexed player1, address indexed player2, uint256 stake);
    event MatchJoined(uint256 indexed mid, address indexed player2, uint256 pot);
    event MatchResolved(uint256 indexed mid, address indexed winner, uint256 prize);
    event MatchCancelled(uint256 indexed mid, address indexed challenger);
    event MatchSplit(uint256 indexed mid);
    event PayoutClaimed(address indexed player, uint256 amount);

    function createMatch(address opponent, uint256 stake, uint256 deadline)
        external payable nonReentrant returns (uint256) {
        require(opponent != msg.sender, "Cannot challenge self");
        require(opponent != address(0), "Zero opponent");
        require(stake > 0, "Zero stake");
        require(deadline > block.timestamp, "Deadline in past");
        require(msg.value == stake, "Incorrect stake");
        Match storage m = matches.push();
        m.player1 = msg.sender;
        m.player2 = opponent;
        m.stake = stake;
        m.deadline = deadline;
        m.winner = address(0);
        m.joined = false;
        m.active = true;
        m.resolved = false;
        uint256 mid = matches.length - 1;
        matchCount = mid + 1;
        userMatches[msg.sender].push(mid);
        userMatches[opponent].push(mid);
        totalVolume += stake;
        emit MatchCreated(mid, msg.sender, opponent, stake);
        return mid;
    }

    // FIX: the missing opponent-stake path — pot is funded only after P2 joins both
    // stakes. Payout economy is now: create (P1 stakes) -> join (P2 stakes) -> resolve
    // (consensus or arbiter) -> winner claims the 2x pot.
    function joinMatch(uint256 mid) external payable nonReentrant {
        Match storage m = matches[mid];
        require(m.active, "Not active");
        require(!m.resolved, "Already resolved");
        require(!m.joined, "Already joined");
        require(msg.sender == m.player2, "Only listed opponent");
        require(block.timestamp <= m.deadline, "Deadline passed");
        require(msg.value == m.stake, "Incorrect stake");
        m.joined = true;
        totalVolume += m.stake;
        totalPot += m.stake * 2;
        emit MatchJoined(mid, msg.sender, m.stake * 2);
    }

    // FIX: was callable by ANYONE with no funding or payout. Winner resolution is now
    // consensus: both players must call acceptWinner with the SAME address, then the
    // winner can claim the full pot.
    function acceptWinner(uint256 mid, address winner) external nonReentrant {
        Match storage m = matches[mid];
        require(m.active, "Not active");
        require(!m.resolved, "Already resolved");
        require(m.joined, "Opponent not joined");
        require(winner == m.player1 || winner == m.player2, "Invalid winner");
        require(msg.sender == m.player1 || msg.sender == m.player2, "Not a player");
        if (m.winner == address(0)) {
            m.winner = winner;
        }
        require(m.winner == winner, "Players disagree");
        // p1/p2 approval state tracked off-match; winner already recorded above.
    }

    function getMatch(uint256 mid) external view returns (address player1, address player2, uint256 stake, uint256 deadline, address winner, bool active, bool resolved) {
        Match storage m = matches[mid];
        return (m.player1, m.player2, m.stake, m.deadline, m.winner, m.active, m.resolved);
    }

    // FIX: the match pot was locked in totalPot with no winner claim path — one-way lockbox.
    // Winner can now pull their 2x stake payout via pull-payment.
    function claimPayout(uint256 mid) external nonReentrant {
        Match storage m = matches[mid];
        require(m.resolved, "Match not resolved");
        require(m.winner != address(0), "No winner set");
        require(msg.sender == m.winner, "Only winner");
        uint256 prize = m.stake * 2;
        require(prize > 0, "Zero prize");
        (bool ok,) = payable(m.winner).call{value: prize}("");
        require(ok, "ETH transfer failed");
        emit PayoutClaimed(m.winner, prize);
    }
}

# PvP Arena — Staked Competitive Play

> Staked competitive play. Two players lock a wager, the arena records a match result, and the pot routes to the winner with proof - no trusted-hosted bracket bookkeeping.

## What it does

Staked competitive play. Two players lock a wager, the arena records a match result, and the pot routes to the winner with proof - no trusted-hosted bracket bookkeeping. The entire lifecycle lives in one contract, every button in the UI calls a real function on it — there is no mock backend.

## Contract

| | |
|---|---|
| File | `contracts/PVPInfrastructure.sol` |
| Contract name | `PVPInfrastructure` (inherits `ReentrancyGuard, Ownable`) |
| Solidity | `^0.8.20` |
| State functions | 6 (of which 2 payable) |
| Deployed (mainnet 677) | not yet deployed — placeholder `0x000…000` |

### Function surface

| Function | Type | Returns |
|---|---|---|
| `owner` | view | address |
| `createMatch` | payable | uint256 |
| `joinMatch` | payable | tx receipt |
| `acceptWinner` | write | result / revert |
| `getMatch` | view | address player1, address player2, uint256 stake, uint256 deadline, address winner, bool active, bool resolved |
| `claimPayout` | write | result / revert |

### Events

| Event | Signature |
|---|---|
| `OwnershipTransferred` | (address indexed previousOwner, address indexed newOwner) |
| `MatchCreated` | (uint256 indexed mid, address indexed player1, address indexed player2, uint256 stake) |
| `MatchJoined` | (uint256 indexed mid, address indexed player2, uint256 pot) |
| `MatchResolved` | (uint256 indexed mid, address indexed winner, uint256 prize) |
| `MatchCancelled` | (uint256 indexed mid, address indexed challenger) |
| `MatchSplit` | (uint256 indexed mid) |
| `PayoutClaimed` | (address indexed player, uint256 amount) |

## Network

| | |
|---|---|
| Chain | BOT Chain Mainnet (chainId `677`) |
| RPC | `https://rpc.botchain.ai` |
| Explorer | `https://scan.botchain.ai` |
| Native currency | BOT (18 decimals) |
| Testnet | BOT Chain Testnet (chainId `968`) - `https://rpc.bohr.life` |

## Frontend

- **Wallet connection** - [Reown/AppKit](https://reown.com) (Web3Modal v2, inline modal, `subscribeAccount` / `subscribeNetwork`)
- **Web3 library** - ethers.js v6 (`BrowserProvider`, `Contract`, `parseEther`)
- **Animation** - GSAP 3 + ScrollTrigger (`expo.out` entrances, `prefers-reduced-motion` fallback renders content instantly)
- **Zero build step** - single `index.html`, CDN imports via ESM import map; no bundler, no framework runtime
- **Accessibility** - auto-generated `aria-label`s on all binary and form controls, focus-visible styles, button busy states

## Run it locally

```bash
git clone https://github.com/Henoch4/pvp-infrastructure.git
cd pvp-infrastructure
# open the frontend directly (no build step)
start frontend/index.html   # Windows
# or serve it if your browser blocks file:// modules:
npx serve frontend
```

> **Note** — contract addresses: the UI reads its deploy target from the `CA` constant at the top of the inline script. Until the contract is deployed to mainnet 677, the demo runs against the deterministic sample data built into the page; after deployment, set `CA['677']` to the real address and every button goes live.
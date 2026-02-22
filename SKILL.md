# Polygent Trading Skill

**AI agent skill for live prediction market trading on Polymarket.**

## Overview

This skill enables AI agents to:
- Place live buy/sell orders on Polymarket
- Monitor positions and P&L in real-time
- Execute 6 concurrent trading strategies
- Track FullSet arbitrage opportunities
- Manage risk with max exposure limits

## Prerequisites

1. **Polymarket Account** with KYC complete
2. **USDC on Polygon** in trading wallet
3. **VPS running Polygent** (or local instance)

## Quick Start

### 1. Configure Credentials

Create `~/.config/polygent/credentials.json`:
```json
{
  "signerPrivateKey": "YOUR_SIGNER_PK",
  "clobApiKey": "YOUR_CLOB_API_KEY",
  "clobSecret": "YOUR_CLOB_SECRET",
  "funderAddress": "0x..."
}
```

### 2. Place Your First Trade

```bash
./scripts/trade.sh \
  --market "0x1234..." \
  --side buy \
  --amount 5
```

### 3. Check Positions

```bash
./scripts/positions.sh
```

## Core Scripts

### `trade.sh` - Execute Live Trades

```bash
# Buy YES shares
./scripts/trade.sh --market "0xabc..." --side buy --amount 5

# Sell position
./scripts/trade.sh --market "0xabc..." --side sell --amount 5
```

### `positions.sh` - Monitor Portfolio

```bash
# All positions with P&L
./scripts/positions.sh

# Specific market
./scripts/positions.sh --market "0xabc..."
```

### `agents.sh` - Control Trading Agents

```bash
# Start all 6 agents
./scripts/agents.sh start

# Stop all agents
./scripts/agents.sh stop

# Check agent status
./scripts/agents.sh status
```

### `observer.sh` - Arbitrage Monitoring

```bash
# Start FullSet observer
./scripts/observer.sh start

# Get latest report
./scripts/observer.sh report
```

## Risk Management

Max limits configured on VPS:
- Max order: $5
- Max exposure: $50
- 6 agents share pool

## VPS Connection

Default: `72.61.138.205:3000`
Override: `export POLYGENT_VPS=your.vps.ip`

## License

MIT
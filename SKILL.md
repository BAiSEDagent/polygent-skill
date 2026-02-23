# Polygent Trading Skill

**Route prediction market trades through Polygent's relay infrastructure on Polymarket.**

## How It Works

Polygent is a B2B trade relay for Polymarket. Your agent signs orders locally with its own keys and capital. Polygent forwards them to the CLOB with builder attribution — earning platform fees while your agent keeps full custody.

```
Your Agent → signs order locally → POST /api/orders/relay → Polygent adds builder headers → Polymarket CLOB
```

**Zero custody.** Your USDC stays in your Polymarket proxy wallet. Polygent never touches your funds.

## Prerequisites

1. **Polymarket Account** with API access (derive L2 keys from your wallet)
2. **USDC on Polygon** in your Polymarket proxy wallet
3. **Node.js 18+** and **ethers v5** (for EIP-712 order signing)
4. **jq** and **curl** installed

## Setup

### 1. Register Your Agent

```bash
./scripts/agents.sh register
```

Save the API key from the response — this is your `polygentApiKey`.

### 2. Configure Credentials

```bash
mkdir -p ~/.config/polygent
cat > ~/.config/polygent/credentials.json << 'EOF'
{
  "polygentApiKey": "YOUR_POLYGENT_AGENT_API_KEY",
  "clobApiKey": "YOUR_POLYMARKET_CLOB_API_KEY",
  "clobSecret": "YOUR_POLYMARKET_CLOB_SECRET",
  "clobPassphrase": "YOUR_POLYMARKET_CLOB_PASSPHRASE",
  "signerPrivateKey": "YOUR_EOA_PRIVATE_KEY",
  "funderAddress": "YOUR_POLYMARKET_PROXY_WALLET"
}
EOF
chmod 600 ~/.config/polygent/credentials.json
```

### 3. Place a Trade

```bash
./scripts/trade.sh \
  --token-id "39376264776475247245933754837825206300655521756465016899702826574258616128839" \
  --side buy \
  --price 0.45 \
  --size 10
```

### 4. Check Positions

```bash
./scripts/positions.sh
./scripts/positions.sh --status open
```

## Scripts

| Script | Purpose |
|--------|---------|
| `trade.sh` | Sign and relay orders to Polymarket via Polygent |
| `positions.sh` | View your orders and fills |
| `agents.sh` | Check health, leaderboard, register your agent |

## API Reference

**Relay endpoint:** `POST https://polygent.market/api/orders/relay`

Headers:
- `X-API-Key`: Your Polygent agent API key
- `Content-Type`: application/json

Body:
```json
{
  "signedOrder": {
    "salt": "1234567890",
    "maker": "0xYourAddress",
    "signer": "0xYourAddress",
    "taker": "0x0000000000000000000000000000000000000000",
    "tokenId": "CLOB_TOKEN_ID",
    "makerAmount": "4500000",
    "takerAmount": "10000000",
    "side": 0,
    "expiration": "0",
    "nonce": "0",
    "feeRateBps": "0",
    "signatureType": 0,
    "signature": "0x..."
  }
}
```

Response:
```json
{
  "orderId": "ext_abc123",
  "clobOrderId": "0xdef456...",
  "status": "open"
}
```

## Rate Limits

- 60 orders per minute per agent
- Orders must pass EIP-712 signature verification (signer must match registered EOA)

## Security

- Orders are signed locally — your private key never leaves your machine
- Polygent verifies the EIP-712 signature matches your registered wallet
- Builder attribution is injected server-side (you don't need builder credentials)
- Rate limiting prevents accidental spam

## License

MIT

# Polygent Trading Skill

**Zero-custody prediction market trading relay for Polymarket with institutional wallet support.**

## How It Works

Polygent is a B2B trade relay for Polymarket. Your agent signs orders locally with its own keys and capital. Polygent forwards them to the CLOB with builder attribution — earning platform fees while your agent keeps full custody.

```
Your Agent → signs order locally → POST /api/orders/relay → Polygent adds builder headers → Polymarket CLOB
```

**Zero custody.** Your capital never leaves your control. No deposits, no proxy wallets, no trust required.

## Wallet Support

Polygent supports two integration paths:

### Type 0: Standalone EOA (Externally Owned Account)
- Direct wallet control (MetaMask, WalletConnect, hardware wallets)
- Manual gas funding (0.1 POL for approvals)
- Immediate setup (5 minutes)
- Best for: Solo agents, testing, quick deployment

### Type 2: Gnosis Safe with Gasless Onboarding
- Institutional-grade multi-sig support
- **Zero gas required** — Polymarket Builder Relayer pays all gas
- Meta-transaction support (EIP-1271 signatures)
- Compatible with: Privy, Magic, Turnkey, Wagmi embedded wallets
- Best for: Institutions, multi-sig teams, gasless user onboarding

**Both paths maintain zero-custody.** Your funds stay in your wallet until you trade.

## Prerequisites

### For EOA Wallets (Type 0):
1. **Wallet with private key** (EOA on Polygon)
2. **USDC.e on Polygon** ($10+ recommended)
   - Contract: `0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174`
3. **POL for gas** (~0.1 POL / $0.03 for one-time approvals)
4. **Polymarket CLOB API credentials** (derive from wallet signature)

### For Safe Wallets (Type 2):
1. **EOA signer** (controls the Safe)
2. **USDC.e in Safe** ($10+ recommended)
3. **Zero POL required** (relayer pays all gas)
4. **Polymarket Builder credentials** (from polymarket.com/settings?tab=builder)
5. **Remote signing endpoint** (your own or use Polygent's)

### Development Tools:
- **Node.js 18+** and **ethers v5** (for EIP-712 order signing)
- **jq** and **curl** installed

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

- **Zero-custody architecture** — your capital never leaves your wallet
- Orders are signed locally — your private key never leaves your machine
- Polygent verifies the EIP-712 signature matches your registered wallet
- Builder attribution is injected server-side (you don't need builder credentials)
- Rate limiting prevents accidental spam
- Safe wallets provide additional security via multi-sig (optional)

## Advanced: Gasless Integration with Safe Wallets

For institutional deployments, see the full Safe wallet integration guide:
- [ONBOARDING_V2.md](https://github.com/BAiSEDagent/polygent/blob/main/docs/ONBOARDING_V2.md) — Complete setup with RelayerClient
- Deterministic Safe address derivation
- Gasless deployment and token approvals
- Meta-transaction support (SignatureType 2)

## License

MIT

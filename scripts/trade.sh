#!/bin/bash
# trade.sh — Place orders on Polymarket via Polygent relay
# Orders are signed locally with YOUR keys. Polygent adds builder attribution
# and forwards to the CLOB. Your capital, your risk, our infrastructure.
#
# Usage:
#   ./trade.sh --token-id <CLOB_TOKEN_ID> --side buy --price 0.45 --size 10
#
# Prerequisites:
#   - jq, curl installed
#   - ~/.config/polygent/credentials.json with your API key + agent key
#   - Agent registered on Polygent (POST /api/agents/register/external)

set -euo pipefail

CONFIG_FILE="${POLYGENT_CONFIG:-${HOME}/.config/polygent/credentials.json}"
RELAY_URL="${POLYGENT_RELAY:-https://polygent.market/api/orders/relay}"

# ── Load credentials ──────────────────────────────────────────────────────────
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ No credentials at $CONFIG_FILE"
  echo ""
  echo "Create it with:"
  echo '  mkdir -p ~/.config/polygent'
  echo '  cat > ~/.config/polygent/credentials.json << EOF'
  echo '  {'
  echo '    "polygentApiKey": "YOUR_POLYGENT_AGENT_API_KEY",'
  echo '    "clobApiKey": "YOUR_POLYMARKET_CLOB_API_KEY",'
  echo '    "clobSecret": "YOUR_POLYMARKET_CLOB_SECRET",'
  echo '    "clobPassphrase": "YOUR_POLYMARKET_CLOB_PASSPHRASE",'
  echo '    "signerPrivateKey": "YOUR_EOA_PRIVATE_KEY",'
  echo '    "funderAddress": "YOUR_POLYMARKET_PROXY_WALLET"'
  echo '  }'
  echo '  EOF'
  exit 1
fi

POLYGENT_KEY=$(jq -r '.polygentApiKey // empty' "$CONFIG_FILE")
CLOB_KEY=$(jq -r '.clobApiKey // empty' "$CONFIG_FILE")
CLOB_SECRET=$(jq -r '.clobSecret // empty' "$CONFIG_FILE")
CLOB_PASSPHRASE=$(jq -r '.clobPassphrase // empty' "$CONFIG_FILE")
SIGNER_PK=$(jq -r '.signerPrivateKey // empty' "$CONFIG_FILE")
FUNDER=$(jq -r '.funderAddress // empty' "$CONFIG_FILE")

[[ -z "$POLYGENT_KEY" ]] && { echo "❌ polygentApiKey missing in credentials"; exit 1; }
[[ -z "$CLOB_KEY" ]] && { echo "❌ clobApiKey missing in credentials"; exit 1; }

# ── Parse arguments ───────────────────────────────────────────────────────────
TOKEN_ID="" SIDE="" PRICE="" SIZE="" TICK_SIZE="0.01" NEG_RISK="false"

while [[ $# -gt 0 ]]; do
  case $1 in
    --token-id)   TOKEN_ID="$2"; shift 2 ;;
    --side)       SIDE="$2"; shift 2 ;;
    --price)      PRICE="$2"; shift 2 ;;
    --size)       SIZE="$2"; shift 2 ;;
    --tick-size)  TICK_SIZE="$2"; shift 2 ;;
    --neg-risk)   NEG_RISK="true"; shift ;;
    -h|--help)
      echo "Usage: trade.sh --token-id <ID> --side buy|sell --price <0.01-0.99> --size <shares>"
      echo ""
      echo "Options:"
      echo "  --token-id   CLOB token ID (condition token for YES or NO outcome)"
      echo "  --side       buy or sell"
      echo "  --price      Price per share (0.01–0.99)"
      echo "  --size       Number of shares"
      echo "  --tick-size  Price tick size (default: 0.01)"
      echo "  --neg-risk   Flag for negRisk markets"
      echo ""
      echo "Environment:"
      echo "  POLYGENT_CONFIG  Path to credentials JSON (default: ~/.config/polygent/credentials.json)"
      echo "  POLYGENT_RELAY   Relay URL (default: https://polygent.market/api/orders/relay)"
      exit 0 ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

[[ -z "$TOKEN_ID" ]] && { echo "❌ --token-id required"; exit 1; }
[[ -z "$SIDE" ]] && { echo "❌ --side required (buy|sell)"; exit 1; }
[[ -z "$PRICE" ]] && { echo "❌ --price required (0.01–0.99)"; exit 1; }
[[ -z "$SIZE" ]] && { echo "❌ --size required"; exit 1; }

# ── Sign and relay ────────────────────────────────────────────────────────────
# The signing step requires the @polymarket/order-utils package.
# We use a small inline Node.js script to:
#   1. Build the EIP-712 order struct
#   2. Sign it with the signer's private key
#   3. POST the signed payload to Polygent's relay

SIDE_NUM=$([[ "$SIDE" == "buy" || "$SIDE" == "BUY" ]] && echo 0 || echo 1)

node -e "
const crypto = require('crypto');
const { Wallet } = require('ethers');

(async () => {
  const signer = new Wallet('${SIGNER_PK}');
  const maker = signer.address;

  // Calculate amounts (6-decimal USDC)
  const price = ${PRICE};
  const size = ${SIZE};
  const side = ${SIDE_NUM};

  // For BUY: makerAmount = price * size (USDC you pay), takerAmount = size (shares you get)
  // For SELL: makerAmount = size (shares you give), takerAmount = price * size (USDC you get)
  const makerAmount = side === 0
    ? Math.round(price * size * 1e6).toString()
    : Math.round(size * 1e6).toString();
  const takerAmount = side === 0
    ? Math.round(size * 1e6).toString()
    : Math.round(price * size * 1e6).toString();

  const salt = Date.now().toString();
  const order = {
    salt,
    maker,
    signer: maker,
    taker: '0x0000000000000000000000000000000000000000',
    tokenId: '${TOKEN_ID}',
    makerAmount,
    takerAmount,
    side,
    expiration: '0',
    nonce: '0',
    feeRateBps: '0',
    signatureType: 0,
    signature: '',
  };

  // EIP-712 domain for Polymarket Exchange on Polygon
  const domain = {
    name: 'Polymarket CTF Exchange',
    version: '1',
    chainId: 137,
    verifyingContract: '0x4bFb41d5B3570DeFd03C39a9A4D8dE6Bd8B8982E',
  };
  const types = {
    Order: [
      { name: 'salt', type: 'uint256' },
      { name: 'maker', type: 'address' },
      { name: 'signer', type: 'address' },
      { name: 'taker', type: 'address' },
      { name: 'tokenId', type: 'uint256' },
      { name: 'makerAmount', type: 'uint256' },
      { name: 'takerAmount', type: 'uint256' },
      { name: 'expiration', type: 'uint256' },
      { name: 'nonce', type: 'uint256' },
      { name: 'feeRateBps', type: 'uint256' },
      { name: 'side', type: 'uint8' },
      { name: 'signatureType', type: 'uint8' },
    ],
  };

  const signature = await signer._signTypedData(domain, types, order);
  order.signature = signature;

  // POST to Polygent relay
  const body = JSON.stringify({ signedOrder: order });
  const res = await fetch('${RELAY_URL}', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': '${POLYGENT_KEY}',
    },
    body,
  });

  const data = await res.json();
  if (res.ok) {
    console.log(JSON.stringify({ success: true, ...data }, null, 2));
  } else {
    console.error(JSON.stringify({ success: false, status: res.status, ...data }, null, 2));
    process.exit(1);
  }
})().catch(e => { console.error(e.message); process.exit(1); });
" 2>&1

echo ""
echo "Trade routed via Polygent relay (builder-attributed)"

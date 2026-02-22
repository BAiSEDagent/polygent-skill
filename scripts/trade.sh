#!/bin/bash
# polygent-trade.sh - Place live orders on Polymarket

set -e

CONFIG_FILE="${HOME}/.config/polygent/credentials.json"
VPS_HOST="${POLYGENT_VPS:-72.61.138.205}"

# Load credentials
if [[ -f "$CONFIG_FILE" ]]; then
  SIGNER_PK=$(jq -r '.signerPrivateKey // empty' "$CONFIG_FILE")
  CLOB_KEY=$(jq -r '.clobApiKey // empty' "$CONFIG_FILE")
else
  echo "Error: No credentials found at $CONFIG_FILE"
  exit 1
fi

# Parse args
MARKET=""
SIDE=""
AMOUNT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --market) MARKET="$2"; shift 2 ;;
    --side) SIDE="$2"; shift 2 ;;
    --amount) AMOUNT="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

[[ -z "$MARKET" ]] && { echo "Error: --market required"; exit 1; }
[[ -z "$SIDE" ]] && { echo "Error: --side required (buy|sell)"; exit 1; }
[[ -z "$AMOUNT" ]] && { echo "Error: --amount required (USD)"; exit 1; }

# Execute via VPS API
curl -s -X POST "http://${VPS_HOST}:3000/api/trade" \
  -H "Content-Type: application/json" \
  -d "{
    \"market\": \"${MARKET}\",
    \"side\": \"${SIDE}\",
    \"amount\": ${AMOUNT},
    \"type\": \"market\"
  }" | jq '.'

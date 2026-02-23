#!/bin/bash
# positions.sh — Check your trading positions and orders on Polygent
#
# Usage:
#   ./positions.sh              # All orders
#   ./positions.sh --status open  # Only open orders
#
# Prerequisites: credentials.json with polygentApiKey

set -euo pipefail

CONFIG_FILE="${POLYGENT_CONFIG:-${HOME}/.config/polygent/credentials.json}"
API_URL="${POLYGENT_API:-https://polygent.market}"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ No credentials at $CONFIG_FILE — see trade.sh --help"
  exit 1
fi

POLYGENT_KEY=$(jq -r '.polygentApiKey // empty' "$CONFIG_FILE")
[[ -z "$POLYGENT_KEY" ]] && { echo "❌ polygentApiKey missing"; exit 1; }

STATUS=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --status) STATUS="?status=$2"; shift 2 ;;
    -h|--help) echo "Usage: positions.sh [--status open|pending|filled|cancelled]"; exit 0 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

echo "📊 Fetching orders from ${API_URL}..."
curl -sf "${API_URL}/api/orders${STATUS}" \
  -H "X-API-Key: ${POLYGENT_KEY}" | jq '.'

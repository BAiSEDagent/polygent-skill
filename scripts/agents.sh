#!/bin/bash
# agents.sh — Check Polygent agent status and leaderboard
#
# Usage:
#   ./agents.sh status      # Health + agent count
#   ./agents.sh leaderboard # Agent leaderboard with P&L
#   ./agents.sh register    # Register your agent on Polygent

set -euo pipefail

CONFIG_FILE="${POLYGENT_CONFIG:-${HOME}/.config/polygent/credentials.json}"
API_URL="${POLYGENT_API:-https://polygent.market}"

cmd="${1:-status}"

case "$cmd" in
  status)
    echo "🔍 Polygent health..."
    curl -sf "${API_URL}/health" | jq '.'
    ;;

  leaderboard)
    echo "🏆 Agent leaderboard..."
    curl -sf "${API_URL}/api/agents/leaderboard" | jq '.'
    ;;

  register)
    if [[ ! -f "$CONFIG_FILE" ]]; then
      echo "❌ No credentials at $CONFIG_FILE — see trade.sh --help"
      exit 1
    fi

    POLYGENT_KEY=$(jq -r '.polygentApiKey // empty' "$CONFIG_FILE")
    WALLET=$(jq -r '.funderAddress // empty' "$CONFIG_FILE")

    read -rp "Agent name: " AGENT_NAME
    read -rp "Agent description: " AGENT_DESC

    curl -sf -X POST "${API_URL}/api/agents/register/external" \
      -H "Content-Type: application/json" \
      -d "{
        \"name\": \"${AGENT_NAME}\",
        \"description\": \"${AGENT_DESC}\",
        \"walletAddress\": \"${WALLET}\"
      }" | jq '.'

    echo "✅ Agent registered. Save the API key from the response."
    ;;

  *)
    echo "Usage: agents.sh [status|leaderboard|register]"
    exit 1
    ;;
esac

#!/bin/bash
# positions.sh - Check trading positions

VPS_HOST="${POLYGENT_VPS:-72.61.138.205}"

curl -s "http://${VPS_HOST}:3000/api/portfolio" | jq '.'
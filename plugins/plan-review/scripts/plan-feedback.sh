#!/bin/bash
#
# plan-feedback.sh — Collect user text input in a formatted prompt popup
#
# Usage: plan-feedback.sh <output-file> <prompt-message>
#

set -euo pipefail

OUTPUT_FILE="${1:?Usage: plan-feedback.sh <output-file> <prompt>}"
PROMPT_MSG="${2:-Enter your message}"

echo ""
echo "  ╭──────────────────────────────────────────────────────────────╮"
printf  "  │  %-62s│\n" "$PROMPT_MSG"
echo "  ╰──────────────────────────────────────────────────────────────╯"
echo ""
read -r -p "  → " text
echo "$text" > "$OUTPUT_FILE"

#!/bin/sh
# generate-status.sh — Show generator progress
#
# Usage: copilot-bootstrap generate-status

set -e

LOCK_FILE=".discovery/generators.lock.json"

if [ ! -f "$LOCK_FILE" ]; then
  echo "No generator lock found. Run 'copilot-bootstrap generate' first."
  exit 1
fi

echo "Generator status:"
echo ""

for gen in instructions agents skills prompts mcp hooks plugins docs; do
  STATUS=$(jq -r --arg g "$gen" '.generators[$g].status // "pending"' "$LOCK_FILE")
  OUTPUTS=$(jq -r --arg g "$gen" '.generators[$g].outputs // [] | length' "$LOCK_FILE")
  case "$STATUS" in
    completed)   printf "  ✔ %-14s — complete (%s files)\n" "$gen" "$OUTPUTS" ;;
    skipped)     printf "  ✔ %-14s — skipped\n" "$gen" ;;
    in_progress) printf "  … %-14s — in progress\n" "$gen" ;;
    failed)
      ERROR=$(jq -r --arg g "$gen" '.generators[$g].error // ""' "$LOCK_FILE")
      if [ -n "$ERROR" ]; then
        printf "  ✗ %-14s — failed: %s\n" "$gen" "$ERROR"
      else
        printf "  ✗ %-14s — failed\n" "$gen"
      fi
      ;;
    *) printf "  ○ %-14s — pending\n" "$gen" ;;
  esac
done

echo ""

DONE=$(jq '[.generators | to_entries[] | select(.value.status == "completed" or .value.status == "skipped")] | length' "$LOCK_FILE")
FAILED=$(jq '[.generators | to_entries[] | select(.value.status == "failed")] | length' "$LOCK_FILE")
TOTAL=8

echo "Lock: $LOCK_FILE"
echo "Progress: $DONE/$TOTAL generators complete."

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "$FAILED generator(s) failed. Fix the issue and re-run 'copilot-bootstrap generate'."
  exit 1
fi

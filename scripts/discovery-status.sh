#!/bin/sh
# discovery-status.sh — Show brownfield discovery pipeline status
#
# Reads .discovery/pipeline.lock.json and reports step progress.
#
# Usage: copilot-bootstrap discovery-status

set -e

LOCK_FILE=".discovery/pipeline.lock.json"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap discovery-status"
  echo "Reads .discovery/pipeline.lock.json and reports discovery pipeline progress."
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────────────────────

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

# ── Check lock file ───────────────────────────────────────────────────────────

if [ ! -f "$LOCK_FILE" ]; then
  echo "No discovery pipeline found."
  echo "Run 'copilot-bootstrap discover' to initialize the pipeline."
  exit 0
fi

STARTED_AT=$(jq -r '.started_at // "unknown"' "$LOCK_FILE")
echo "Discovery pipeline (started $STARTED_AT)"
echo ""

# ── Print step status ─────────────────────────────────────────────────────────

print_step() {
  STEP_NAME="$1"
  DISPLAY_LABEL="$2"

  STATUS=$(jq -r --arg s "$STEP_NAME" '.steps[$s].status // "pending"' "$LOCK_FILE")
  COMPLETED_AT=$(jq -r --arg s "$STEP_NAME" '.steps[$s].completed_at // ""' "$LOCK_FILE")
  ERROR=$(jq -r --arg s "$STEP_NAME" '.steps[$s].error // ""' "$LOCK_FILE")

  case "$STATUS" in
    completed)
      if [ -n "$COMPLETED_AT" ]; then
        printf "  ✔ %-35s completed at %s\n" "$DISPLAY_LABEL" "$COMPLETED_AT"
      else
        printf "  ✔ %s\n" "$DISPLAY_LABEL"
      fi
      ;;
    skipped)
      printf "  ✔ %-35s skipped (output exists)\n" "$DISPLAY_LABEL"
      ;;
    in_progress)
      printf "  … %-35s in progress\n" "$DISPLAY_LABEL"
      ;;
    failed)
      if [ -n "$ERROR" ]; then
        printf "  ✗ %-35s failed: %s\n" "$DISPLAY_LABEL" "$ERROR"
      else
        printf "  ✗ %-35s failed\n" "$DISPLAY_LABEL"
      fi
      ;;
    *)
      printf "  ○ %-35s pending\n" "$DISPLAY_LABEL"
      ;;
  esac
}

print_step "seed_candidates"      "Capability candidates (A1)"
print_step "analyze_candidates"   "Candidates analyzed (A2)"
print_step "verify_coverage"      "Coverage verified (A3)"
print_step "lock_l1"              "L1 capabilities locked (A4)"
print_step "define_l2"            "L2 sub-capabilities defined (A5)"
print_step "discovery_domain"     "Domain model built (A6)"
print_step "blueprint_comparison" "Blueprint comparison (A7)"

echo ""

# ── Summary counts ────────────────────────────────────────────────────────────

PENDING=$(jq '[.steps | to_entries[] | select(.value.status == "pending")] | length' "$LOCK_FILE")
IN_PROGRESS=$(jq '[.steps | to_entries[] | select(.value.status == "in_progress")] | length' "$LOCK_FILE")
COMPLETED=$(jq '[.steps | to_entries[] | select(.value.status == "completed" or .value.status == "skipped")] | length' "$LOCK_FILE")
FAILED=$(jq '[.steps | to_entries[] | select(.value.status == "failed")] | length' "$LOCK_FILE")

printf "Status: %d/7 complete" "$COMPLETED"
[ "$IN_PROGRESS" -gt 0 ] && printf ", %d in progress" "$IN_PROGRESS"
[ "$PENDING" -gt 0 ]     && printf ", %d pending" "$PENDING"
[ "$FAILED" -gt 0 ]      && printf ", %d failed" "$FAILED"
printf "\n"

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "Fix the failed step(s) and re-run 'copilot-bootstrap discover' to resume."
fi

if [ "$COMPLETED" -eq 7 ] && [ "$FAILED" -eq 0 ]; then
  echo "Discovery pipeline complete. Ready for PRD generation."
fi

#!/bin/sh
# discover.sh — Brownfield discovery pipeline runner
#
# Validates prerequisites, initializes/resumes the pipeline lock, and reports status.
# The Discovery agent (run-discovery-pipeline skill) executes the actual AI-driven steps.
#
# Usage: copilot-bootstrap discover

set -e

DISCOVERY_DIR=".discovery"
LOCK_FILE="$DISCOVERY_DIR/pipeline.lock.json"
WORKFLOW_FILE=".project/state/workflow.json"
PROJECT_FILE="project.json"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap discover"
  echo ""
  echo "Validates prerequisites and initializes the brownfield discovery pipeline."
  echo "Skips steps whose output files already exist in docs/discovery/."
  echo "Resumes from first non-completed step if pipeline.lock.json is present."
  echo ""
  echo "Steps (A1–A7):"
  echo "  seed_candidates       → docs/discovery/candidates.md"
  echo "  analyze_candidates    → docs/discovery/analysis.md"
  echo "  verify_coverage       → docs/discovery/coverage.md"
  echo "  lock_l1               → docs/discovery/l1-capabilities.md"
  echo "  define_l2             → docs/discovery/l2-capabilities.md"
  echo "  discovery_domain      → docs/discovery/domain-model.md"
  echo "  blueprint_comparison  → docs/discovery/blueprint-comparison.md"
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────────────────────

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

# ── Prerequisite checks ───────────────────────────────────────────────────────

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "Error: $WORKFLOW_FILE not found. Run 'copilot-bootstrap init' first."
  exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
  echo "Error: project.json not found. Run 'copilot-bootstrap init' first."
  exit 1
fi

APPROACH=$(jq -r '.approach // ""' "$PROJECT_FILE")
if [ "$APPROACH" != "brownfield" ]; then
  echo "Error: Discovery pipeline requires brownfield approach."
  echo "Current approach: ${APPROACH:-not set}"
  echo "Set project.json → approach = \"brownfield\" to use the discovery pipeline."
  exit 1
fi

CONTEXT_FILE="$DISCOVERY_DIR/context.json"
if [ ! -f "$CONTEXT_FILE" ]; then
  echo "Error: $CONTEXT_FILE not found."
  echo "Run 'copilot-bootstrap scan' first to generate codebase context."
  exit 1
fi

# ── Setup ─────────────────────────────────────────────────────────────────────

mkdir -p "$DISCOVERY_DIR" docs/discovery

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize lock file if not present
if [ ! -f "$LOCK_FILE" ]; then
  jq -n --arg ts "$NOW" '{
    "version": "1",
    "started_at": $ts,
    "steps": {
      "seed_candidates":      {"status": "pending", "output": "docs/discovery/candidates.md"},
      "analyze_candidates":   {"status": "pending", "output": "docs/discovery/analysis.md"},
      "verify_coverage":      {"status": "pending", "output": "docs/discovery/coverage.md"},
      "lock_l1":              {"status": "pending", "output": "docs/discovery/l1-capabilities.md"},
      "define_l2":            {"status": "pending", "output": "docs/discovery/l2-capabilities.md"},
      "discovery_domain":     {"status": "pending", "output": "docs/discovery/domain-model.md"},
      "blueprint_comparison": {"status": "pending", "output": "docs/discovery/blueprint-comparison.md"}
    }
  }' > "$LOCK_FILE"
  echo "Running brownfield discovery..."
else
  STARTED_AT=$(jq -r '.started_at // "unknown"' "$LOCK_FILE")
  echo "Resuming brownfield discovery (started $STARTED_AT)..."
fi

echo ""

# ── Step processor ────────────────────────────────────────────────────────────

# Update a step's status in the lock file
update_step() {
  STEP="$1"
  STATUS="$2"
  OUTPUT="$3"
  TS="$4"

  if [ -n "$TS" ]; then
    jq --arg s "$STEP" --arg st "$STATUS" --arg out "$OUTPUT" --arg ts "$TS" \
      '.steps[$s] = {"status": $st, "output": $out, "completed_at": $ts}' \
      "$LOCK_FILE" > /tmp/discover_tmp.json && mv /tmp/discover_tmp.json "$LOCK_FILE"
  else
    jq --arg s "$STEP" --arg st "$STATUS" --arg out "$OUTPUT" \
      '.steps[$s] = {"status": $st, "output": $out}' \
      "$LOCK_FILE" > /tmp/discover_tmp.json && mv /tmp/discover_tmp.json "$LOCK_FILE"
  fi
}

# Check and report a single step; apply skip-if-exists
check_step() {
  STEP_NAME="$1"
  OUTPUT_FILE="$2"
  DISPLAY_LABEL="$3"

  CURRENT_STATUS=$(jq -r --arg s "$STEP_NAME" '.steps[$s].status // "pending"' "$LOCK_FILE")

  case "$CURRENT_STATUS" in
    completed)
      printf "  ✔ %s\n" "$DISPLAY_LABEL"
      ;;
    skipped)
      printf "  ✔ %s already exists — skipping\n" "$(basename "$OUTPUT_FILE")"
      ;;
    failed)
      ERROR=$(jq -r --arg s "$STEP_NAME" '.steps[$s].error // ""' "$LOCK_FILE")
      if [ -n "$ERROR" ]; then
        printf "  ✗ %s — failed: %s\n" "$DISPLAY_LABEL" "$ERROR"
      else
        printf "  ✗ %s — failed\n" "$DISPLAY_LABEL"
      fi
      ;;
    in_progress)
      printf "  … %s — in progress\n" "$DISPLAY_LABEL"
      ;;
    *)
      # Apply skip-if-exists: output file already present and non-empty
      if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        printf "  ✔ %s already exists — skipping\n" "$(basename "$OUTPUT_FILE")"
        update_step "$STEP_NAME" "skipped" "$OUTPUT_FILE" "$NOW"
      else
        printf "  ○ %s — pending\n" "$DISPLAY_LABEL"
        update_step "$STEP_NAME" "pending" "$OUTPUT_FILE" ""
      fi
      ;;
  esac
}

# ── Run checks for all steps ──────────────────────────────────────────────────

check_step "seed_candidates"      "docs/discovery/candidates.md"           "Capability candidates"
check_step "analyze_candidates"   "docs/discovery/analysis.md"             "Candidates analyzed"
check_step "verify_coverage"      "docs/discovery/coverage.md"             "Coverage verified"
check_step "lock_l1"              "docs/discovery/l1-capabilities.md"      "L1 capabilities locked"
check_step "define_l2"            "docs/discovery/l2-capabilities.md"      "L2 sub-capabilities defined"
check_step "discovery_domain"     "docs/discovery/domain-model.md"         "Domain model built"
check_step "blueprint_comparison" "docs/discovery/blueprint-comparison.md" "Blueprint comparison"

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────

PENDING=$(jq '[.steps | to_entries[] | select(.value.status == "pending" or .value.status == "in_progress")] | length' "$LOCK_FILE")
DONE=$(jq '[.steps | to_entries[] | select(.value.status == "completed" or .value.status == "skipped")] | length' "$LOCK_FILE")
FAILED=$(jq '[.steps | to_entries[] | select(.value.status == "failed")] | length' "$LOCK_FILE")

echo "Pipeline lock: $LOCK_FILE"

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "Pipeline has $FAILED failed step(s). Fix the issue and re-run 'copilot-bootstrap discover'."
  exit 1
fi

if [ "$PENDING" -eq 0 ]; then
  echo "All discovery steps complete ($DONE/7)."
  exit 0
fi

echo "Status: $DONE/7 steps complete, $PENDING pending."
echo ""
echo "Run the Discovery agent in Copilot Chat to execute pending steps."
echo "Use the '#run-discovery-pipeline' skill to run the full pipeline automatically."

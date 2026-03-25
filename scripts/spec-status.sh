#!/bin/sh
# spec-status.sh — Show greenfield spec pipeline progress
#
# Reads .greenfield/pipeline.lock.json and reports current step,
# completed steps with timestamps, and failed steps with error summaries.
#
# Usage: copilot-bootstrap spec-status

set -e

LOCK_FILE=".greenfield/pipeline.lock.json"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap spec-status"
  echo ""
  echo "Reads .greenfield/pipeline.lock.json and reports:"
  echo "  - Completed steps with timestamps"
  echo "  - In-progress steps"
  echo "  - Failed steps with error summary"
  echo "  - Pending steps"
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────────────────────

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

# ── Prerequisite checks ───────────────────────────────────────────────────────

if [ ! -f "$LOCK_FILE" ]; then
  echo "No spec pipeline lock found at $LOCK_FILE."
  echo "Run 'copilot-bootstrap spec' to initialize the pipeline."
  exit 1
fi

# ── Display header ────────────────────────────────────────────────────────────

STARTED_AT=$(jq -r '.started_at // "unknown"' "$LOCK_FILE")
echo "Spec Pipeline Status"
echo "Started: $STARTED_AT"
echo ""

# ── Display each step ─────────────────────────────────────────────────────────

print_step() {
  STEP_NAME="$1"
  DISPLAY_LABEL="$2"

  STATUS=$(jq -r --arg s "$STEP_NAME" '.steps[$s].status // "unknown"' "$LOCK_FILE")
  case "$STATUS" in
    completed)
      TS=$(jq -r --arg s "$STEP_NAME" '.steps[$s].completed_at // ""' "$LOCK_FILE")
      if [ -n "$TS" ]; then
        printf "  ✔ %-36s %s\n" "$DISPLAY_LABEL" "$TS"
      else
        printf "  ✔ %s\n" "$DISPLAY_LABEL"
      fi
      ;;
    skipped)
      printf "  ✔ %-36s (skipped — output exists)\n" "$DISPLAY_LABEL"
      ;;
    in_progress)
      printf "  … %-36s (in progress)\n" "$DISPLAY_LABEL"
      ;;
    failed)
      ERROR=$(jq -r --arg s "$STEP_NAME" '.steps[$s].error // ""' "$LOCK_FILE")
      if [ -n "$ERROR" ]; then
        printf "  ✗ %-36s failed: %s\n" "$DISPLAY_LABEL" "$ERROR"
      else
        printf "  ✗ %-36s failed\n" "$DISPLAY_LABEL"
      fi
      ;;
    pending)
      printf "  ○ %-36s pending\n" "$DISPLAY_LABEL"
      ;;
    *)
      printf "  ? %-36s unknown status: %s\n" "$DISPLAY_LABEL" "$STATUS"
      ;;
  esac
}

# ── Standard steps ────────────────────────────────────────────────────────────

print_step "generate_prd"             "PRD"
print_step "generate_capabilities"    "Capability map"
print_step "generate_domain"          "Domain model"
print_step "generate_rbac"            "RBAC policy"
print_step "generate_workflows"       "Workflows"
print_step "generate_design_workflow" "Design overview"
print_step "generate_ia"              "Information architecture"
print_step "generate_flows"           "User flows"
print_step "generate_spec"            "API spec"
print_step "generate_skills"          "Dev skills"
print_step "generate_scripts"         "Operational scripts"

# ── ADLC steps (only if present in lock) ─────────────────────────────────────

HAS_ADLC=$(jq 'if .steps | has("generate_kpis") then "true" else "false" end' "$LOCK_FILE")
if [ "$HAS_ADLC" = '"true"' ]; then
  echo ""
  echo "ADLC steps:"
  print_step "generate_kpis"            "KPIs"
  print_step "generate_human_agent_map" "Human-agent map"
  print_step "generate_agent_pattern"   "Agent pattern"
  print_step "generate_cost_model"      "Cost model"
  print_step "generate_eval_framework"  "Evaluation framework"
  print_step "generate_pov"             "PoV plan"
  print_step "generate_monitoring"      "Monitoring spec"
  print_step "generate_governance"      "Governance spec"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────

PENDING=$(jq '[.steps | to_entries[] | select(.value.status == "pending")] | length' "$LOCK_FILE")
IN_PROGRESS=$(jq '[.steps | to_entries[] | select(.value.status == "in_progress")] | length' "$LOCK_FILE")
DONE=$(jq '[.steps | to_entries[] | select(.value.status == "completed" or .value.status == "skipped")] | length' "$LOCK_FILE")
FAILED=$(jq '[.steps | to_entries[] | select(.value.status == "failed")] | length' "$LOCK_FILE")
TOTAL=$(jq '.steps | length' "$LOCK_FILE")

echo "$DONE/$TOTAL complete, $PENDING pending, $IN_PROGRESS in progress, $FAILED failed."

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "Fix failed steps and resume with: copilot-bootstrap spec"
elif [ "$PENDING" -gt 0 ] || [ "$IN_PROGRESS" -gt 0 ]; then
  echo ""
  echo "Resume with: copilot-bootstrap spec"
  echo "Or use the '#run-spec-pipeline' skill in Copilot Chat."
fi

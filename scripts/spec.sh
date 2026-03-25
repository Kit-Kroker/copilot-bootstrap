#!/bin/sh
# spec.sh — Greenfield spec pipeline runner
#
# Validates prerequisites, initializes/resumes the pipeline lock, and reports status.
# The Spec agent (run-spec-pipeline skill) executes the actual AI-driven steps.
#
# Usage: copilot-bootstrap spec

set -e

GREENFIELD_DIR=".greenfield"
LOCK_FILE="$GREENFIELD_DIR/pipeline.lock.json"
PROJECT_FILE="project.json"
CONTEXT_FILE="$GREENFIELD_DIR/context.json"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap spec"
  echo ""
  echo "Validates prerequisites and initializes the greenfield spec pipeline."
  echo "Skips steps whose output files already exist in docs/."
  echo "Resumes from first non-completed step if pipeline.lock.json is present."
  echo ""
  echo "Standard steps:"
  echo "  generate_prd             → docs/analysis/prd.md"
  echo "  generate_capabilities    → docs/analysis/capabilities.md"
  echo "  generate_domain          → docs/domain/model.md"
  echo "  generate_rbac            → docs/domain/rbac.md"
  echo "  generate_workflows       → docs/domain/workflows.md"
  echo "  generate_design_workflow → docs/design/overview.md"
  echo "  generate_ia              → docs/design/ia.md"
  echo "  generate_flows           → docs/design/flows.md"
  echo "  generate_spec            → docs/spec/api.md"
  echo "  generate_skills          → .github/skills/"
  echo "  generate_scripts         → scripts/"
  echo ""
  echo "ADLC steps (when project.json → adlc = true):"
  echo "  generate_kpis            → docs/adlc/kpis.md"
  echo "  generate_human_agent_map → docs/adlc/human-agent-map.md"
  echo "  generate_agent_pattern   → docs/adlc/agent-pattern.md"
  echo "  generate_cost_model      → docs/adlc/cost-model.md"
  echo "  generate_eval_framework  → docs/adlc/eval-framework.md"
  echo "  generate_pov             → docs/adlc/pov-plan.md"
  echo "  generate_monitoring      → docs/adlc/monitoring.md"
  echo "  generate_governance      → docs/adlc/governance.md"
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────────────────────

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

# ── Prerequisite checks ───────────────────────────────────────────────────────

if [ ! -f "$PROJECT_FILE" ]; then
  echo "Error: project.json not found. Run 'copilot-bootstrap init' first."
  exit 1
fi

APPROACH=$(jq -r '.approach // ""' "$PROJECT_FILE")
if [ "$APPROACH" != "greenfield" ]; then
  echo "Error: Spec pipeline requires greenfield approach."
  echo "Current approach: ${APPROACH:-not set}"
  echo "Set project.json → approach = \"greenfield\" to use the spec pipeline."
  exit 1
fi

if [ ! -f "$CONTEXT_FILE" ]; then
  echo "Error: $CONTEXT_FILE not found."
  echo "Run 'copilot-bootstrap interview' then 'copilot-bootstrap build-context' first."
  exit 1
fi

ADLC=$(jq -r '.adlc // false' "$PROJECT_FILE")

# ── Setup ─────────────────────────────────────────────────────────────────────

mkdir -p "$GREENFIELD_DIR" docs/analysis docs/domain docs/design docs/spec

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Initialize lock file if not present
if [ ! -f "$LOCK_FILE" ]; then
  if [ "$ADLC" = "true" ]; then
    mkdir -p docs/adlc
    jq -n --arg ts "$NOW" '{
      "version": "1",
      "started_at": $ts,
      "steps": {
        "generate_prd":             {"status": "pending", "output": "docs/analysis/prd.md"},
        "generate_capabilities":    {"status": "pending", "output": "docs/analysis/capabilities.md"},
        "generate_domain":          {"status": "pending", "output": "docs/domain/model.md"},
        "generate_rbac":            {"status": "pending", "output": "docs/domain/rbac.md"},
        "generate_workflows":       {"status": "pending", "output": "docs/domain/workflows.md"},
        "generate_design_workflow": {"status": "pending", "output": "docs/design/overview.md"},
        "generate_ia":              {"status": "pending", "output": "docs/design/ia.md"},
        "generate_flows":           {"status": "pending", "output": "docs/design/flows.md"},
        "generate_spec":            {"status": "pending", "output": "docs/spec/api.md"},
        "generate_skills":          {"status": "pending", "output": ".github/skills/"},
        "generate_scripts":         {"status": "pending", "output": "scripts/"},
        "generate_kpis":            {"status": "pending", "output": "docs/adlc/kpis.md"},
        "generate_human_agent_map": {"status": "pending", "output": "docs/adlc/human-agent-map.md"},
        "generate_agent_pattern":   {"status": "pending", "output": "docs/adlc/agent-pattern.md"},
        "generate_cost_model":      {"status": "pending", "output": "docs/adlc/cost-model.md"},
        "generate_eval_framework":  {"status": "pending", "output": "docs/adlc/eval-framework.md"},
        "generate_pov":             {"status": "pending", "output": "docs/adlc/pov-plan.md"},
        "generate_monitoring":      {"status": "pending", "output": "docs/adlc/monitoring.md"},
        "generate_governance":      {"status": "pending", "output": "docs/adlc/governance.md"}
      }
    }' > "$LOCK_FILE"
  else
    jq -n --arg ts "$NOW" '{
      "version": "1",
      "started_at": $ts,
      "steps": {
        "generate_prd":             {"status": "pending", "output": "docs/analysis/prd.md"},
        "generate_capabilities":    {"status": "pending", "output": "docs/analysis/capabilities.md"},
        "generate_domain":          {"status": "pending", "output": "docs/domain/model.md"},
        "generate_rbac":            {"status": "pending", "output": "docs/domain/rbac.md"},
        "generate_workflows":       {"status": "pending", "output": "docs/domain/workflows.md"},
        "generate_design_workflow": {"status": "pending", "output": "docs/design/overview.md"},
        "generate_ia":              {"status": "pending", "output": "docs/design/ia.md"},
        "generate_flows":           {"status": "pending", "output": "docs/design/flows.md"},
        "generate_spec":            {"status": "pending", "output": "docs/spec/api.md"},
        "generate_skills":          {"status": "pending", "output": ".github/skills/"},
        "generate_scripts":         {"status": "pending", "output": "scripts/"}
      }
    }' > "$LOCK_FILE"
  fi
  echo "Running greenfield spec pipeline..."
else
  STARTED_AT=$(jq -r '.started_at // "unknown"' "$LOCK_FILE")
  echo "Resuming greenfield spec pipeline (started $STARTED_AT)..."
fi

echo ""

# ── Step processor ────────────────────────────────────────────────────────────

update_step() {
  STEP="$1"
  STATUS="$2"
  OUTPUT="$3"
  TS="$4"

  if [ -n "$TS" ]; then
    jq --arg s "$STEP" --arg st "$STATUS" --arg out "$OUTPUT" --arg ts "$TS" \
      '.steps[$s] = {"status": $st, "output": $out, "completed_at": $ts}' \
      "$LOCK_FILE" > /tmp/spec_lock_tmp.json && mv /tmp/spec_lock_tmp.json "$LOCK_FILE"
  else
    jq --arg s "$STEP" --arg st "$STATUS" --arg out "$OUTPUT" \
      '.steps[$s] = {"status": $st, "output": $out}' \
      "$LOCK_FILE" > /tmp/spec_lock_tmp.json && mv /tmp/spec_lock_tmp.json "$LOCK_FILE"
  fi
}

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
      printf "  ✔ %s already exists — skipping\n" "$DISPLAY_LABEL"
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
      # Apply skip-if-exists: output file present and non-empty
      if [ -f "$OUTPUT_FILE" ] && [ -s "$OUTPUT_FILE" ]; then
        printf "  ✔ %s already exists — skipping\n" "$DISPLAY_LABEL"
        update_step "$STEP_NAME" "skipped" "$OUTPUT_FILE" "$NOW"
      else
        printf "  ○ %s — pending\n" "$DISPLAY_LABEL"
        update_step "$STEP_NAME" "pending" "$OUTPUT_FILE" ""
      fi
      ;;
  esac
}

# ── Standard steps ────────────────────────────────────────────────────────────

check_step "generate_prd"             "docs/analysis/prd.md"          "PRD"
check_step "generate_capabilities"    "docs/analysis/capabilities.md" "Capability map"
check_step "generate_domain"          "docs/domain/model.md"          "Domain model"
check_step "generate_rbac"            "docs/domain/rbac.md"           "RBAC policy"
check_step "generate_workflows"       "docs/domain/workflows.md"      "Workflows"
check_step "generate_design_workflow" "docs/design/overview.md"       "Design overview"
check_step "generate_ia"              "docs/design/ia.md"             "Information architecture"
check_step "generate_flows"           "docs/design/flows.md"          "User flows"
check_step "generate_spec"            "docs/spec/api.md"              "API spec"
check_step "generate_skills"          ".github/skills/"               "Dev skills"
check_step "generate_scripts"         "scripts/"                      "Operational scripts"

# ── ADLC steps (if enabled) ───────────────────────────────────────────────────

if [ "$ADLC" = "true" ]; then
  echo ""
  echo "ADLC steps:"
  check_step "generate_kpis"            "docs/adlc/kpis.md"            "KPIs"
  check_step "generate_human_agent_map" "docs/adlc/human-agent-map.md" "Human-agent map"
  check_step "generate_agent_pattern"   "docs/adlc/agent-pattern.md"   "Agent pattern"
  check_step "generate_cost_model"      "docs/adlc/cost-model.md"      "Cost model"
  check_step "generate_eval_framework"  "docs/adlc/eval-framework.md"  "Evaluation framework"
  check_step "generate_pov"             "docs/adlc/pov-plan.md"        "PoV plan"
  check_step "generate_monitoring"      "docs/adlc/monitoring.md"      "Monitoring spec"
  check_step "generate_governance"      "docs/adlc/governance.md"      "Governance spec"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────

PENDING=$(jq '[.steps | to_entries[] | select(.value.status == "pending" or .value.status == "in_progress")] | length' "$LOCK_FILE")
DONE=$(jq '[.steps | to_entries[] | select(.value.status == "completed" or .value.status == "skipped")] | length' "$LOCK_FILE")
FAILED=$(jq '[.steps | to_entries[] | select(.value.status == "failed")] | length' "$LOCK_FILE")
TOTAL=$(jq '.steps | length' "$LOCK_FILE")

echo "Pipeline lock: $LOCK_FILE"

if [ "$FAILED" -gt 0 ]; then
  echo ""
  echo "Pipeline has $FAILED failed step(s). Fix the issue and re-run 'copilot-bootstrap spec'."
  exit 1
fi

if [ "$PENDING" -eq 0 ]; then
  echo "All spec steps complete ($DONE/$TOTAL)."
  echo ""
  echo "Running generators..."
  echo ""
  copilot-bootstrap generate
  exit 0
fi

echo "Status: $DONE/$TOTAL steps complete, $PENDING pending."
echo ""
echo "Use the '#run-spec-pipeline' skill in Copilot Chat to run the full pipeline automatically."

#!/bin/sh
# interview.sh — Greenfield interview launcher
#
# Initializes .greenfield/ state, checks interview progress, and instructs
# the AI agent to run the smart greenfield interview via bootstrap-ask skill.
#
# Usage: copilot-bootstrap interview

set -e

GREENFIELD_DIR=".greenfield"
ANSWERS_FILE="$GREENFIELD_DIR/answers.json"
PROJECT_FILE="project.json"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap interview"
  echo ""
  echo "Runs the smart greenfield interview to collect project answers."
  echo "Produces .greenfield/answers.json with normalized structured data."
  echo ""
  echo "Interview steps:"
  echo "  1. idea         — project idea and pain points"
  echo "  2. project_info — name, type, domain"
  echo "  3. users        — user roles and descriptions"
  echo "  4. features     — core features with priority"
  echo "  5. tech         — stack choices with smart defaults"
  echo "  6. complexity   — complexity level and autonomy"
  echo ""
  echo "After interview, run: copilot-bootstrap build-context"
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────────────────────

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

# ── Setup ─────────────────────────────────────────────────────────────────────

mkdir -p "$GREENFIELD_DIR"

# Initialize answers.json if not present
if [ ! -f "$ANSWERS_FILE" ]; then
  jq -n '{
    "collected_at": null,
    "steps_completed": []
  }' > "$ANSWERS_FILE"
fi

# ── Check prerequisite: project must be initialized ───────────────────────────

if [ ! -f "$PROJECT_FILE" ]; then
  echo "Error: project.json not found. Run 'copilot-bootstrap init' first."
  exit 1
fi

APPROACH=$(jq -r '.approach // ""' "$PROJECT_FILE")

# ── Check interview progress ──────────────────────────────────────────────────

STEPS="idea project_info users features tech complexity"
COMPLETED=$(jq -r '.steps_completed // [] | join(" ")' "$ANSWERS_FILE" 2>/dev/null || echo "")
TOTAL_STEPS=6
DONE_COUNT=0

echo "Greenfield interview status"
echo ""

for step in $STEPS; do
  case " $COMPLETED " in
    *" $step "*)
      printf "  ✔ %s\n" "$step"
      DONE_COUNT=$((DONE_COUNT + 1))
      ;;
    *)
      printf "  ○ %s\n" "$step"
      ;;
  esac
done

echo ""

# ── Determine what to do ──────────────────────────────────────────────────────

if [ "$DONE_COUNT" -eq "$TOTAL_STEPS" ]; then
  echo "Interview complete ($DONE_COUNT/$TOTAL_STEPS steps)."
  echo ""
  echo "Run 'copilot-bootstrap build-context' to build context.json, decisions.json, and scope.json."
  exit 0
fi

REMAINING=$((TOTAL_STEPS - DONE_COUNT))
echo "Progress: $DONE_COUNT/$TOTAL_STEPS steps complete. $REMAINING step(s) remaining."
echo ""

# ── Update project.json to greenfield approach if not set ─────────────────────

if [ "$APPROACH" != "greenfield" ]; then
  jq '.approach = "greenfield"' "$PROJECT_FILE" > /tmp/proj_tmp.json && mv /tmp/proj_tmp.json "$PROJECT_FILE"
fi

# ── Emit instructions for the AI agent ───────────────────────────────────────

echo "Running greenfield interview..."
echo ""
echo "Use the '#bootstrap-ask' skill in Copilot Chat to conduct the interview."
echo "The skill will ask only the missing questions and save answers to:"
echo "  .greenfield/answers.json  (structured format)"
echo "  .project/state/answers.json  (legacy format)"
echo ""
echo "Interview steps to complete:"

for step in $STEPS; do
  case " $COMPLETED " in
    *" $step "*) ;;
    *) printf "  - %s\n" "$step" ;;
  esac
done

echo ""
echo "After all steps complete, run: copilot-bootstrap build-context"

#!/bin/sh
# init.sh — Initialise bootstrap workflow state
#
# Usage: ./scripts/init.sh [--brownfield|--greenfield]

set -e

WORKFLOW_FILE=".project/state/workflow.json"
ANSWERS_FILE=".project/state/answers.json"
PROJECT_FILE="project.json"

if [ "$1" = "--help" ]; then
  echo "Usage: ./scripts/init.sh [--brownfield|--greenfield]"
  echo ""
  echo "  --brownfield   Initialise for an existing codebase (next step: scan)"
  echo "  --greenfield   Initialise for a new project (default, next step: idea)"
  echo ""
  echo "Exits with error if state already exists. Run 'redo' to reinitialise."
  exit 0
fi

# Determine approach
APPROACH="greenfield"
STEP="idea"

case "$1" in
  --brownfield)
    APPROACH="brownfield"
    STEP="scan"
    ;;
  --greenfield|"")
    APPROACH="greenfield"
    STEP="idea"
    ;;
  *)
    echo "Error: unknown option '$1'. Use --brownfield or --greenfield." >&2
    exit 1
    ;;
esac

if [ -f "$WORKFLOW_FILE" ]; then
  echo "Error: $WORKFLOW_FILE already exists. Delete it first to reinitialise."
  exit 1
fi

mkdir -p .project/state .discovery docs/workflow docs/analysis docs/design docs/domain docs/spec docs/discovery docs/ops scripts

if [ -n "$COPILOT_BOOTSTRAP_HOME" ]; then
  [ -d "$COPILOT_BOOTSTRAP_HOME/docs" ] && cp -r --update=none "$COPILOT_BOOTSTRAP_HOME/docs/." docs/ 2>/dev/null || cp -rn "$COPILOT_BOOTSTRAP_HOME/docs/." docs/
  [ -d "$COPILOT_BOOTSTRAP_HOME/.github" ] && cp -r --update=none "$COPILOT_BOOTSTRAP_HOME/.github/." .github/ 2>/dev/null || cp -rn "$COPILOT_BOOTSTRAP_HOME/.github/." .github/
  if [ -f "$COPILOT_BOOTSTRAP_HOME/.vscode/mcp.json" ]; then
    mkdir -p .vscode
    cp --update=none "$COPILOT_BOOTSTRAP_HOME/.vscode/mcp.json" .vscode/mcp.json 2>/dev/null || cp -n "$COPILOT_BOOTSTRAP_HOME/.vscode/mcp.json" .vscode/mcp.json
  fi
fi

cat > "$WORKFLOW_FILE" <<EOF
{
  "workflow": "bootstrap",
  "approach": "$APPROACH",
  "step": "$STEP",
  "status": "in_progress"
}
EOF

cat > "$ANSWERS_FILE" <<EOF
{}
EOF

cat > "$PROJECT_FILE" <<EOF
{
  "name": "",
  "type": "",
  "domain": "",
  "approach": "$APPROACH",
  "codebase_path": "",
  "stage": "bootstrap",
  "workflow": "bootstrap",
  "step": "$STEP",
  "autonomy_level": "",
  "adlc": false
}
EOF

if [ "$APPROACH" = "greenfield" ]; then
  mkdir -p .greenfield
  cat > ".greenfield/answers.json" <<EOF
{
  "collected_at": "",
  "steps_completed": []
}
EOF
fi

if [ "$APPROACH" = "brownfield" ]; then
  echo "Brownfield project initialised."
  echo ""
  echo "Next:"
  echo "  copilot-bootstrap scan       — auto-detect your stack"
  echo "  copilot-bootstrap discover   — extract capabilities from the codebase"
  echo "  copilot-bootstrap generate   — generate Copilot configuration"
else
  echo "Greenfield project initialised."
  echo ""
  echo "Next: start the interview"
  echo "  copilot-bootstrap interview"
fi

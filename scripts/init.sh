#!/bin/sh
# init.sh — Initialise bootstrap workflow state
#
# Usage: ./scripts/init.sh

set -e

WORKFLOW_FILE=".project/state/workflow.json"
ANSWERS_FILE=".project/state/answers.json"
PROJECT_FILE="project.json"

if [ "$1" = "--help" ]; then
  echo "Usage: ./scripts/init.sh"
  echo "Initialises .project/state/ for a new bootstrap workflow."
  echo "Exits with error if state already exists."
  exit 0
fi

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
  "approach": "",
  "step": "idea",
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
  "approach": "",
  "codebase_path": "",
  "stage": "bootstrap",
  "workflow": "bootstrap",
  "step": "idea",
  "autonomy_level": "",
  "adlc": false
}
EOF

echo "Bootstrap workflow initialised. Current step: idea"

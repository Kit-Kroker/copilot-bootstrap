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

mkdir -p .project/state docs/workflow docs/analysis docs/design docs/domain docs/spec scripts

if [ -n "$COPILOT_BOOTSTRAP_HOME" ] && [ -d "$COPILOT_BOOTSTRAP_HOME/docs" ]; then
  cp -rn "$COPILOT_BOOTSTRAP_HOME/docs/." docs/
fi

cat > "$WORKFLOW_FILE" <<EOF
{
  "workflow": "bootstrap",
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
  "stage": "bootstrap",
  "workflow": "bootstrap",
  "step": "idea"
}
EOF

echo "Bootstrap workflow initialised. Current step: idea"

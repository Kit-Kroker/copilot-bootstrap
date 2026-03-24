#!/bin/sh
# step.sh — Read or set the current workflow step
#
# Usage:
#   ./scripts/step.sh             Print current step
#   ./scripts/step.sh <step>      Jump to a specific step
#   ./scripts/step.sh --list      List all steps

set -e

WORKFLOW_FILE=".project/state/workflow.json"

# Determine workflow doc based on approach (greenfield vs brownfield)
APPROACH=""
if [ -f "$WORKFLOW_FILE" ] && command -v jq > /dev/null 2>&1; then
  APPROACH=$(jq -r '.approach // ""' "$WORKFLOW_FILE")
fi

if [ "$APPROACH" = "brownfield" ]; then
  DOC_NAME="brownfield.md"
else
  DOC_NAME="bootstrap.md"
fi

if [ -f "docs/workflow/$DOC_NAME" ]; then
  BOOTSTRAP_DOC="docs/workflow/$DOC_NAME"
elif [ -n "$COPILOT_BOOTSTRAP_HOME" ] && [ -f "$COPILOT_BOOTSTRAP_HOME/docs/workflow/$DOC_NAME" ]; then
  BOOTSTRAP_DOC="$COPILOT_BOOTSTRAP_HOME/docs/workflow/$DOC_NAME"
else
  echo "Error: docs/workflow/$DOC_NAME not found. Run 'copilot-bootstrap init' first."
  exit 1
fi

if [ "$1" = "--help" ]; then
  echo "Usage:"
  echo "  ./scripts/step.sh           Print current step and status"
  echo "  ./scripts/step.sh <step>    Set workflow to a specific step"
  echo "  ./scripts/step.sh --list    List all valid steps"
  exit 0
fi

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "Error: $WORKFLOW_FILE not found. Run ./scripts/init.sh first."
  exit 1
fi

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required."
  exit 1
fi

if [ "$1" = "--list" ]; then
  echo "Bootstrap steps:"
  grep -E '^[0-9]+\.' "$BOOTSTRAP_DOC" | sed 's/^/  /'
  exit 0
fi

if [ -z "$1" ]; then
  STEP=$(jq -r '.step' "$WORKFLOW_FILE")
  STATUS=$(jq -r '.status' "$WORKFLOW_FILE")
  echo "Current step: $STEP ($STATUS)"
  exit 0
fi

TARGET="$1"
VALID=$(grep -E '^[0-9]+\.' "$BOOTSTRAP_DOC" | sed 's/^[0-9]*\. *//' | grep -x "$TARGET" || true)

if [ -z "$VALID" ]; then
  echo "Error: '$TARGET' is not a valid step. Run --list to see valid steps."
  exit 1
fi

jq --arg step "$TARGET" '.step = $step | .status = "in_progress"' "$WORKFLOW_FILE" > /tmp/wf_tmp.json
mv /tmp/wf_tmp.json "$WORKFLOW_FILE"

jq --arg step "$TARGET" '.step = $step' project.json > /tmp/proj_tmp.json
mv /tmp/proj_tmp.json project.json

echo "Step set to: $TARGET"

#!/bin/sh
# next.sh — Advance to the next bootstrap step
#
# Usage: ./scripts/next.sh

set -e

WORKFLOW_FILE=".project/state/workflow.json"
if [ -f "docs/workflow/bootstrap.md" ]; then
  BOOTSTRAP_DOC="docs/workflow/bootstrap.md"
elif [ -n "$COPILOT_BOOTSTRAP_HOME" ] && [ -f "$COPILOT_BOOTSTRAP_HOME/docs/workflow/bootstrap.md" ]; then
  BOOTSTRAP_DOC="$COPILOT_BOOTSTRAP_HOME/docs/workflow/bootstrap.md"
else
  echo "Error: docs/workflow/bootstrap.md not found. Run 'copilot-bootstrap init' first."
  exit 1
fi

if [ "$1" = "--help" ]; then
  echo "Usage: ./scripts/next.sh"
  echo "Advances workflow.json to the next step in bootstrap.md."
  exit 0
fi

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "Error: $WORKFLOW_FILE not found. Run ./scripts/init.sh first."
  exit 1
fi

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

CURRENT=$(jq -r '.step' "$WORKFLOW_FILE")

FOUND=0
NEXT=""
while IFS= read -r line; do
  case "$line" in
    [0-9]*\.*)
      STEP=$(echo "$line" | sed 's/^[0-9]*\. *//')
      if [ "$FOUND" = "1" ]; then
        NEXT="$STEP"
        break
      fi
      if [ "$STEP" = "$CURRENT" ]; then
        FOUND=1
      fi
      ;;
  esac
done < "$BOOTSTRAP_DOC"

if [ -z "$NEXT" ]; then
  echo "Workflow is already at the final step: $CURRENT"
  exit 0
fi

jq --arg step "$NEXT" '.step = $step | .status = "in_progress"' "$WORKFLOW_FILE" > /tmp/wf_tmp.json
mv /tmp/wf_tmp.json "$WORKFLOW_FILE"

jq --arg step "$NEXT" '.step = $step' project.json > /tmp/proj_tmp.json
mv /tmp/proj_tmp.json project.json

echo "Advanced: $CURRENT → $NEXT"

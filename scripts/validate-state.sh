#!/bin/sh
# validate-state.sh — Validate workflow state files after agent edits
#
# Called by PostToolUse hooks. Exits 0 if valid, 1 with error message if not.

set -e

WORKFLOW_FILE=".project/state/workflow.json"
ANSWERS_FILE=".project/state/answers.json"

ERRORS=0

# Check workflow.json exists and is valid JSON
if [ -f "$WORKFLOW_FILE" ]; then
  if ! jq empty "$WORKFLOW_FILE" 2>/dev/null; then
    echo "ERROR: $WORKFLOW_FILE is not valid JSON"
    ERRORS=$((ERRORS + 1))
  else
    # Check required fields
    STEP=$(jq -r '.step // empty' "$WORKFLOW_FILE")
    STATUS=$(jq -r '.status // empty' "$WORKFLOW_FILE")
    WORKFLOW=$(jq -r '.workflow // empty' "$WORKFLOW_FILE")

    if [ -z "$STEP" ]; then
      echo "ERROR: $WORKFLOW_FILE missing required field: step"
      ERRORS=$((ERRORS + 1))
    fi
    if [ -z "$STATUS" ]; then
      echo "ERROR: $WORKFLOW_FILE missing required field: status"
      ERRORS=$((ERRORS + 1))
    fi
    if [ -z "$WORKFLOW" ]; then
      echo "ERROR: $WORKFLOW_FILE missing required field: workflow"
      ERRORS=$((ERRORS + 1))
    fi

    # Check status is a valid value
    case "$STATUS" in
      in_progress|completed|blocked) ;;
      *)
        echo "ERROR: $WORKFLOW_FILE invalid status: '$STATUS' (must be in_progress, completed, or blocked)"
        ERRORS=$((ERRORS + 1))
        ;;
    esac
  fi
fi

# Check answers.json exists and is valid JSON
if [ -f "$ANSWERS_FILE" ]; then
  if ! jq empty "$ANSWERS_FILE" 2>/dev/null; then
    echo "ERROR: $ANSWERS_FILE is not valid JSON"
    ERRORS=$((ERRORS + 1))
  fi
fi

# Check project.json step matches workflow.json step
if [ -f "project.json" ] && [ -f "$WORKFLOW_FILE" ]; then
  PROJ_STEP=$(jq -r '.step // empty' project.json 2>/dev/null)
  WF_STEP=$(jq -r '.step // empty' "$WORKFLOW_FILE" 2>/dev/null)
  if [ -n "$PROJ_STEP" ] && [ -n "$WF_STEP" ] && [ "$PROJ_STEP" != "$WF_STEP" ]; then
    echo "WARNING: project.json step ('$PROJ_STEP') does not match workflow.json step ('$WF_STEP')"
  fi
fi

if [ "$ERRORS" -gt 0 ]; then
  echo "State validation failed with $ERRORS error(s)."
  exit 1
fi

exit 0

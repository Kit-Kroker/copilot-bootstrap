#!/bin/sh
# ask.sh — Print questions for a bootstrap step
#
# Usage:
#   ./scripts/ask.sh              Questions for current step
#   ./scripts/ask.sh <step>       Questions for a specific step

set -e

WORKFLOW_FILE=".project/state/workflow.json"
ANSWERS_FILE=".project/state/answers.json"

if [ "$1" = "--help" ]; then
  echo "Usage:"
  echo "  ./scripts/ask.sh           Print questions for the current step"
  echo "  ./scripts/ask.sh <step>    Print questions for a specific step"
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

STEP="${1:-$(jq -r '.step' "$WORKFLOW_FILE")}"

echo "Questions for step: $STEP"
echo ""

case "$STEP" in
  idea)
    echo "  - What is your project idea? Describe it in a few sentences."
    ;;
  project_info)
    echo "  - What is the project name?"
    echo "  - What type of project is it? (web app / mobile app / API / CLI / other)"
    echo "  - What domain does it belong to?"
    ;;
  users)
    echo "  - Who are the users of this system?"
    echo "  - What roles do they have?"
    ;;
  features)
    echo "  - What are the core features? List 3 to 10."
    ;;
  tech)
    echo "  - What backend technology will you use?"
    echo "  - What frontend technology will you use?"
    echo "  - Any database or infrastructure preferences?"
    ;;
  complexity)
    echo "  - How complex is this project?"
    echo "    simple     — single team, no integrations"
    echo "    saas       — multi-tenant, subscriptions, external integrations"
    echo "    enterprise — large org, RBAC, compliance, many integrations"
    ;;
  *)
    echo "  No predefined questions for step '$STEP'."
    echo "  Check docs/workflow/bootstrap.md for guidance."
    ;;
esac

echo ""
echo "Answers saved in: $ANSWERS_FILE"
ANSWERED=$(jq --arg s "$STEP" 'has($s)' "$ANSWERS_FILE" 2>/dev/null || echo "false")
echo "Step answered: $ANSWERED"

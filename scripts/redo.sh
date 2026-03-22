#!/bin/sh
# redo.sh — Revert to the previous workflow step and delete its generated output
#
# Usage: copilot-bootstrap redo [--dry-run]

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
  echo "Usage: copilot-bootstrap redo [--dry-run]"
  echo "Reverts to the previous workflow step and deletes its generated output files."
  echo ""
  echo "Options:"
  echo "  --dry-run   Show what would be deleted without making changes"
  exit 0
fi

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "Error: $WORKFLOW_FILE not found. Run 'copilot-bootstrap init' first."
  exit 1
fi

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

DRY_RUN=0
if [ "$1" = "--dry-run" ]; then
  DRY_RUN=1
fi

CURRENT=$(jq -r '.step' "$WORKFLOW_FILE")

# Find the previous step from bootstrap.md
PREV=""
LAST=""
while IFS= read -r line; do
  case "$line" in
    [0-9]*\.*)
      STEP=$(echo "$line" | sed 's/^[0-9]*\. *//')
      if [ "$STEP" = "$CURRENT" ]; then
        PREV="$LAST"
        break
      fi
      LAST="$STEP"
      ;;
  esac
done < "$BOOTSTRAP_DOC"

if [ -z "$PREV" ]; then
  echo "Already at the first step: $CURRENT. Nothing to redo."
  exit 0
fi

# Map each step to the output files it generates
outputs_for_step() {
  case "$1" in
    prd)              echo "docs/analysis/prd.md" ;;
    capabilities)     echo "docs/analysis/capabilities.md" ;;
    domain)           echo "docs/domain/model.md" ;;
    rbac)             echo "docs/domain/rbac.md" ;;
    workflow)         echo "docs/domain/workflows.md" ;;
    integration)      echo "docs/domain/integrations.md" ;;
    metrics)          echo "docs/analysis/metrics.md" ;;
    ia)               echo "docs/design/ia.md" ;;
    flows)            echo "docs/design/flows.md" ;;
    wireframes)       echo "docs/design/wireframes.md" ;;
    stitch)           echo "docs/design/screens" ;;
    ux)               echo "docs/design/ux.md" ;;
    design-system)    echo "docs/design/design-system.md" ;;
    spec)             echo "docs/spec/design-spec.md" ;;
    design_workflow)  echo "docs/workflow/design.md docs/design/overview.md" ;;
    skills)           echo "docs/workflow/agents.md" ;;
    scripts)          echo "scripts/generated" ;;
    *)                echo "" ;;
  esac
}

OUTPUTS=$(outputs_for_step "$CURRENT")

echo "Redo: $CURRENT → $PREV"
echo ""

if [ -z "$OUTPUTS" ]; then
  echo "No tracked output files for step '$CURRENT'."
else
  echo "Output files to delete:"
  for f in $OUTPUTS; do
    if [ -e "$f" ]; then
      echo "  $f"
    else
      echo "  $f (not found — skipping)"
    fi
  done
fi

echo ""

if [ "$DRY_RUN" = "1" ]; then
  echo "Dry run — no changes made."
  exit 0
fi

# Confirm
printf "Proceed? [y/N] "
read -r CONFIRM
case "$CONFIRM" in
  y|Y) ;;
  *)
    echo "Aborted."
    exit 0
    ;;
esac

# Delete output files
for f in $OUTPUTS; do
  if [ -d "$f" ]; then
    rm -rf "$f"
    echo "Deleted directory: $f"
  elif [ -f "$f" ]; then
    rm "$f"
    echo "Deleted: $f"
  fi
done

# Step back
jq --arg step "$PREV" '.step = $step | .status = "in_progress"' "$WORKFLOW_FILE" > /tmp/wf_tmp.json
mv /tmp/wf_tmp.json "$WORKFLOW_FILE"

if [ -f "project.json" ]; then
  jq --arg step "$PREV" '.step = $step' project.json > /tmp/proj_tmp.json
  mv /tmp/proj_tmp.json project.json
fi

echo "Step reverted to: $PREV"

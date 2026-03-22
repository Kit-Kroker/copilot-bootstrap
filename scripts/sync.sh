#!/bin/sh
# sync.sh — Sync framework files from the installed package into the current project
#
# Updates .github/ and docs/workflow/ with the latest versions from the package.
# Does NOT touch .project/state/, project.json, or user-created docs.
#
# Usage: copilot-bootstrap sync

set -e

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap sync"
  echo "Updates .github/ and docs/workflow/ from the installed package."
  echo "Does not touch .project/state/ or project.json."
  exit 0
fi

if [ -z "$COPILOT_BOOTSTRAP_HOME" ]; then
  echo "Error: COPILOT_BOOTSTRAP_HOME is not set. Run via 'copilot-bootstrap sync'."
  exit 1
fi

if [ ! -f "project.json" ] && [ ! -f ".project/state/workflow.json" ]; then
  echo "Error: no copilot-bootstrap project found here. Run 'copilot-bootstrap init' first."
  exit 1
fi

echo "Syncing framework files from $COPILOT_BOOTSTRAP_HOME ..."

[ -d "$COPILOT_BOOTSTRAP_HOME/.github" ] && cp -r "$COPILOT_BOOTSTRAP_HOME/.github/." .github/
[ -d "$COPILOT_BOOTSTRAP_HOME/docs/workflow" ] && cp -r "$COPILOT_BOOTSTRAP_HOME/docs/workflow/." docs/workflow/
[ -f "$COPILOT_BOOTSTRAP_HOME/.vscode/mcp.json" ] && mkdir -p .vscode && cp "$COPILOT_BOOTSTRAP_HOME/.vscode/mcp.json" .vscode/mcp.json

echo "Sync complete. State files and project.json were not changed."

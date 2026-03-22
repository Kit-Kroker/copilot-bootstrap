---
name: generate-scripts
description: Generate POSIX shell helper scripts for operating the bootstrap workflow. Use this when the workflow step is "scripts". Produces init.sh, next.sh, step.sh, and ask.sh under scripts/.
argument-hint: "[script to generate: init | next | step | ask | all]"
---

# Skill Instructions

Read:
- `.project/state/workflow.json`
- `.project/state/answers.json`
- `docs/workflow/bootstrap.md`

Generate four scripts under `scripts/`. All scripts must be:
- POSIX shell compatible (`#!/bin/sh`)
- Idempotent where possible
- Include a `--help` flag with usage output
- Validate inputs before acting
- Print clear success/error messages

---

## 1. `scripts/init.sh`

Initialises a fresh project state. Safe to run on an existing project — prints a warning and exits if state already exists.

```sh
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
```

---

## 2. `scripts/next.sh`

Advances the workflow to the next step. Reads `docs/workflow/bootstrap.md` to determine the sequence.

```sh
#!/bin/sh
# next.sh — Advance to the next bootstrap step
#
# Usage: ./scripts/next.sh

set -e

WORKFLOW_FILE=".project/state/workflow.json"
BOOTSTRAP_DOC="docs/workflow/bootstrap.md"

if [ "$1" = "--help" ]; then
  echo "Usage: ./scripts/next.sh"
  echo "Advances workflow.json to the next step in bootstrap.md."
  exit 0
fi

if [ ! -f "$WORKFLOW_FILE" ]; then
  echo "Error: $WORKFLOW_FILE not found. Run ./scripts/init.sh first."
  exit 1
fi

# Extract current step (requires jq)
if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

CURRENT=$(jq -r '.step' "$WORKFLOW_FILE")

# Build ordered step list from bootstrap.md
STEPS=$(grep -E '^[0-9]+\.' "$BOOTSTRAP_DOC" | sed 's/^[0-9]*\. *//')

FOUND=0
NEXT=""
for STEP in $STEPS; do
  if [ "$FOUND" = "1" ]; then
    NEXT="$STEP"
    break
  fi
  if [ "$STEP" = "$CURRENT" ]; then
    FOUND=1
  fi
done

if [ -z "$NEXT" ]; then
  echo "Workflow is already at the final step: $CURRENT"
  exit 0
fi

jq --arg step "$NEXT" '.step = $step | .status = "in_progress"' "$WORKFLOW_FILE" > /tmp/wf_tmp.json
mv /tmp/wf_tmp.json "$WORKFLOW_FILE"

jq --arg step "$NEXT" '.step = $step' project.json > /tmp/proj_tmp.json
mv /tmp/proj_tmp.json project.json

echo "Advanced: $CURRENT → $NEXT"
```

---

## 3. `scripts/step.sh`

Prints or sets the current workflow step.

```sh
#!/bin/sh
# step.sh — Read or set the current workflow step
#
# Usage:
#   ./scripts/step.sh             Print current step
#   ./scripts/step.sh <step>      Jump to a specific step
#   ./scripts/step.sh --list      List all steps

set -e

WORKFLOW_FILE=".project/state/workflow.json"
BOOTSTRAP_DOC="docs/workflow/bootstrap.md"

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
```

---

## 4. `scripts/ask.sh`

Prints the questions for the current or specified step, so the user knows what data is needed.

```sh
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
    echo "    simple    — single team, no integrations"
    echo "    saas      — multi-tenant, subscriptions, external integrations"
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
```

---

After generating all four scripts:
- Make scripts executable: each should include a note to run `chmod +x scripts/*.sh`
- Update `.project/state/workflow.json`: set `step` to `done`, `status` to `completed`
- Update `project.json` `stage` to `ready`

---
name: init
description: Initialize a new copilot-bootstrap project. Creates project.json, workflow state, and directory structure. Pass "brownfield" to initialize for an existing codebase; defaults to greenfield.
tools: ['read', 'edit']
argument-hint: "[greenfield|brownfield] — defaults to greenfield"
---

Initialize a new copilot-bootstrap project in the current workspace.

## Pre-flight

Check if `.project/state/workflow.json` already exists.
- If it exists, stop: "Project already initialized. Current step: {step from workflow.json}. Run `/reset` to start over."

## Determine approach

If the user passed `brownfield` as an argument, set:
- `approach = "brownfield"`
- `step = "scan"`

Otherwise (no argument or `greenfield`), set:
- `approach = "greenfield"`
- `step = "idea"`

## Create files

### `.project/state/workflow.json`

**Greenfield:**
```json
{
  "workflow": "bootstrap",
  "approach": "greenfield",
  "step": "idea",
  "status": "in_progress"
}
```

**Brownfield:**
```json
{
  "workflow": "bootstrap",
  "approach": "brownfield",
  "step": "scan",
  "status": "in_progress"
}
```

### `.project/state/answers.json`
```json
{}
```

### `project.json`

**Greenfield:**
```json
{
  "name": "",
  "type": "",
  "domain": "",
  "approach": "greenfield",
  "codebase_path": "",
  "stage": "bootstrap",
  "workflow": "bootstrap",
  "step": "idea",
  "autonomy_level": "",
  "adlc": false
}
```

**Brownfield:**
```json
{
  "name": "",
  "type": "",
  "domain": "",
  "approach": "brownfield",
  "codebase_path": "",
  "stage": "bootstrap",
  "workflow": "bootstrap",
  "step": "scan",
  "autonomy_level": "",
  "adlc": false
}
```

### `.greenfield/answers.json` (greenfield only — skip for brownfield)
```json
{
  "collected_at": "",
  "steps_completed": []
}
```

## Confirm

**Greenfield:**
```
Greenfield project initialized.

Next: start the interview
  /bootstrap idea: <your project idea>
```

**Brownfield:**
```
Brownfield project initialized.

Next:
  /scan       — auto-detect your stack
  /discover   — extract capabilities from the codebase
  /generate   — generate Copilot configuration
```

---
name: init
description: Initialize a new copilot-bootstrap project. Creates project.json, workflow state, and directory structure. Run once before starting the bootstrap interview.
tools: ['read', 'edit']
argument-hint: "[greenfield|brownfield] — defaults to greenfield"
---

Initialize a new copilot-bootstrap project in the current workspace.

## Pre-flight

Check if `.project/state/workflow.json` already exists.
- If it exists, stop: "Project already initialized. Current step: {step from workflow.json}. Run `/bootstrap` to continue, or `/reset` to start over."

## Create files

Create these files exactly as shown:

### `.project/state/workflow.json`
```json
{
  "workflow": "bootstrap",
  "approach": "",
  "step": "idea",
  "status": "in_progress"
}
```

### `.project/state/answers.json`
```json
{}
```

### `project.json`
```json
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
```

### `.greenfield/answers.json`
```json
{
  "collected_at": "",
  "steps_completed": []
}
```

## Confirm

Print:
```
Bootstrap project initialized.

Next: start the interview
  /bootstrap idea: <your project idea>

For brownfield (existing codebase):
  /scan       — auto-detect your stack
  /bootstrap  — then describe your codebase
```

# copilot-bootstrap

A multi-agent workflow that takes a project idea and produces a full implementation-ready specification — PRD, domain model, RBAC, API spec, design artifacts, and dev scaffolding scripts — all driven by GitHub Copilot agents in VS Code.

## Install

```sh
uv tool install copilot-bootstrap --from git+https://github.com/Kit-Kroker/copilot-bootstrap.git
```

**Requirements:** `uv`, `jq`

## Quick Start

```sh
mkdir my-project && cd my-project
copilot-bootstrap init
code .
```

`init` copies all framework files (`.github/`, `docs/workflow/`, `.vscode/`) into the current directory and creates the initial workflow state. Then open in VS Code and use the **Bootstrap** Copilot agent to drive the workflow step by step.

## Commands

```sh
copilot-bootstrap init     # set up a new project (copies agents, prompts, skills)
copilot-bootstrap sync     # update framework files from the latest package version
copilot-bootstrap step     # show current step
copilot-bootstrap next     # advance to the next step
copilot-bootstrap ask      # print questions for the current step
copilot-bootstrap validate # validate state files
```

## Updating

To get the latest agents, prompts, and skills in an existing project:

```sh
uv tool install copilot-bootstrap --from git+https://github.com/Kit-Kroker/copilot-bootstrap.git --force
copilot-bootstrap sync
```

`sync` overwrites `.github/` and `docs/workflow/` from the updated package. It never touches `.project/state/` or `project.json`.

## Workflow Steps

| Step | Description |
|------|-------------|
| `idea` | Capture the initial project idea |
| `project_info` | Name, type, domain |
| `users` | User roles and target audience |
| `features` | Core features |
| `tech` | Backend, frontend, infrastructure |
| `complexity` | simple / saas / enterprise |
| `prd` | Generate Product Requirements Document |
| `capabilities` | System capabilities |
| `domain` | Domain model |
| `design_workflow` | Design artifacts |
| `skills` | Copilot skill definitions |
| `scripts` | Dev scaffolding scripts |
| `done` | Spec complete |

## File Structure

```
.github/
  agents/          # Copilot agent definitions
  prompts/         # Reusable prompt files
  skills/          # Copilot skill definitions
  copilot-instructions.md
.project/state/
  workflow.json    # Current step and status
  answers.json     # Collected answers per step
docs/workflow/     # Workflow and design documentation
project.json       # Project metadata
scripts/           # Shell scripts for state management
```

## VS Code Setup

The `.vscode/` directory includes pre-configured MCP and settings. Open the project folder directly in VS Code — no additional setup required.

## Manual

See [MANUAL.md](MANUAL.md) for full documentation including agents, slash commands, skills, and troubleshooting.

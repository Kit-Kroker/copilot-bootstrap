# Copilot Bootstrap — Manual

A multi-agent workflow that takes a project idea and produces a full implementation-ready specification: PRD, domain model, RBAC, API spec, design artifacts, and dev scaffolding scripts — all driven by GitHub Copilot agents in VS Code.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Quick Start](#2-quick-start)
3. [How It Works](#3-how-it-works)
4. [Workflow Steps](#4-workflow-steps)
5. [Agents](#5-agents)
6. [Slash Commands](#6-slash-commands)
7. [Skills](#7-skills)
8. [Scripts](#8-scripts)
9. [File Structure](#9-file-structure)
10. [Extending the Framework](#10-extending-the-framework)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Prerequisites

- **VS Code** with the **GitHub Copilot** extension installed and signed in
- **jq** installed (used by shell scripts): `apt install jq` / `brew install jq`
- VS Code setting enabled for hooks (optional):
  ```json
  "chat.useCustomAgentHooks": true
  ```

---

## 2. Quick Start

### Step 1 — Copy this repository into your new project

```sh
cp -r copilot-bootstrap/. my-project/
cd my-project
```

Or use it as-is by opening this folder in VS Code.

### Step 2 — Initialise state

```sh
./scripts/init.sh
```

This creates `.project/state/workflow.json` and `.project/state/answers.json` if they do not exist.

### Step 3 — Open Copilot Chat

In VS Code, open the Copilot Chat panel (`Ctrl+Alt+I` / `Cmd+Alt+I`).

### Step 4 — Select the Bootstrap agent

Click the agent selector in the chat input and choose **Bootstrap**.

### Step 5 — Start

Type your idea:

```
idea: a helpdesk system for managing customer support tickets
```

The agent will ask you questions one step at a time. When all answers are collected, click the **Generate PRD & Capabilities** handoff button to pass control to the next agent. Continue clicking handoff buttons as each phase completes.

### Done

When the Script agent finishes, all documents are generated and the workflow state is `done`. Open Copilot Chat and use `/scaffold-project` to start development.

---

## 3. How It Works

### Customization Layers

This framework uses all VS Code Copilot customization types:

| Layer | Location | Purpose |
|-------|----------|---------|
| Custom Instructions | `.github/copilot-instructions.md` | Always-on project context, loaded in every request |
| Prompt Files | `.github/prompts/*.prompt.md` | User-facing slash commands (`/status`, `/reset`, etc.) |
| Agent Skills | `.github/skills/*/SKILL.md` | Multi-step reusable workflows used by agents |
| Custom Agents | `.github/agents/*.agent.md` | Specialized personas with tools, models, and handoffs |
| Hooks | `PostToolUse` in agent frontmatter | Auto-validate state files after every agent edit |

### Agent Pipeline

Agents are chained via **handoff buttons**. Each agent completes its phase and presents a button that passes context to the next agent.

```
Bootstrap → Analyst → Architect → Designer → Spec → Script
```

### State Machine

Workflow progress is tracked in two files:

- `.project/state/workflow.json` — current step and status
- `.project/state/answers.json` — all collected answers

Both files are updated by agents after each step. The `project.json` root file mirrors the current step for quick reference.

### Dependency Chain

Each document depends on the previous phase:

```
answers.json
  └─► docs/analysis/prd.md
        └─► docs/analysis/capabilities.md
              └─► docs/domain/model.md
                    └─► docs/domain/rbac.md
                          └─► docs/domain/workflows.md
                                └─► docs/design/overview.md + ia.md + flows.md
                                      └─► docs/spec/api.md + events.md + permissions.md + state-machines.md
```

If a required input file is missing, the agent will report what needs to run first.

---

## 4. Workflow Steps

The bootstrap workflow has 13 steps defined in `docs/workflow/bootstrap.md`.

| # | Step | Agent | Output |
|---|------|-------|--------|
| 1 | `idea` | Bootstrap | answers.json: idea |
| 2 | `project_info` | Bootstrap | answers.json: project_info; project.json updated |
| 3 | `users` | Bootstrap | answers.json: users |
| 4 | `features` | Bootstrap | answers.json: features |
| 5 | `tech` | Bootstrap | answers.json: tech |
| 6 | `complexity` | Bootstrap | answers.json: complexity |
| 7 | `prd` | Analyst | docs/analysis/prd.md |
| 8 | `capabilities` | Analyst | docs/analysis/capabilities.md |
| 9 | `domain` | Architect | docs/domain/model.md, rbac.md, workflows.md |
| 10 | `design_workflow` | Designer | docs/design/overview.md, ia.md, flows.md |
| 11 | `skills` | Script | .github/skills/ (dev skill stubs) |
| 12 | `scripts` | Script | scripts/*.sh |
| 13 | `done` | — | Bootstrap complete |

### Questions Asked Per Step

| Step | Questions |
|------|-----------|
| `idea` | Describe your project idea |
| `project_info` | Name, type (web app / mobile / API / CLI), domain |
| `users` | Who are the users, what roles do they have |
| `features` | List 3–10 core features |
| `tech` | Backend, frontend, database/infra preferences |
| `complexity` | `simple` / `saas` / `enterprise` |

---

## 5. Agents

Agents are defined in `.github/agents/`. Select an agent in the Copilot Chat panel before typing.

### Bootstrap
**File:** `.github/agents/bootstrap.agent.md`
**Tools:** `read`, `edit`, `agent`
**Visible in chat:** Yes

Collects all project answers step by step. Asks only missing questions. Saves answers to `answers.json` after each step. When all six answer steps are complete, presents the **Generate PRD & Capabilities** handoff button.

**Hook:** Runs `./scripts/validate-state.sh` after every file edit to ensure `workflow.json` and `answers.json` remain valid JSON.

---

### Analyst
**File:** `.github/agents/analyst.agent.md`
**Tools:** `read`, `edit`
**Visible in chat:** No (called via handoff from Bootstrap)

Generates two analysis documents from `answers.json`:
1. `docs/analysis/prd.md` — Product Requirements Document
2. `docs/analysis/capabilities.md` — Capability map with dependencies and feature traceability

When done, presents the **Model Domain & Architecture** handoff button.

---

### Architect
**File:** `.github/agents/architect.agent.md`
**Tools:** `read`, `edit`
**Visible in chat:** No (called via handoff from Analyst)

Generates three domain architecture documents in order:
1. `docs/domain/model.md` — Entities, aggregates, bounded contexts, domain events
2. `docs/domain/rbac.md` — Roles, permission matrix, scope rules
3. `docs/domain/workflows.md` — Business workflows, state transitions, capability traceability

When done, presents the **Design Workflow & IA** handoff button.

---

### Designer
**File:** `.github/agents/designer.agent.md`
**Tools:** `read`, `edit`
**Visible in chat:** No (called via handoff from Architect)

Generates three design documents in order:
1. `docs/design/overview.md` — Design phases, deliverables, entry/exit criteria
2. `docs/design/ia.md` — Sitemap, navigation model, screen inventory, access rules
3. `docs/design/flows.md` — User flows with happy path, alternate paths, failure paths

When done, presents the **Generate Spec** handoff button.

---

### Spec
**File:** `.github/agents/spec.agent.md`
**Tools:** `read`, `edit`
**Visible in chat:** No (called via handoff from Designer)

Generates four specification files in a single pass:
1. `docs/spec/api.md` — REST API endpoints with auth, params, and responses
2. `docs/spec/events.md` — Domain event catalogue with payloads
3. `docs/spec/permissions.md` — Permission list and role assignments (`resource:action` format)
4. `docs/spec/state-machines.md` — State machines for all stateful entities

Uses consistent naming across all four files. When done, presents the **Generate Scripts & Dev Skills** handoff button.

---

### Script
**File:** `.github/agents/script.agent.md`
**Tools:** `read`, `edit`, `run`
**Visible in chat:** No (called via handoff from Spec)

Generates two things:

**Dev skill stubs** under `.github/skills/` — tailored to the project's tech stack:
- `scaffold-project` — always generated
- `generate-models` — always generated
- `generate-api` — always generated
- `generate-tests` — always generated
- `generate-components` + `generate-pages` — if frontend is not `none`
- `generate-auth` + `generate-tenant` — if complexity is `saas`
- `generate-rbac-impl` + `generate-audit-log` — if complexity is `enterprise`

**Operational scripts** — verifies `scripts/*.sh` exist and are executable.

Sets `workflow.json` step to `done` and `project.json` stage to `ready`.

**Hook:** Runs `./scripts/validate-state.sh` after every file edit.

---

## 6. Slash Commands

Type `/` in the Copilot Chat input to access these commands.

### `/bootstrap`
**File:** `.github/prompts/bootstrap.prompt.md`

Start or resume the bootstrap workflow. Routes to the Bootstrap agent from the current step.

```
/bootstrap
/bootstrap idea: inventory management system
```

---

### `/status`
**File:** `.github/prompts/status.prompt.md`

Print a dashboard showing current step, answers collected, and which output files exist.

```
/status
```

Example output:
```
Bootstrap Status
────────────────
Step:    prd (in_progress)

Answers collected:
  idea          ✅
  project_info  ✅
  users         ✅
  features      ✅
  tech          ✅
  complexity    ✅

Generated files:
  docs/analysis/prd.md           ❌ missing
  docs/analysis/capabilities.md  ❌ missing
  docs/domain/model.md           ❌ missing
  ...
```

---

### `/reset`
**File:** `.github/prompts/reset.prompt.md`

Jump the workflow to a specific step without deleting existing output files. Useful for re-running a phase after editing answers.

```
/reset prd
/reset domain
/reset spec
```

Valid step names: `idea`, `project_info`, `users`, `features`, `tech`, `complexity`, `prd`, `capabilities`, `domain`, `design_workflow`, `skills`, `scripts`, `done`.

---

### `/review-spec`
**File:** `.github/prompts/review-spec.prompt.md`

Cross-check all four spec files for consistency issues:
- Resource naming across `api.md`, `permissions.md`, `events.md`
- Permission coverage for every API endpoint
- Event coverage for every state transition
- Role name consistency with `rbac.md`
- State machine completeness for all stateful entities

```
/review-spec
```

---

## 7. Skills

Skills are reusable prompt workflows in `.github/skills/`. They are invoked by agents or directly via `/skill-name` in chat.

### Workflow Skills (internal)

| Skill | Purpose |
|-------|---------|
| `workflow-read` | Read current step and status from `workflow.json` |
| `workflow-update` | Update `workflow.json` and `project.json` after a step |
| `bootstrap-ask` | Ask only missing questions for the current step |
| `bootstrap-next` | Advance to the next step in `bootstrap.md` |

### Generation Skills

| Skill | Triggered at step | Output |
|-------|------------------|--------|
| `generate-prd` | `prd` | `docs/analysis/prd.md` |
| `generate-capabilities` | `capabilities` | `docs/analysis/capabilities.md` |
| `generate-domain` | `domain` | `docs/domain/model.md` |
| `generate-rbac` | `rbac` | `docs/domain/rbac.md` |
| `generate-workflows` | `workflow` | `docs/domain/workflows.md` |
| `generate-design-workflow` | `design_workflow` | `docs/workflow/design.md`, `docs/design/overview.md` |
| `generate-ia` | `ia` | `docs/design/ia.md` |
| `generate-flows` | `flows` | `docs/design/flows.md` |
| `generate-spec` | `spec` | `docs/spec/*.md` |
| `generate-skills` | `skills` | `.github/skills/` (dev stubs) |
| `generate-scripts` | `scripts` | `scripts/*.sh` |

---

## 8. Scripts

Shell scripts in `scripts/`. All require `jq`. Run `chmod +x scripts/*.sh` if needed.

### `init.sh`

Initialise a fresh project state. Safe — exits with an error if state already exists.

```sh
./scripts/init.sh
```

Creates:
- `.project/state/workflow.json` — step: `idea`, status: `in_progress`
- `.project/state/answers.json` — empty `{}`
- `project.json` — blank project metadata
- All output folders

---

### `next.sh`

Advance the workflow to the next step in `bootstrap.md`.

```sh
./scripts/next.sh
# Advanced: idea → project_info
```

---

### `step.sh`

Read or set the current workflow step.

```sh
./scripts/step.sh              # Print current step and status
./scripts/step.sh --list       # List all valid steps
./scripts/step.sh prd          # Jump to step "prd"
```

---

### `ask.sh`

Print the questions for the current or a specific step.

```sh
./scripts/ask.sh               # Questions for the current step
./scripts/ask.sh features      # Questions for the "features" step
```

---

### `validate-state.sh`

Validate `workflow.json` and `answers.json`. Called automatically by agent hooks after every file edit. Can also be run manually.

```sh
./scripts/validate-state.sh
```

Checks:
- Both files are valid JSON
- `workflow.json` has required fields: `workflow`, `step`, `status`
- `status` is one of: `in_progress`, `completed`, `blocked`
- `project.json` step matches `workflow.json` step

---

## 9. File Structure

```
.github/
  copilot-instructions.md         Always-on project context

  agents/
    bootstrap.agent.md            Collects answers, orchestrates pipeline
    analyst.agent.md              Generates PRD and capabilities
    architect.agent.md            Generates domain model, RBAC, workflows
    designer.agent.md             Generates design overview, IA, flows
    spec.agent.md                 Generates API, events, permissions, state machines
    script.agent.md               Generates dev skills and operational scripts

  prompts/
    bootstrap.prompt.md           /bootstrap — start or resume
    status.prompt.md              /status    — show current state
    reset.prompt.md               /reset     — jump to a step
    review-spec.prompt.md         /review-spec — validate spec consistency

  skills/
    workflow-read/SKILL.md        Read workflow state
    workflow-update/SKILL.md      Update workflow state
    bootstrap-ask/SKILL.md        Ask missing questions
    bootstrap-next/SKILL.md       Advance to next step
    generate-prd/SKILL.md         Generate PRD
    generate-capabilities/SKILL.md Generate capability map
    generate-domain/SKILL.md      Generate domain model
    generate-rbac/SKILL.md        Generate RBAC policy
    generate-workflows/SKILL.md   Generate business workflows
    generate-design-workflow/SKILL.md Generate design plan
    generate-ia/SKILL.md          Generate information architecture
    generate-flows/SKILL.md       Generate user flows
    generate-spec/SKILL.md        Generate implementation spec
    generate-skills/SKILL.md      Generate dev skill stubs
    generate-scripts/SKILL.md     Generate operational scripts

.project/
  state/
    workflow.json                 { workflow, step, status }
    answers.json                  { idea, project_info, users, features, tech, complexity }

docs/
  workflow/
    bootstrap.md                  13-step bootstrap sequence
    design.md                     13-step design sub-workflow
    agents.md                     Routing table: step → agent → skill
  analysis/
    prd.md                        Product Requirements Document
    capabilities.md               Capability map
  domain/
    model.md                      Entities, aggregates, domain events
    rbac.md                       Roles, permission matrix
    workflows.md                  Business workflows
  design/
    overview.md                   Design phases and deliverables
    ia.md                         Sitemap, navigation, screen inventory
    flows.md                      User flows
  spec/
    api.md                        REST API endpoints
    events.md                     Domain event catalogue
    permissions.md                Permission list and role assignments
    state-machines.md             State machines for stateful entities

scripts/
  init.sh                         Initialise project state
  next.sh                         Advance to next step
  step.sh                         Read or set current step
  ask.sh                          Print questions for a step
  validate-state.sh               Validate state file integrity

project.json                      Project metadata (name, type, domain, step)
```

---

## 10. Google Stitch Integration

Google Stitch is an AI UI design tool from Google Labs. It generates high-fidelity HTML + TailwindCSS screens from natural language prompts via an MCP server. It replaces the manual wireframe and hi-fi phases.

### Where it fits

```
flows.md  →  Stitch MCP  →  docs/design/screens/*.html  →  spec
```

The Designer agent calls Stitch after `flows.md` is complete. It generates screens for every entry in the IA screen inventory — default, empty, and error states.

### Setup (required before first use)

Full instructions: `docs/design/stitch-setup.md`

**Quick setup:**
```sh
# 1. Get an API key at stitch.withgoogle.com → account settings
# 2. Install the SDK
npm install @google/stitch-sdk

# 3. Set your API key
export STITCH_API_KEY=your-key-here
```

`.vscode/mcp.json` is already included — it runs `scripts/stitch-mcp.js` as the MCP server.
Restart VS Code, then type `#` in Copilot Chat and verify `stitch` tools appear.

Full instructions: `docs/design/stitch-setup.md`

### Usage

Stitch runs automatically in the Designer agent pipeline after flows are generated. To run it manually:

```
/stitch                      Generate all screens from ia.md
/stitch dashboard screen     Regenerate one specific screen
```

### Outputs

| File | Contents |
|------|----------|
| `docs/design/screens/{name}.html` | HTML + TailwindCSS screen |
| `docs/design/screens/index.md` | Screen inventory with states generated |

### Graceful fallback

If the Stitch MCP server is not configured, the Designer agent logs a warning in `screens/index.md` and continues to the spec phase. You can run `/stitch` later once setup is complete.

### Free tier limits

| Plan | Model | Generations/month |
|------|-------|------------------|
| Standard | Gemini 2.5 Flash | 350 |
| Experimental | Gemini 2.5 Pro | 50 (accepts image inputs) |

---

## 11. Extending the Framework

### Add a new bootstrap step

1. Add the step name to `docs/workflow/bootstrap.md` in the correct position
2. Add questions for it to `.github/skills/bootstrap-ask/SKILL.md`
3. Add a row to the routing table in `docs/workflow/agents.md`
4. Add the step's questions to `scripts/ask.sh`
5. Create a generation skill under `.github/skills/` if the step produces a document

### Add a new agent

1. Create `.github/agents/my-agent.agent.md` with the correct frontmatter:
   ```markdown
   ---
   name: My Agent
   description: What it does and when to use it
   tools: ['read', 'edit']
   user-invocable: false
   handoffs:
     - label: "Next Phase"
       agent: next-agent-name
       prompt: "Context for the next agent"
       send: false
   ---
   ```
2. Add it to the `agents:` list of whichever agent will call it as a subagent
3. Add it to the routing table in `docs/workflow/agents.md`
4. Update `copilot-instructions.md`

### Add a new slash command

1. Create `.github/prompts/my-command.prompt.md`:
   ```markdown
   ---
   name: my-command
   description: What this command does
   agent: ask
   ---
   Prompt instructions here.
   ```
2. It will appear in the `/` menu automatically

### Add a new skill

1. Create `.github/skills/my-skill/SKILL.md`:
   ```markdown
   ---
   name: my-skill
   description: What this skill does and when to use it
   argument-hint: "[optional argument hint]"
   ---
   # Skill Instructions
   Instructions here.
   ```
2. The directory name must match the `name` field exactly

### Change the model per agent

Add a `model:` field to any agent's frontmatter:

```yaml
model: 'Claude Opus 4.6'
# or a priority list:
model: ['Claude Opus 4.6', 'GPT-4o']
```

---

## 12. Troubleshooting

### Agent is not visible in the chat selector

- Check that the file has `.agent.md` extension and is in `.github/agents/`
- Check that `user-invocable` is not set to `false` (only the Bootstrap agent should be visible)

### Handoff button is not appearing

- The handoff only appears after the agent finishes its instructions
- Check that the `handoffs:` block is valid YAML in the agent frontmatter

### Hooks are not running

- Enable the setting: `"chat.useCustomAgentHooks": true` in VS Code settings
- Check that `scripts/validate-state.sh` is executable: `chmod +x scripts/validate-state.sh`
- The hook requires `jq` to be installed

### `validate-state.sh` fails with JSON error

The agent edited `workflow.json` or `answers.json` into an invalid state. Run:

```sh
cat .project/state/workflow.json
cat .project/state/answers.json
```

Fix manually or reset to a known-good state:

```sh
./scripts/step.sh prd     # jump back to a working step
```

### An agent cannot find a required input file

The dependency chain was broken — a required previous step did not run. Use `/status` to see which files are missing, then `/reset <step>` to rerun the missing phase.

### `next.sh` or `step.sh` says step not found

The step name in `workflow.json` does not match any step in `docs/workflow/bootstrap.md`. Edit `workflow.json` directly and set `step` to a valid value from `./scripts/step.sh --list`.

---

*End of Manual*

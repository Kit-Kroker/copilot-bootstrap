# copilot-bootstrap

A multi-agent workflow that takes a project idea and produces a full implementation-ready specification — PRD, domain model, RBAC, API spec, design artifacts, and dev scaffolding scripts — all driven by GitHub Copilot agents in VS Code.

Supports two approaches:
- **Greenfield** — build from scratch: the agents collect your idea, features, and tech choices, then generate all specification documents.
- **Brownfield** — modernize existing code: a 7-step capability extraction pipeline analyzes your codebase first, then feeds discovered capabilities into the same generation pipeline.

For **agent** and **ai-system** projects, the workflow extends with the Agentic Development Lifecycle (ADLC): KPIs, human-agent responsibility mapping, agent architecture patterns, cost modelling, evaluation frameworks, Proof of Value plans, monitoring, and governance. ADLC composes with both greenfield and brownfield approaches.

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

## Project Types

| Type | Description |
|------|-------------|
| `web-app` | Traditional UI-driven application |
| `mobile` | Native or hybrid mobile application |
| `api` | Headless API service or backend |
| `cli` | Command-line tool |
| `agent` | Single LLM-driven agent with tool use |
| `ai-system` | Multi-agent or LLM-core product |

When type is `agent` or `ai-system`, the ADLC extended workflow activates automatically after the standard bootstrap.

## Project Approach

| Approach | Description |
|----------|-------------|
| `greenfield` | Building from scratch — user provides idea, features, tech stack |
| `brownfield` | Modernizing existing code — 7-step capability extraction pipeline analyzes the codebase first |

Set during the `project_info` step. Greenfield is the default.

## Workflow Steps

### Standard Bootstrap (Greenfield)

| Step | Description |
|------|-------------|
| `idea` | Capture the project idea and pain points |
| `project_info` | Name, type, domain |
| `users` | User roles and target audience |
| `features` | Core features |
| `tech` | Backend, frontend, infrastructure |
| `complexity` | simple / saas / enterprise (+ autonomy level for agents) |
| `prd` | Generate Product Requirements Document |
| `capabilities` | System capabilities |
| `domain` | Domain model |
| `design_workflow` | Design artifacts |
| `skills` | Copilot skill definitions |
| `scripts` | Dev scaffolding scripts |
| `done` | Standard bootstrap complete |

### ADLC Extended Steps (agent / ai-system only)

| Step | Description |
|------|-------------|
| `constraints` | Regulatory, error tolerance, and autonomy boundaries |
| `kpis` | Business and technical KPIs with measurable thresholds |
| `human_agent_map` | Human vs agent responsibility matrix |
| `agent_pattern` | Agent architecture pattern, tool inventory, memory design |
| `cost_model` | Token economics, monthly cost estimates |
| `eval_framework` | Evaluation framework, golden dataset spec, regression strategy |
| `pov` | Proof of Value plan with go/no-go criteria |
| `monitoring` | Observability dashboards, alert thresholds, rollback criteria |
| `governance` | Model versioning, feedback loops, drift monitoring, audit policy |
| `adlc_done` | Full ADLC lifecycle complete |

### Brownfield Discovery Steps (replaces steps 3-6 of greenfield)

When approach is `brownfield`, these steps replace `users`, `features`, `tech`, `complexity`:

| Step | Description |
|------|-------------|
| `codebase_setup` | Codebase path, language, architecture style, DB access, pre-generated reports |
| `seed_candidates` | A1: Extract capability candidates from package structure, DB schema, entry points |
| `analyze_candidates` | A2: Cohesion/coupling/boundary analysis — confirm, split, merge, de-scope, or flag |
| `verify_coverage` | A3: Map all files to capabilities, target >90% coverage, resolve orphans |
| `lock_l1` | A4: Finalize Level 1 capability list with stable IDs (BC-001, BC-002...) |
| `define_l2` | A5: Define Level 2 sub-capabilities mapped to code locations and entities |
| `discovery_domain` | A6: Generate consolidated domain model with full code traceability |
| `blueprint_comparison` | A7: Compare against industry reference (BIAN, TM Forum, APQC) |

After discovery, the workflow merges back into `prd` → `capabilities` → `domain` → ... using discovery outputs as input.

## Agent Pipeline

```
Greenfield:
  Bootstrap → Analyst → Architect → Designer → Spec → Script

Brownfield:
  Bootstrap → Discovery → Analyst → Architect → Designer → Spec → Script

ADLC extension (appends to either pipeline when type = agent / ai-system):
  ... → Evaluator → Script → Ops
```

| Agent | Responsibility |
|-------|----------------|
| Bootstrap | Collect project answers, route to Discovery (brownfield) or Analyst (greenfield) |
| Discovery | Extract capabilities from existing codebase using 7-step pipeline (brownfield only) |
| Analyst | PRD, capability map, + KPIs and human-agent map (ADLC) |
| Architect | Domain model, RBAC, workflows, + agent pattern and cost model (ADLC) |
| Designer | Design overview, IA, user flows |
| Spec | API, events, permissions, state machines |
| Evaluator | Eval framework and PoV plan (ADLC only) |
| Script | Dev skill stubs and operational scripts |
| Ops | Monitoring spec and governance doc (ADLC only) |

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/bootstrap` | Start or resume the workflow |
| `/status` | Show current step, answers, and generated files |
| `/adlc-status` | Show ADLC-specific output status |
| `/pov` | Print PoV plan and go/no-go thresholds |
| `/review-spec` | Validate consistency across spec files |
| `/review-agent` | Cross-check ADLC document consistency |
| `/discovery-status` | Show brownfield discovery pipeline progress |
| `/reset` | Jump workflow to a specific step |
| `/stitch` | Generate or regenerate UI screens via Google Stitch |

## File Structure

```
.github/
  agents/          # Copilot agent definitions (9 agents)
  prompts/         # Slash command prompts (9 commands)
  skills/          # Copilot skill definitions (32 skills)
  copilot-instructions.md
.project/state/
  workflow.json    # Current step and status
  answers.json     # Collected answers per step
docs/
  workflow/        # Workflow definitions (bootstrap, brownfield, design, adlc, agents)
  discovery/       # Brownfield extraction outputs** (candidates, analysis, coverage, L1, L2, domain model, blueprint)
  analysis/        # PRD, capabilities, kpis*, human-agent-map*
  domain/          # Model, RBAC, workflows, agent-pattern*, cost-model*
  design/          # Overview, IA, flows, screens
  spec/            # API, events, permissions, state-machines, eval*, pov-plan*
  ops/             # monitoring*, governance*
project.json       # Project metadata (includes approach and adlc flag)
scripts/           # Shell scripts for state management
```

*Files marked with `*` are generated only when ADLC is active. Files marked with `**` are generated only when approach is brownfield.*

## VS Code Setup

The `.vscode/` directory includes pre-configured MCP and settings. Open the project folder directly in VS Code — no additional setup required.

## Manual

See [MANUAL.md](MANUAL.md) for full documentation including agents, slash commands, skills, and troubleshooting.

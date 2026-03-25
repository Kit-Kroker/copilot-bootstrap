# Copilot Bootstrap — Manual

A structured workflow that takes a project idea — or an existing codebase — and produces a complete, implementation-ready specification through a chain of GitHub Copilot agents in VS Code.

Supports **greenfield** (build from scratch) and **brownfield** (modernize existing code) approaches. For **agent** and **ai-system** projects, the Agentic Development Lifecycle (ADLC) extends the workflow with KPIs, evaluation frameworks, PoV plans, monitoring, and governance. All three modes compose.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Quick Start](#2-quick-start)
3. [How It Works](#3-how-it-works)
4. [Project Types & Approach](#4-project-types--approach)
5. [Workflow Steps](#5-workflow-steps)
6. [Agents](#6-agents)
7. [Slash Commands](#7-slash-commands)
8. [Skills](#8-skills)
9. [CLI Commands](#9-cli-commands)
10. [File Structure](#10-file-structure)
11. [Greenfield Pipeline](#11-greenfield-pipeline)
13. [Brownfield Discovery Pipeline](#13-brownfield-discovery-pipeline)
14. [Generator Orchestrator](#14-generator-orchestrator)
15. [Google Stitch Integration](#15-google-stitch-integration)
16. [ADLC Extended Workflow](#16-adlc-extended-workflow)
17. [Extending the Framework](#17-extending-the-framework)
18. [Troubleshooting](#18-troubleshooting)

---

## 1. Prerequisites

- **VS Code** with the **GitHub Copilot** extension (signed in)
- **`uv`** — Python package installer: `curl -LsSf https://astral.sh/uv/install.sh | sh`
- **`jq`** — JSON processor: `apt install jq` / `brew install jq`

Optional but recommended:
- VS Code setting for agent hooks: `"chat.useCustomAgentHooks": true`

---

## 2. Quick Start

### Install

```sh
uv tool install copilot-bootstrap --from git+https://github.com/Kit-Kroker/copilot-bootstrap.git
```

### Greenfield — new project from scratch

```sh
mkdir my-project && cd my-project
copilot-bootstrap init
copilot-bootstrap interview         # 6-step interview: idea → project_info → users → features → tech → complexity
copilot-bootstrap build-context     # derive context.json, decisions.json, scope.json from answers
copilot-bootstrap spec              # initialize spec pipeline (creates pipeline.lock.json)
code .
```

In VS Code, use the `#run-spec-pipeline` skill in Copilot Chat. The pipeline runs all spec steps automatically. When complete, `copilot-bootstrap spec` auto-triggers `copilot-bootstrap generate`, which writes project-specific Copilot config to `.github/`.

**Smart defaults**: pick React → Vite + ESLint + Prettier + Vitest are set automatically. Pick Python → Poetry + Ruff + Black + Pytest. Toolchain derivations are tracked in `.greenfield/decisions.json` so generators know why each choice was made.

**Resumable**: both the spec pipeline and generators track progress in lock files. Re-run `copilot-bootstrap spec` or `copilot-bootstrap generate` after an interruption — completed steps are skipped.

#### Legacy greenfield (manual navigation)

```sh
mkdir my-project && cd my-project
copilot-bootstrap init
code .
```

Select the **Bootstrap** agent in Copilot Chat and type your idea. Bootstrap asks one step at a time; click handoff buttons to advance through Analyst → Architect → Designer → Spec → Script.

### Brownfield — existing codebase

```sh
cd /path/to/existing-project
copilot-bootstrap init
copilot-bootstrap scan          # detect stack → .discovery/context.json
copilot-bootstrap discover      # initialise discovery pipeline
code .
```

In VS Code, select **Bootstrap** and say:

```
idea: understand and document this codebase before modernizing it
```

Bootstrap collects `codebase_setup` answers, then routes to the **Discovery** agent, which runs the 7-step capability extraction pipeline. After discovery completes, run:

```sh
copilot-bootstrap generate      # produce project-specific Copilot config
```

---

## 3. How It Works

### Customization layers

This framework uses all VS Code Copilot customization types:

| Layer | Location | Purpose |
|-------|----------|---------|
| Custom Instructions | `.github/copilot-instructions.md` | Always-on project context, loaded in every request |
| File Instructions | `.github/instructions/*.instructions.md` | Language/framework-specific rules with `applyTo` globs |
| Prompt Files | `.github/prompts/*.prompt.md` | User-facing slash commands (`/status`, `/reset`, etc.) |
| Agent Skills | `.github/skills/*/SKILL.md` | Multi-step reusable workflows used by agents |
| Custom Agents | `.github/agents/*.agent.md` | Specialized personas with tools, models, and handoffs |
| Hooks | Defined in agent frontmatter | Auto-validate state files after every agent edit |
| MCP Servers | `.vscode/mcp.json` | External tool integrations (databases, filesystem, Stitch) |

### Agent pipeline

**Greenfield pipeline (single-command)**:

```
copilot-bootstrap interview         → .greenfield/answers.json
copilot-bootstrap build-context     → .greenfield/context.json + decisions.json + scope.json
copilot-bootstrap spec              → initializes pipeline.lock.json
  #run-spec-pipeline skill:
    Analyst  → docs/analysis/prd.md, capabilities.md
    Architect→ docs/domain/model.md, rbac.md, workflows.md
    Designer → docs/design/overview.md, ia.md, flows.md
    Spec     → docs/spec/api.md
    Script   → .github/skills/ (dev skills)
copilot-bootstrap generate          → .github/ (runtime Copilot config) — runs automatically
```

**Greenfield (legacy, manual navigation)**:

```
Bootstrap → Analyst → Architect → Designer → Spec → Script
```

**Brownfield**:

```
Bootstrap → Discovery → Analyst → Architect → Designer → Spec → Script
```

**ADLC extension** (appends when type = `agent` or `ai-system`):

```
... → Evaluator → Script → Ops
```

For manual navigation, agents are chained via **handoff buttons**. Each agent completes its phase and presents a button that passes context to the next.

### State machine

Workflow progress is tracked in two files:

- `.project/state/workflow.json` — current step and status
- `.project/state/answers.json` — all collected answers

Both are updated by agents after each step. `project.json` at the root mirrors the current step and includes `approach` and `adlc` flags.

### Dependency chain

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

Brownfield adds a discovery chain before generation:

```
answers.json (codebase_setup)
  └─► docs/discovery/candidates.md
        └─► docs/discovery/analysis.md
              └─► docs/discovery/coverage.md
                    └─► docs/discovery/l1-capabilities.md
                          └─► docs/discovery/l2-capabilities.md
                                └─► docs/discovery/domain-model.md
                                      └─► docs/discovery/blueprint-comparison.md
                                            └─► docs/analysis/prd.md (brownfield mode)
```

ADLC extends with:

```
answers.json (constraints, kpis)
  └─► docs/analysis/kpis.md
        └─► docs/analysis/human-agent-map.md
              └─► docs/domain/agent-pattern.md
                    └─► docs/domain/cost-model.md
                          └─► docs/spec/eval.md
                                └─► docs/spec/pov-plan.md
                                      └─► docs/ops/monitoring.md
                                            └─► docs/ops/governance.md
```

If a required input is missing, the agent reports what needs to run first.

---

## 4. Project Types & Approach

### Project types

| Type | Description | ADLC |
|------|-------------|------|
| `web-app` | Traditional UI-driven application | No |
| `mobile` | Native or hybrid mobile application | No |
| `api` | Headless API service or backend | No |
| `cli` | Command-line tool | No |
| `agent` | Single LLM-driven agent with tool use | Yes |
| `ai-system` | Multi-agent or LLM-core product | Yes |

When type is `agent` or `ai-system`: `project.json → adlc` is set to `true`, an additional `constraints` + `kpis` step is added, and the ADLC pipeline activates after the standard bootstrap completes.

### Approach

| Approach | Description |
|----------|-------------|
| `greenfield` | Building from scratch — user provides idea, features, tech stack |
| `brownfield` | Modernizing existing code — 7-step pipeline analyzes the codebase first |

When `brownfield`: the `users`, `features`, `tech`, `complexity` steps are replaced by `codebase_setup` + 7 discovery steps. ADLC still applies if type is `agent` or `ai-system`.

---

## 5. Workflow Steps

### Greenfield pipeline (single-command)

The pipeline approach replaces manual step navigation with CLI commands and a single skill invocation.

| Phase | Command / Skill | Output |
|-------|----------------|--------|
| Interview | `copilot-bootstrap interview` + `#bootstrap-ask` | `.greenfield/answers.json` |
| Context build | `copilot-bootstrap build-context` | `.greenfield/context.json`, `decisions.json`, `scope.json` |
| Spec pipeline | `copilot-bootstrap spec` + `#run-spec-pipeline` | `docs/analysis/`, `docs/domain/`, `docs/design/`, `docs/spec/`, `.github/skills/` |
| Generators | auto-runs when spec completes (or `copilot-bootstrap generate`) | `.github/instructions/`, `agents/`, `skills/`, `prompts/`, hooks, MCP, docs |

#### Interview steps (6 steps)

| # | Step | Collected |
|---|------|-----------|
| 1 | `idea` | description, pain_points |
| 2 | `project_info` | name, type, domain |
| 3 | `users` | user roles and descriptions |
| 4 | `features` | feature list with priority (must-have / should-have / nice-to-have) |
| 5 | `tech` | language, frontend, backend, db, container |
| 6 | `complexity` | level (mvp / startup / saas / enterprise), autonomy, adlc |

#### Spec pipeline steps (11 steps)

| Step | Output |
|------|--------|
| `generate_prd` | `docs/analysis/prd.md` |
| `generate_capabilities` | `docs/analysis/capabilities.md` |
| `generate_domain` | `docs/domain/model.md` |
| `generate_rbac` | `docs/domain/rbac.md` |
| `generate_workflows` | `docs/domain/workflows.md` |
| `generate_design_workflow` | `docs/design/overview.md` |
| `generate_ia` | `docs/design/ia.md` |
| `generate_flows` | `docs/design/flows.md` |
| `generate_spec` | `docs/spec/api.md` |
| `generate_skills` | `.github/skills/` (dev skills) |
| `generate_scripts` | `scripts/` |

Steps that already have output files are automatically skipped (resumable from any point).

#### Generator steps (8 generators — run after spec pipeline)

| Generator | Output |
|-----------|--------|
| `instructions` | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` |
| `agents` | `.github/agents/*.agent.md` (includes scaffold agent — greenfield only) |
| `skills` | `.github/skills/*/SKILL.md` (runtime skills: build, test, lint, format, deploy) |
| `prompts` | `.github/prompts/*.prompt.md` (includes implement-feature, scaffold-project — greenfield only) |
| `mcp` | `.vscode/mcp.json` |
| `hooks` | `.github/hooks/*.json` |
| `plugins` | `.github/plugins/project.plugin.json` |
| `docs` | `.github/docs/` (includes getting-started.md — greenfield only) |

### Standard bootstrap — greenfield (legacy, 13 steps)

| # | Step | Agent | Output |
|---|------|-------|--------|
| 1 | `idea` | Bootstrap | answers: idea, pain_points |
| 2 | `project_info` | Bootstrap | answers: project_info; project.json updated |
| 3 | `users` | Bootstrap | answers: users |
| 4 | `features` | Bootstrap | answers: features |
| 5 | `tech` | Bootstrap | answers: tech |
| 6 | `complexity` | Bootstrap | answers: complexity (+ autonomy_level for agents) |
| 7 | `prd` | Analyst | docs/analysis/prd.md |
| 8 | `capabilities` | Analyst | docs/analysis/capabilities.md |
| 9 | `domain` | Architect | docs/domain/model.md, rbac.md, workflows.md |
| 10 | `design_workflow` | Designer | docs/design/overview.md, ia.md, flows.md |
| 11 | `skills` | Script | .github/skills/ (dev stubs) |
| 12 | `scripts` | Script | scripts/*.sh |
| 13 | `done` | — | Standard bootstrap complete |

### ADLC extended steps (10 steps, agent/ai-system only)

| # | Step | Agent | Output |
|---|------|-------|--------|
| 14 | `constraints` | Bootstrap | answers: constraints |
| 15 | `kpis` | Bootstrap | answers: kpis |
| 16 | `human_agent_map` | Analyst | docs/analysis/human-agent-map.md |
| 17 | `agent_pattern` | Architect | docs/domain/agent-pattern.md |
| 18 | `cost_model` | Architect | docs/domain/cost-model.md |
| 19 | `eval_framework` | Evaluator | docs/spec/eval.md |
| 20 | `pov` | Evaluator | docs/spec/pov-plan.md |
| 21 | `monitoring` | Ops | docs/ops/monitoring.md |
| 22 | `governance` | Ops | docs/ops/governance.md |
| 23 | `adlc_done` | — | Full ADLC lifecycle complete |

### Brownfield discovery steps (replaces greenfield steps 3-6)

| # | Step | Agent | Output |
|---|------|-------|--------|
| 3 | `codebase_setup` | Bootstrap | answers: codebase_setup |
| 4 | `seed_candidates` | Discovery | docs/discovery/candidates.md |
| 5 | `analyze_candidates` | Discovery | docs/discovery/analysis.md |
| 6 | `verify_coverage` | Discovery | docs/discovery/coverage.md |
| 7 | `lock_l1` | Discovery | docs/discovery/l1-capabilities.md |
| 8 | `define_l2` | Discovery | docs/discovery/l2-capabilities.md |
| 9 | `discovery_domain` | Discovery | docs/discovery/domain-model.md |
| 10 | `blueprint_comparison` | Discovery | docs/discovery/blueprint-comparison.md |

After discovery, the workflow continues from `prd` (step 11) onward, using discovery outputs as primary inputs.

### Questions asked per step

| Step | Questions |
|------|-----------|
| `idea` | Describe your project; what is currently manual or slow; why is a human doing it today |
| `project_info` | Name; type; domain; approach |
| `codebase_setup` | Codebase path; primary language; architecture style; DB access; pre-generated reports; has frontend |
| `users` | Who are the users; what roles do they have |
| `features` | List 3-10 core features |
| `tech` | Backend, frontend, database preferences |
| `complexity` | `simple` / `saas` / `enterprise`; autonomy level (agent/ai-system only) |
| `constraints` | Regulatory requirements; max error rate; forbidden actions; latency tolerance *(ADLC only)* |
| `kpis` | Primary business metric; 30-day success criteria; minimum accuracy; kill-switch criteria *(ADLC only)* |

---

## 6. Agents

Agents live in `.github/agents/`. Select an agent in the Copilot Chat panel.

### Bootstrap
**File:** `.github/agents/bootstrap.agent.md` | **Visible in chat:** Yes

Collects all project answers step by step. Asks only missing questions. Saves to `answers.json` after each step. Routes to Discovery (brownfield) or Analyst (greenfield) when collection is complete. Validates state after every file edit via a `PostToolUse` hook.

---

### Discovery *(brownfield only)*
**File:** `.github/agents/discovery.agent.md` | **Visible in chat:** No

Analyzes an existing codebase using the 7-step capability extraction pipeline. Each step reads one input, produces one output, and feeds the next. Adaptive: skips unavailable signal sources (no DB, no frontend). Accepts pre-generated inputs — if an output file already exists in `docs/discovery/`, uses it as-is.

| Step | Skill | Output |
|------|-------|--------|
| `seed_candidates` | `discover-candidates` | docs/discovery/candidates.md |
| `analyze_candidates` | `analyze-candidates` | docs/discovery/analysis.md |
| `verify_coverage` | `verify-coverage` | docs/discovery/coverage.md |
| `lock_l1` | `lock-l1` | docs/discovery/l1-capabilities.md |
| `define_l2` | `define-l2` | docs/discovery/l2-capabilities.md |
| `discovery_domain` | `generate-discovery-domain` | docs/discovery/domain-model.md |
| `blueprint_comparison` | `compare-blueprint` | docs/discovery/blueprint-comparison.md |

---

### Analyst
**File:** `.github/agents/analyst.agent.md` | **Visible in chat:** No

Generates: `docs/analysis/prd.md`, `docs/analysis/capabilities.md`. In brownfield mode, reads from `docs/discovery/` instead of user-supplied answers. For ADLC: also generates `docs/analysis/kpis.md` and `docs/analysis/human-agent-map.md`.

---

### Architect
**File:** `.github/agents/architect.agent.md` | **Visible in chat:** No

Generates: `docs/domain/model.md`, `docs/domain/rbac.md`, `docs/domain/workflows.md`. For ADLC: also generates `docs/domain/agent-pattern.md` and `docs/domain/cost-model.md`.

---

### Designer
**File:** `.github/agents/designer.agent.md` | **Visible in chat:** No

Generates: `docs/design/overview.md`, `docs/design/ia.md`, `docs/design/flows.md`. Optionally generates UI screens via Google Stitch MCP.

---

### Spec
**File:** `.github/agents/spec.agent.md` | **Visible in chat:** No

Generates in a single pass: `docs/spec/api.md`, `docs/spec/events.md`, `docs/spec/permissions.md`, `docs/spec/state-machines.md`. Uses consistent naming across all four. Routes to Evaluator (ADLC) or Script (standard).

---

### Evaluator *(ADLC only)*
**File:** `.github/agents/evaluator.agent.md` | **Visible in chat:** No

Generates: `docs/spec/eval.md` (evaluation framework, golden dataset spec, regression strategy) and `docs/spec/pov-plan.md` (highest-risk assumption, PoV scope, go/no-go gate criteria).

---

### Script
**File:** `.github/agents/script.agent.md` | **Visible in chat:** No

Generates dev skill stubs under `.github/skills/` tailored to the project's stack:
- Always: `scaffold-project`, `generate-models`, `generate-api`, `generate-tests`
- If frontend: `generate-components`, `generate-pages`
- If complexity is `saas`: `generate-auth`, `generate-tenant`
- If complexity is `enterprise`: `generate-rbac-impl`, `generate-audit-log`

Also verifies `scripts/*.sh` are executable. Routes to Ops (ADLC) or sets workflow to `done`.

---

### Ops *(ADLC only)*
**File:** `.github/agents/ops.agent.md` | **Visible in chat:** No

Generates: `docs/ops/monitoring.md` (dashboards, alert thresholds tied to KPIs, rollback criteria) and `docs/ops/governance.md` (model versioning, feedback loops, drift monitoring, audit log policy). Sets workflow to `adlc_done`.

---

## 7. Slash Commands

Type `/` in Copilot Chat to access these commands.

### `/bootstrap`
Start or resume the workflow. Routes to Bootstrap from the current step.

```
/bootstrap
/bootstrap idea: inventory management system
```

---

### `/status`
Show current step, collected answers, and which output files exist.

```
/status
```

---

### `/discovery-status`
Show brownfield discovery pipeline progress: which of the 7 steps are complete, counts, and coverage stats.

```
/discovery-status
```

---

### `/adlc-status`
Extended status view for ADLC projects. Shows all ADLC documents grouped by phase.

---

### `/pov`
Print the Proof of Value plan and go/no-go thresholds from `docs/spec/pov-plan.md`. Use during PoV execution to stay aligned on the experiment scope and pass/fail criteria.

---

### `/reset`
Jump the workflow to a specific step without deleting output files. Use when re-running a phase after editing answers.

```
/reset prd
/reset domain
/reset constraints
```

---

### `/review-spec`
Cross-check all four spec files for consistency: resource naming, permission coverage for every API endpoint, event coverage for every state transition, role name consistency with `rbac.md`.

---

### `/review-agent`
Cross-check all ADLC documents: KPI thresholds match eval thresholds, human-agent map tasks map to capabilities, PoV criteria match KPIs, monitoring alerts reference the correct thresholds.

---

### `/stitch`
Generate or regenerate UI screens via Google Stitch MCP.

```
/stitch
/stitch dashboard screen
```

---

## 8. Skills

Skills live in `.github/skills/`. Agents call them directly; some can also be invoked by name in chat.

### Workflow skills (internal)

| Skill | Purpose |
|-------|---------|
| `workflow-read` | Read current step and status from `workflow.json` |
| `workflow-update` | Update `workflow.json` and `project.json` after a step |
| `bootstrap-ask` | Ask only missing questions for the current step |
| `bootstrap-next` | Advance to the next step |

### Standard generation skills

| Skill | Step | Output |
|-------|------|--------|
| `generate-prd` | `prd` | `docs/analysis/prd.md` |
| `generate-capabilities` | `capabilities` | `docs/analysis/capabilities.md` |
| `generate-domain` | `domain` | `docs/domain/model.md` |
| `generate-rbac` | `rbac` | `docs/domain/rbac.md` |
| `generate-workflows` | `workflow` | `docs/domain/workflows.md` |
| `generate-design-workflow` | `design_workflow` | `docs/design/overview.md` |
| `generate-ia` | `ia` | `docs/design/ia.md` |
| `generate-flows` | `flows` | `docs/design/flows.md` |
| `generate-spec` | `spec` | `docs/spec/*.md` |
| `generate-skills` | `skills` | `.github/skills/` (dev stubs) |
| `generate-scripts` | `scripts` | `scripts/*.sh` |

### Brownfield discovery skills

Used by the Discovery agent when `approach = brownfield`.

| Skill | Step | Output |
|-------|------|--------|
| `discover-candidates` | `seed_candidates` | `docs/discovery/candidates.md` |
| `analyze-candidates` | `analyze_candidates` | `docs/discovery/analysis.md` |
| `verify-coverage` | `verify_coverage` | `docs/discovery/coverage.md` |
| `lock-l1` | `lock_l1` | `docs/discovery/l1-capabilities.md` |
| `define-l2` | `define_l2` | `docs/discovery/l2-capabilities.md` |
| `generate-discovery-domain` | `discovery_domain` | `docs/discovery/domain-model.md` |
| `compare-blueprint` | `blueprint_comparison` | `docs/discovery/blueprint-comparison.md` |

### ADLC generation skills

Used when `adlc = true`.

| Skill | Step | Output |
|-------|------|--------|
| `generate-kpis` | `kpis` | `docs/analysis/kpis.md` |
| `generate-human-agent-map` | `human_agent_map` | `docs/analysis/human-agent-map.md` |
| `generate-agent-pattern` | `agent_pattern` | `docs/domain/agent-pattern.md` |
| `generate-cost-model` | `cost_model` | `docs/domain/cost-model.md` |
| `generate-eval-framework` | `eval_framework` | `docs/spec/eval.md` |
| `generate-pov-plan` | `pov` | `docs/spec/pov-plan.md` |
| `generate-monitoring-spec` | `monitoring` | `docs/ops/monitoring.md` |
| `generate-governance` | `governance` | `docs/ops/governance.md` |

---

## 9. CLI Commands

All commands require `jq`. Run `copilot-bootstrap <command> --help` for full options.

### `init`

Initialise a fresh project. Safe — exits if state already exists.

```sh
copilot-bootstrap init
```

Creates `.project/state/workflow.json`, `.project/state/answers.json`, `project.json`, and all output folders.

---

### `interview`

Start or resume the greenfield interview. Initialises `.greenfield/answers.json`, shows progress, and guides you to use the `#bootstrap-ask` skill in Copilot Chat.

```sh
copilot-bootstrap interview
```

Tracks 6 steps: `idea`, `project_info`, `users`, `features`, `tech`, `complexity`. Shows which steps are complete and which remain. Re-running is safe — completed steps are not overwritten.

---

### `build-context`

Build structured context files from `.greenfield/answers.json`. Applies derivation rules and smart defaults.

```sh
copilot-bootstrap build-context
```

**Outputs:**

| File | Purpose |
|------|---------|
| `.greenfield/context.json` | Unified stack, tools, architecture, paths, project metadata |
| `.greenfield/decisions.json` | Why each choice was made: user / default / derived |
| `.greenfield/scope.json` | Features, users, complexity, autonomy level |

**Derivation rules** (automatic, no user input):
- Runtime from language: `typescript` → `node`, `python` → `python`, `go` → `go`
- Architecture from project type: `web` → `layered`, `cli` → `monolith`
- Monorepo: always `false` for greenfield

**Smart defaults** (applied when not provided by user):

| Language | Defaults |
|----------|---------|
| TypeScript / JavaScript | npm, eslint, prettier, vitest (React+Vite) or jest (Next.js) |
| Python | poetry, ruff, black, pytest |
| Go | go mod, golangci-lint, gofmt, go test |
| Java | maven, checkstyle, spotless, junit |

All defaults are recorded in `decisions.json` with `source: "default"` so generators know what was chosen automatically vs explicitly.

---

### `spec`

Initialise or resume the greenfield spec pipeline. Validates prerequisites, creates `.greenfield/pipeline.lock.json`, and reports step status.

```sh
copilot-bootstrap spec
```

When all spec steps are complete (all 11 show `completed` or `skipped`), `spec` automatically runs `copilot-bootstrap generate`.

Use the `#run-spec-pipeline` skill in Copilot Chat to execute the pipeline steps. Re-run `copilot-bootstrap spec` after the skill completes to update the lock and trigger generators.

---

### `spec-status`

Print current spec pipeline progress.

```sh
copilot-bootstrap spec-status
```

---

### `scan`

Scan the codebase and write `.discovery/context.json`. Run this before `discover` or `generate` on a brownfield project.

```sh
copilot-bootstrap scan
```

Detects: languages, frontend framework, backend framework, database, package manager, linter, test runner, bundler, container tool, architecture style, monorepo flag, entry points. Writes detection confidence scores to `.discovery/confidence.json`. Produces a unified context at `.discovery/context.json`.

Output example:
```json
{
  "stack": { "languages": ["typescript"], "backend": "express", "frontend": "react", "db": "postgres" },
  "tools": { "package_manager": "npm", "test_runner": "jest", "linter": "eslint", "bundler": "vite", "container": "docker" },
  "arch": { "style": "layered", "monorepo": false, "services": 1 },
  "paths": { "src": "src/", "tests": "tests/" }
}
```

---

### `discover`

Initialise or resume the brownfield discovery pipeline. Validates prerequisites, creates `.discovery/pipeline.lock.json`, and reports step status.

```sh
copilot-bootstrap discover
```

The pipeline itself runs via the Discovery agent in Copilot Chat. Re-run `discover` after the agent completes steps to see updated status and auto-trigger `generate` when all 7 steps are done.

---

### `discovery-status`

Print current discovery pipeline progress.

```sh
copilot-bootstrap discovery-status
```

---

### `generate`

Produce project-specific Copilot configuration from context outputs. **Automatically detects** whether to use `.greenfield/context.json` (greenfield) or `.discovery/context.json` (brownfield). Runs all 8 generators in order and writes to `.github/` and `.vscode/`.

```sh
copilot-bootstrap generate              # run all generators
copilot-bootstrap generate instructions # run one generator
copilot-bootstrap generate status       # show progress
copilot-bootstrap generate --force      # re-run completed generators
```

Generators and their output:

| Generator | Output | Greenfield extras |
|-----------|--------|-------------------|
| `instructions` | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md` | `decisions.instructions.md` — stack rationale from `decisions.json` |
| `agents` | `.github/agents/*.agent.md` (backend, frontend, test, refactor, devops) | `scaffold.agent.md` — guides initial project setup from specs |
| `skills` | `.github/skills/*/SKILL.md` (build, test, lint, format, deploy) | — |
| `prompts` | `.github/prompts/*.prompt.md` (/new-feature, /fix-bug, /write-tests, /review-pr) | `implement-feature`, `scaffold-project` |
| `mcp` | `.vscode/mcp.json` (DB server, filesystem server) | — |
| `hooks` | `.github/hooks/*.json` (session-start, pre-tool-use, post-tool-use) | — |
| `plugins` | `.github/plugins/project.plugin.json` | — |
| `docs` | `.github/docs/` (stack, architecture, agents, skills, prompts) | `getting-started.md` — onboarding guide for this project |

**Generator inputs:**

| File | Required | Used by |
|------|----------|---------|
| `.greenfield/context.json` or `.discovery/context.json` | Yes | All generators |
| `.greenfield/decisions.json` | No (greenfield) | instructions, docs |
| `.greenfield/scope.json` | No (greenfield) | agents, docs |
| `docs/analysis/prd.md`, `capabilities.md` | No | agents, prompts |
| `docs/domain/model.md` | No | agents |
| `docs/spec/api.md` | No | prompts |

Generators work with `context.json` alone (minimal mode). Spec pipeline outputs enhance them when present.

Generator progress is tracked in `{context-dir}/generators.lock.json` for resumability. If a generator fails, fix the issue and re-run `generate` — completed generators are skipped.

---

### `generate-status`

Print current generator progress.

```sh
copilot-bootstrap generate-status
```

Equivalent to `copilot-bootstrap generate status`.

---

### `sync`

Overwrite `.github/` and `docs/workflow/` with the latest package version. Never touches `.project/state/`, `project.json`, or generated documents.

```sh
copilot-bootstrap sync
```

---

### `step`

Read or set the current workflow step.

```sh
copilot-bootstrap step              # print current step
copilot-bootstrap step --list       # list all valid steps
copilot-bootstrap step prd          # jump to step "prd"
```

---

### `next`

Advance to the next step in the active workflow.

```sh
copilot-bootstrap next
```

---

### `ask`

Print the questions for the current or a specific step.

```sh
copilot-bootstrap ask               # questions for the current step
copilot-bootstrap ask features      # questions for a specific step
```

---

### `validate`

Validate `workflow.json` and `answers.json` integrity. Called automatically by agent hooks; also useful to run manually after editing state files.

```sh
copilot-bootstrap validate
```

Checks: valid JSON, required fields present, `status` is a valid value, `project.json` step matches `workflow.json`.

---

## 10. File Structure

```
.github/
  copilot-instructions.md         Always-on project context (generated by `generate`)

  agents/
    bootstrap.agent.md            Collects answers, routes to Discovery or Analyst
    discovery.agent.md            Brownfield codebase analysis (7-step pipeline)**
    analyst.agent.md              Generates PRD, capabilities, kpis*, human-agent-map*
    architect.agent.md            Generates domain model, RBAC, workflows, agent-pattern*, cost-model*
    designer.agent.md             Generates design overview, IA, flows
    spec.agent.md                 Generates API, events, permissions, state machines
    evaluator.agent.md            Generates eval framework, PoV plan*
    script.agent.md               Generates dev skills and operational scripts
    ops.agent.md                  Generates monitoring spec, governance doc*

  instructions/                   File-scoped instructions (generated by `generate`)
    {language}.instructions.md    Language coding standards with applyTo glob
    {framework}.instructions.md   Framework-specific conventions
    architecture.instructions.md  Architectural layer rules
    decisions.instructions.md     Stack rationale and smart defaults summary (greenfield only)†

  prompts/
    bootstrap.prompt.md           /bootstrap
    status.prompt.md              /status
    discovery-status.prompt.md    /discovery-status**
    adlc-status.prompt.md         /adlc-status*
    pov.prompt.md                 /pov*
    reset.prompt.md               /reset
    review-spec.prompt.md         /review-spec
    review-agent.prompt.md        /review-agent*
    stitch.prompt.md              /stitch
    scaffold-project.prompt.md    /scaffold-project (greenfield only)†
    implement-feature.prompt.md   /implement-feature (greenfield only)†

  skills/
    workflow-read/SKILL.md
    workflow-update/SKILL.md
    bootstrap-ask/SKILL.md
    bootstrap-next/SKILL.md
    generate-prd/SKILL.md
    generate-capabilities/SKILL.md
    generate-kpis/SKILL.md*
    generate-human-agent-map/SKILL.md*
    generate-domain/SKILL.md
    generate-rbac/SKILL.md
    generate-workflows/SKILL.md
    generate-agent-pattern/SKILL.md*
    generate-cost-model/SKILL.md*
    generate-design-workflow/SKILL.md
    generate-ia/SKILL.md
    generate-flows/SKILL.md
    generate-spec/SKILL.md
    generate-eval-framework/SKILL.md*
    generate-pov-plan/SKILL.md*
    generate-skills/SKILL.md
    generate-scripts/SKILL.md
    generate-monitoring-spec/SKILL.md*
    generate-governance/SKILL.md*
    discover-candidates/SKILL.md**
    analyze-candidates/SKILL.md**
    verify-coverage/SKILL.md**
    lock-l1/SKILL.md**
    define-l2/SKILL.md**
    generate-discovery-domain/SKILL.md**
    compare-blueprint/SKILL.md**

  hooks/                          Generated lifecycle hooks**
    session-start.json
    pre-tool-use.json
    post-tool-use.json

  plugins/                        Generated plugin bundle**
    project.plugin.json

  agents/
    ...                           (workflow agents — bootstrap, analyst, etc.)
    scaffold.agent.md             Guides initial project setup from specs (greenfield only)†

  docs/                           Generated docs summaries
    stack.md
    architecture.md
    agents.md
    skills.md
    prompts.md
    getting-started.md            Onboarding guide for building this project (greenfield only)†

.greenfield/                      Greenfield pipeline context and state†
  answers.json                    Interview answers (written by Bootstrap agent)
  answers.schema.json             Schema for answers.json
  context.json                    Unified stack, tools, architecture, paths (written by build-context)
  context.schema.json             Schema for context.json
  decisions.json                  Why each stack/tool choice was made (user/default/derived)
  decisions.schema.json           Schema for decisions.json
  scope.json                      Features, users, complexity, autonomy level
  scope.schema.json               Schema for scope.json
  pipeline.lock.json              Spec pipeline step progress (written by spec command)
  pipeline.lock.schema.json       Schema for pipeline.lock.json
  generators.lock.json            Generator orchestrator progress (written by generate command)
  generators.lock.schema.json     Schema for generators.lock.json

.project/
  state/
    workflow.json                 { workflow, approach, step, status }
    answers.json                  { idea, project_info, codebase_setup**, users, features, tech, complexity, constraints*, kpis* }

.discovery/                       Machine-readable detection and generation state**
  context.json                    Unified detected stack (written by `scan`)
  confidence.json                 Detection confidence scores per field
  fs.json                         Raw filesystem scan
  stack.json                      Raw stack detection
  tools.json                      Raw tools detection
  arch.json                       Raw architecture detection
  pipeline.lock.json              Discovery pipeline step progress
  generators.lock.json            Generator orchestrator progress
  context.schema.json             Schema for context.json
  pipeline.lock.schema.json       Schema for pipeline.lock.json
  generators.lock.schema.json     Schema for generators.lock.json

docs/
  workflow/
    bootstrap.md                  Greenfield workflow definition
    brownfield.md                 Brownfield workflow definition**
    design.md                     Design sub-workflow
    adlc.md                       ADLC extended workflow definition*
    agents.md                     Step → agent → skill routing table
  discovery/
    candidates.md**               Raw capability candidates
    analysis.md**                 Candidate analysis
    coverage.md**                 Code coverage verification
    l1-capabilities.md**          Locked L1 capability list
    l2-capabilities.md**          L2 sub-capabilities
    domain-model.md**             Code-derived domain model
    blueprint-comparison.md**     Industry reference comparison
  analysis/
    prd.md                        Product Requirements Document
    capabilities.md               Capability map
    kpis.md*                      KPIs and thresholds
    human-agent-map.md*           Human-agent responsibility matrix
  domain/
    model.md                      Entities, aggregates, domain events
    rbac.md                       Roles, permission matrix
    workflows.md                  Business workflows
    agent-pattern.md*             Agent architecture, tools, memory design
    cost-model.md*                Token economics, cost estimates
  design/
    overview.md                   Design phases and deliverables
    ia.md                         Sitemap, navigation, screen inventory
    flows.md                      User flows
    screens/                      Stitch-generated HTML screens
  spec/
    api.md                        REST API endpoints
    events.md                     Domain event catalogue
    permissions.md                Permission list and role assignments
    state-machines.md             State machines for stateful entities
    eval.md*                      Evaluation framework and golden dataset
    pov-plan.md*                  Proof of Value plan and go/no-go criteria
  ops/
    monitoring.md*                Observability, alerts, rollback criteria
    governance.md*                Model versioning, feedback loops, audit

templates/                        Source templates for `generate` command
  instructions/                   Language, framework, architecture templates
  agents/                         Agent persona templates
  skills/                         Skill definition templates
  prompts/                        Prompt file templates
  hooks/                          Hook configuration templates

project.json                      Project metadata (name, type, domain, approach, step, adlc)
```

`*` = ADLC only (type is `agent` or `ai-system`)
`**` = brownfield only (approach is `brownfield`) or generated by `generate` command
`†` = greenfield pipeline only (generated by `generate` when `.greenfield/context.json` is present)

---

## 11. Greenfield Pipeline

The greenfield pipeline transforms a project idea into a complete, implementation-ready Copilot configuration in four phases. The pipeline is resumable at any point via lock files.

### Full flow

```
copilot-bootstrap init
copilot-bootstrap interview         → .greenfield/answers.json
copilot-bootstrap build-context     → .greenfield/context.json + decisions.json + scope.json
copilot-bootstrap spec              → .greenfield/pipeline.lock.json
  [run #run-spec-pipeline in Copilot Chat]
    → docs/analysis/prd.md, capabilities.md
    → docs/domain/model.md, rbac.md, workflows.md
    → docs/design/overview.md, ia.md, flows.md
    → docs/spec/api.md
    → .github/skills/ (dev skills)
copilot-bootstrap spec              → detects all steps complete → runs generate automatically
  → .github/copilot-instructions.md + instructions/
  → .github/agents/ (backend, frontend, test, refactor, devops, scaffold)
  → .github/skills/ (build, test, lint, format, deploy)
  → .github/prompts/ (new-feature, fix-bug, write-tests, review-pr, scaffold-project, implement-feature)
  → .vscode/mcp.json
  → .github/docs/getting-started.md
```

### Smart defaults

When `build-context` runs, it applies smart defaults for any toolchain tools not explicitly chosen. Defaults are selected based on the chosen language and frontend framework:

| Language + Framework | Test runner | Bundler | Linter | Formatter |
|---------------------|-------------|---------|--------|-----------|
| TypeScript + React | vitest | vite | eslint | prettier |
| TypeScript + Next.js | jest | — | eslint | prettier |
| TypeScript + Express | jest | — | eslint | prettier |
| Python + FastAPI | pytest | — | ruff | black |
| Python + Django | pytest | — | ruff | black |
| Go | go test | — | golangci-lint | gofmt |

All defaults are recorded in `.greenfield/decisions.json` with `source: "default"` and a `reason` field. The instructions generator reads this file and emits `decisions.instructions.md` so Copilot understands why the toolchain was chosen.

### Spec pipeline lock

`.greenfield/pipeline.lock.json` tracks each step's status. Steps whose output files already exist are automatically marked `skipped` when `copilot-bootstrap spec` runs — so you can pre-populate `docs/` with existing content and the pipeline will not overwrite it.

```json
{
  "version": "1",
  "started_at": "2026-03-26T10:00:00Z",
  "steps": {
    "generate_prd":          { "status": "completed", "output": "docs/analysis/prd.md" },
    "generate_capabilities": { "status": "completed", "output": "docs/analysis/capabilities.md" },
    "generate_domain":       { "status": "pending",   "output": "docs/domain/model.md" },
    ...
  }
}
```

### Difference: dev skills vs runtime generators

The spec pipeline produces **dev skills** (`.github/skills/scaffold-project`, `generate-models`, etc.) — these tell Copilot *how to build* the project.

`copilot-bootstrap generate` produces **runtime config** (instructions, agents, prompts, hooks) — this tells Copilot *how to behave* while working in the project.

Both are distinct outputs that complement each other. Dev skills are created once during setup; runtime config is regenerated whenever the stack changes.

---

## 13. Brownfield Discovery Pipeline

The brownfield discovery pipeline extracts a complete business capability map from an existing codebase in 7 steps. Each step reads one input, produces one output, and feeds the next.

### When it activates

Set `approach = brownfield` during the `project_info` step (or answer "existing" when Bootstrap asks). This switches the workflow to `docs/workflow/brownfield.md`.

### Before running the pipeline

```sh
copilot-bootstrap scan
```

`scan` reads the codebase at the current directory and writes:
- `.discovery/context.json` — unified stack/tools/architecture context
- `.discovery/confidence.json` — detection confidence per field
- `.discovery/fs.json`, `stack.json`, `tools.json`, `arch.json` — raw detection outputs

Review `.discovery/context.json` before proceeding. Correct any misdetections manually.

### Running the pipeline

```sh
copilot-bootstrap discover
```

This validates prerequisites, initialises `.discovery/pipeline.lock.json`, and reports step status. The actual pipeline runs via the **Discovery agent** in Copilot Chat. Use the `run-discovery-pipeline` skill for a fully automatic run, or execute steps individually.

### Pipeline steps

| Step | What the agent does | Output |
|------|---------------------|--------|
| A1: Seed candidates | Extract signals from package structure, DB schema, backend entry points, frontend routes | `docs/discovery/candidates.md` — 15-25 raw candidates with HIGH/MEDIUM/LOW confidence |
| A2: Analyze candidates | Per candidate: assess cohesion, coupling, boundary clarity; decide confirm/split/merge/de-scope/flag | `docs/discovery/analysis.md` |
| A3: Verify coverage | Map all source files to capabilities; target >90% coverage; resolve orphan code | `docs/discovery/coverage.md` |
| A4: Lock L1 | Finalize L1 list with stable IDs (BC-001, BC-002...) | `docs/discovery/l1-capabilities.md` |
| A5: Define L2 | Per L1: define executable sub-capabilities mapped to code locations and entities | `docs/discovery/l2-capabilities.md` |
| A6: Domain model | Consolidated model with capability hierarchy, entity ownership, cross-capability dependencies, code traceability | `docs/discovery/domain-model.md` |
| A7: Blueprint comparison | Compare against industry reference (BIAN, TM Forum, APQC): aligned / org-specific / missing-from-code | `docs/discovery/blueprint-comparison.md` |

### Design principles

- **Adaptive** — Skips unavailable signal sources. No DB access → skip schema. API-only → skip frontend routes. Extraction continues with fewer signals.
- **Pre-generated inputs accepted** — Each step checks if its output file already exists. Feed it nDepend exports, SonarQube analysis, or DBA reports to anchor the AI analysis in higher-quality signals.
- **Confidence-driven** — Every candidate carries HIGH/MEDIUM/LOW confidence. Ambiguous candidates are flagged for human review, not silently resolved. HIGH = appears in 3+ signal sources; LOW = 1 source, weak evidence.
- **Code is truth** — Industry blueprint comparison adds context but does not override code-derived capabilities. Missing capabilities prompt questions, not assumptions.
- **Traceable** — Every capability, entity, and operation is mapped to specific files and code locations.

### Key concepts

**Capability vs Feature** — A capability is what the business does (e.g. "Payments"). Features are how capabilities are accessed ("scheduled payments" is a feature of Payments, not a separate capability).

**L1 vs L2** — L1 tells you what exists at a functional level. L2 tells you what can be acted on, migrated, extended, or replaced — it's where modernization plans become executable.

**Pre-generated inputs** — If you have better tooling (nDepend, SonarQube, JetBrains analysis), export results to `docs/discovery/` before running the pipeline. The skills use those files instead of regenerating.

### After pipeline complete

When `copilot-bootstrap discover` detects all 7 steps complete, it automatically runs `copilot-bootstrap generate` to produce project-specific Copilot configuration from the discovered stack and capabilities.

---

## 14. Generator Orchestrator

The generator orchestrator (`copilot-bootstrap generate`) reads context from `.greenfield/` (greenfield) or `.discovery/` (brownfield) and produces project-specific Copilot configuration: instructions, agents, skills, prompts, MCP config, hooks, plugins, and docs. It runs automatically after both pipelines complete, or on demand.

### Context detection

`generate` checks for context files in this order:

1. `.greenfield/context.json` → greenfield mode
2. `.discovery/context.json` → brownfield mode

Both modes run the same 8 generators with the same templates. Greenfield mode additionally reads `decisions.json` and `scope.json`, and emits greenfield-specific artifacts.

### Inputs

| File | Required | Mode | Purpose |
|------|----------|------|---------|
| `.greenfield/context.json` or `.discovery/context.json` | Yes | both | Stack, tools, architecture |
| `.greenfield/decisions.json` | No | greenfield | Stack rationale → `decisions.instructions.md` |
| `.greenfield/scope.json` | No | greenfield | Complexity → `getting-started.md` |
| `docs/analysis/prd.md` | No | both | Requirements context |
| `docs/analysis/capabilities.md` | No | both | Capability list |
| `docs/domain/model.md` | No | both | Domain context |
| `docs/spec/api.md` | No | both | API contracts |

Generators work with `context.json` alone (minimal mode). Spec pipeline outputs enhance them when present (full mode).

### Generator order and rationale

```
1. instructions  — foundational; all other generators respect these conventions
2. agents        — uses instructions + stack to define agent personas
3. skills        — uses tools detection to create runnable skill definitions
4. prompts       — uses skills + agents to create reusable slash commands
5. mcp           — uses stack detection for external tool integrations
6. hooks         — uses skills + prompts to wire lifecycle automation
7. plugins       — bundles agents/skills/hooks into a project manifest
8. docs          — documents everything generated above
```

### Greenfield-specific outputs

| Generator | Extra output | Purpose |
|-----------|-------------|---------|
| `instructions` | `.github/instructions/decisions.instructions.md` | Explains stack rationale from `decisions.json`; helps Copilot maintain consistency with chosen conventions |
| `agents` | `.github/agents/scaffold.agent.md` | Guides initial project setup from spec docs; knows about `docs/analysis/`, `docs/domain/`, `.greenfield/` |
| `prompts` | `.github/prompts/scaffold-project.prompt.md` | Kick off initial project creation using the scaffold agent |
| `prompts` | `.github/prompts/implement-feature.prompt.md` | Implement a named capability from `docs/analysis/capabilities.md` |
| `docs` | `.github/docs/getting-started.md` | Onboarding guide: how to scaffold the project, implement features, run dev tasks |

### Template system

Generators use templates from the `templates/` directory. Variables use `{{UPPER_CASE}}` syntax resolved from `context.json` fields and additional exports:

| Variable | Source |
|----------|--------|
| `{{LANGUAGE}}` | `stack.languages[0]` |
| `{{FRONTEND}}` | `stack.frontend` |
| `{{BACKEND}}` | `stack.backend` |
| `{{DB}}` | `stack.db` |
| `{{PKG_MANAGER}}` | `tools.package_manager` |
| `{{LINTER}}` | `tools.linter` |
| `{{FORMATTER}}` | `tools.formatter` |
| `{{TEST_RUNNER}}` | `tools.test_runner` |
| `{{BUNDLER}}` | `tools.bundler` |
| `{{CONTAINER}}` | `tools.container` |
| `{{ARCH_STYLE}}` | `arch.style` |
| `{{SRC_PATH}}` | `paths.src` |
| `{{TESTS_PATH}}` | `paths.tests` |
| `{{PROJECT_NAME}}` | `context.json → project.name` (fallback: `project.json → name`) |
| `{{APPROACH}}` | `greenfield` or `brownfield` |
| `{{COMPLEXITY}}` | `scope.json → complexity` (greenfield only) |

Template coverage:

| Category | Templates |
|----------|-----------|
| Languages | TypeScript, JavaScript, Python, Go, Java, Rust |
| Frameworks | React, Vue, Next.js, Express, FastAPI, Django |
| Architectures | Layered, Hexagonal, Microservices, Monolith, Serverless |
| Agents | backend, frontend, test, refactor, devops, **scaffold** (greenfield) |
| Skills | build, test, lint, format, deploy |
| Prompts | new-feature, fix-bug, write-tests, review-pr, **scaffold-project**, **implement-feature** (greenfield) |
| Hooks | session-start, pre-tool-use, post-tool-use |

### Resumability

Generator progress is tracked in `{context-dir}/generators.lock.json`:
- Greenfield: `.greenfield/generators.lock.json`
- Brownfield: `.discovery/generators.lock.json`

Each generator has a status: `pending`, `in_progress`, `completed`, `skipped`, or `failed`. Re-running `copilot-bootstrap generate` skips completed generators and resumes from the first incomplete one. Use `--force` to re-run everything.

```json
{
  "version": "1",
  "started_at": "2026-03-26T10:15:00Z",
  "generators": {
    "instructions": { "status": "completed", "outputs": ["..."], "completed_at": "..." },
    "agents":       { "status": "completed", "outputs": ["..."], "completed_at": "..." },
    "skills":       { "status": "in_progress" },
    "prompts":      { "status": "pending" },
    "mcp":          { "status": "pending" },
    "hooks":        { "status": "pending" },
    "plugins":      { "status": "pending" },
    "docs":         { "status": "pending" }
  }
}
```

---

## 15. Google Stitch Integration

Google Stitch generates high-fidelity HTML + TailwindCSS screens from natural language prompts via an MCP server.

### Where it fits

```
flows.md  →  Stitch MCP  →  docs/design/screens/*.html  →  spec
```

The Designer agent generates screens after `flows.md` is complete, covering every entry in the IA screen inventory.

### Setup

```sh
# 1. Get an API key at stitch.withgoogle.com → account settings
# 2. Install the SDK
npm install @google/stitch-sdk
# 3. Set the key
export STITCH_API_KEY=your-key-here
```

`.vscode/mcp.json` already includes the Stitch MCP server configuration. Restart VS Code and verify `stitch` tools appear when you type `#` in Copilot Chat.

Full setup guide: `docs/design/stitch-setup.md`

### Usage

```
/stitch                      Generate all screens from ia.md
/stitch dashboard screen     Regenerate one specific screen
```

### Graceful fallback

If Stitch is not configured, Designer logs a warning in `screens/index.md` and continues. Run `/stitch` later once setup is complete.

### Free tier limits

| Plan | Model | Generations/month |
|------|-------|------------------|
| Standard | Gemini 2.5 Flash | 350 |
| Experimental | Gemini 2.5 Pro | 50 |

---

## 16. ADLC Extended Workflow

The Agentic Development Lifecycle (ADLC) extends the standard bootstrap with phases designed for building and operating AI systems in production.

### When it activates

ADLC activates when `project_info → type` is `agent` or `ai-system`. Sets `project.json → adlc = true`. The extended pipeline appends to either greenfield or brownfield.

### ADLC phases

| Phase | Steps | Output |
|-------|-------|--------|
| Scope & Problem | `constraints`, `kpis` + PRD agentic sections | Regulatory constraints, error tolerance, KPI thresholds, failure modes |
| Agent Definition | `human_agent_map`, `agent_pattern`, `cost_model` | Autonomy boundaries, architecture pattern, tool inventory, token economics |
| Proof of Value | `eval_framework`, `pov` | Evaluation framework, golden dataset spec, PoV plan with go/no-go gate |
| Deployment | `monitoring` | Dashboards, alert thresholds tied to KPIs, rollback criteria |
| Governance | `governance` | Model versioning, feedback loops, drift monitoring, audit policy |

### Key concepts

**Human-Agent Responsibility Map** — Maps every task and decision to agent-can-do, human-must-do, or approval-required. This is the core ADLC artifact. It defines the agent's autonomy boundaries before any code is written.

**Autonomy levels** (set during `complexity` step):
- `reactive` — responds to requests, no background action
- `assistive` — takes actions on user request within a defined scope
- `autonomous` — initiates tasks, makes decisions, acts without per-request approval

**Proof of Value** — A hard validation gate before full implementation. Test the highest-risk assumption with a minimal prototype against a golden dataset. Go/no-go criteria derive from KPIs.

**ADLC rules** (enforced when `adlc = true`):
- Development and evaluation are inseparable — never build first and test later
- Every prompt change, model change, or tool addition requires a re-run of the eval suite
- Human-agent boundaries in `human-agent-map.md` are hard constraints, not guidelines
- Go/no-go thresholds in `pov-plan.md` are not negotiable
- Deployment is activation, not completion — `monitoring.md` defines what to watch after launch
- Model updates from providers are not safe by default — always run evals first

### Brownfield + ADLC

A brownfield project with type `agent` or `ai-system` gets both pipelines:

```
Bootstrap → Discovery → Analyst → Architect → Designer → Spec → Evaluator → Script → Ops
(answers)   (codebase)  (PRD)     (domain)    (design)   (spec) (eval+pov)  (dev)    (monitoring+governance)
```

---

## 17. Extending the Framework

### Add a new bootstrap step

1. Add the step name to `docs/workflow/bootstrap.md` (and `brownfield.md` if applicable)
2. Add its questions to `.github/skills/bootstrap-ask/SKILL.md`
3. Add a row to the routing table in `docs/workflow/agents.md`
4. Add the questions to `scripts/ask.sh`
5. Create a generation skill under `.github/skills/` if the step produces a document

### Add a new agent

1. Create `.github/agents/my-agent.agent.md`:
   ```yaml
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
2. Add it to the `agents:` list of the agent that will call it
3. Add it to the routing table in `docs/workflow/agents.md`
4. Update `.github/copilot-instructions.md`

### Add a new slash command

1. Create `.github/prompts/my-command.prompt.md`:
   ```yaml
   ---
   name: my-command
   description: What this command does
   agent: ask
   ---
   Prompt instructions here.
   ```
2. It appears in the `/` menu automatically

### Add a new skill

1. Create `.github/skills/my-skill/SKILL.md`:
   ```yaml
   ---
   name: my-skill
   description: What this skill does
   argument-hint: "[optional hint]"
   ---
   # Instructions
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

## 18. Troubleshooting

### Agent is not visible in the chat selector

Check the file has `.agent.md` extension and is in `.github/agents/`. Check `user-invocable` is not set to `false` (only Bootstrap should be visible).

### Handoff button is not appearing

The handoff only appears after the agent finishes its instructions. Verify the `handoffs:` block is valid YAML in the frontmatter.

### ADLC steps are not activating

Check `project.json → adlc` is `true` and `project.json → type` is `agent` or `ai-system`. If type was set before the ADLC update, manually add `"adlc": true` to `project.json`.

### Hooks are not running

Enable: `"chat.useCustomAgentHooks": true` in VS Code settings. Verify `scripts/validate-state.sh` is executable (`chmod +x`). The hook requires `jq`.

### `validate-state.sh` fails with JSON error

An agent edited state into an invalid form. Run:

```sh
cat .project/state/workflow.json
cat .project/state/answers.json
```

Fix manually, or jump back to a known-good step:

```sh
copilot-bootstrap step prd
```

### An agent cannot find a required input file

A required earlier step did not run. Use `/status` to see missing files, then `/reset <step>` to re-run the missing phase.

### `scan` detected the wrong language or framework

Edit `.discovery/context.json` directly and correct the value. The schema is in `.discovery/context.schema.json`. Re-run `copilot-bootstrap generate` to regenerate config from the corrected context.

### `generate` failed partway through

Check `.discovery/generators.lock.json` to see which generator failed. Fix the issue, then re-run `copilot-bootstrap generate` — completed generators are skipped automatically.

### Discovery agent cannot read the codebase

Check `answers.json → codebase_setup.path` is a valid path accessible from the workspace. Verify with `ls <path>`.

### Brownfield steps are not activating

Check both `project.json → approach` and `workflow.json → approach` are `"brownfield"`. If set after initialization, update both files manually.

### `next` or `step` says step not found

The step name in `workflow.json` does not match the active workflow file. For brownfield, scripts read `docs/workflow/brownfield.md`; for greenfield, `docs/workflow/bootstrap.md`. Set `step` to a valid value: `copilot-bootstrap step --list`.

---

*End of Manual*

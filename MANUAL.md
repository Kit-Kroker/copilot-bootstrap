# Copilot Bootstrap — Manual

A multi-agent workflow that takes a project idea and produces a full implementation-ready specification: PRD, domain model, RBAC, API spec, design artifacts, and dev scaffolding scripts — all driven by GitHub Copilot agents in VS Code.

Supports **greenfield** (build from scratch) and **brownfield** (modernize existing code) approaches. Brownfield uses a 7-step capability extraction pipeline to analyze the existing codebase before generating specifications.

For **agent** and **ai-system** projects, the workflow extends with the Agentic Development Lifecycle (ADLC): KPIs, human-agent responsibility mapping, agent architecture patterns, cost modelling, evaluation frameworks, Proof of Value plans, monitoring, and governance. ADLC composes with both greenfield and brownfield approaches.

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
9. [Scripts](#9-scripts)
10. [File Structure](#10-file-structure)
11. [Google Stitch Integration](#11-google-stitch-integration)
12. [ADLC Extended Workflow](#12-adlc-extended-workflow)
13. [Brownfield Discovery Pipeline](#13-brownfield-discovery-pipeline)
14. [Extending the Framework](#14-extending-the-framework)
15. [Troubleshooting](#15-troubleshooting)

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

If the project type is `agent` or `ai-system`, the ADLC extended workflow activates automatically — the pipeline continues through Evaluator and Ops agents until `adlc_done`.

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

**Greenfield pipeline** (default):
```
Bootstrap → Analyst → Architect → Designer → Spec → Script
```

**Brownfield pipeline** (when approach is `brownfield`):
```
Bootstrap → Discovery → Analyst → Architect → Designer → Spec → Script
```

**ADLC extension** (appends when type is `agent` or `ai-system`):
```
... → Evaluator → Script → Ops
```

### State Machine

Workflow progress is tracked in two files:

- `.project/state/workflow.json` — current step and status
- `.project/state/answers.json` — all collected answers

Both files are updated by agents after each step. The `project.json` root file mirrors the current step and includes the `approach` and `adlc` flags for quick reference.

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

ADLC extends this chain:

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

If a required input file is missing, the agent will report what needs to run first.

---

## 4. Project Types & Approach

### Project Types

Valid project types are set during the `project_info` step:

| Type | Description | ADLC |
|------|-------------|------|
| `web-app` | Traditional UI-driven application | No |
| `mobile` | Native or hybrid mobile application | No |
| `api` | Headless API service or backend | No |
| `cli` | Command-line tool | No |
| `agent` | Single LLM-driven agent with tool use | Yes |
| `ai-system` | Multi-agent or LLM-core product | Yes |

When type is `agent` or `ai-system`:
- `project.json → adlc` is set to `true`
- The `complexity` step also asks for **autonomy level** (`reactive` / `assistive` / `autonomous`)
- Two additional bootstrap steps are added: `constraints` and `kpis`
- After the standard bootstrap completes, the ADLC extended workflow activates

### Project Approach

The approach is also set during the `project_info` step:

| Approach | Description |
|----------|-------------|
| `greenfield` | Building from scratch — user provides idea, features, tech stack (default) |
| `brownfield` | Modernizing existing code — 7-step capability extraction pipeline analyzes the codebase first |

When approach is `brownfield`:
- `project.json → approach` is set to `"brownfield"`
- `.project/state/workflow.json → approach` is set to `"brownfield"`
- The workflow switches to `docs/workflow/brownfield.md`
- Steps `users`, `features`, `tech`, `complexity` are replaced by `codebase_setup` + 7 discovery steps
- A new `codebase_setup` step collects: codebase path, primary language, architecture style, DB access, pre-generated reports
- The Discovery agent runs the 7-step capability extraction pipeline
- After discovery, the pipeline merges back into `prd` → `capabilities` → `domain` with discovery outputs as primary input
- ADLC extension still applies if type is `agent` or `ai-system` (approach and type are orthogonal)

---

## 5. Workflow Steps

### Standard Bootstrap — Greenfield (13 steps)

Defined in `docs/workflow/bootstrap.md`.

| # | Step | Agent | Output |
|---|------|-------|--------|
| 1 | `idea` | Bootstrap | answers.json: idea, pain_points |
| 2 | `project_info` | Bootstrap | answers.json: project_info; project.json updated |
| 3 | `users` | Bootstrap | answers.json: users |
| 4 | `features` | Bootstrap | answers.json: features |
| 5 | `tech` | Bootstrap | answers.json: tech |
| 6 | `complexity` | Bootstrap | answers.json: complexity (+ autonomy_level for agents) |
| 7 | `prd` | Analyst | docs/analysis/prd.md |
| 8 | `capabilities` | Analyst | docs/analysis/capabilities.md |
| 9 | `domain` | Architect | docs/domain/model.md, rbac.md, workflows.md |
| 10 | `design_workflow` | Designer | docs/design/overview.md, ia.md, flows.md |
| 11 | `skills` | Script | .github/skills/ (dev skill stubs) |
| 12 | `scripts` | Script | scripts/*.sh |
| 13 | `done` | — | Standard bootstrap complete |

### ADLC Extended Steps (10 steps, agent/ai-system only)

Defined in `docs/workflow/adlc.md`. Activate after `done` when `adlc = true`.

| # | Step | Agent | Output |
|---|------|-------|--------|
| 14 | `constraints` | Bootstrap | answers.json: constraints |
| 15 | `kpis` | Bootstrap | answers.json: kpis |
| 16 | `human_agent_map` | Analyst | docs/analysis/human-agent-map.md |
| 17 | `agent_pattern` | Architect | docs/domain/agent-pattern.md |
| 18 | `cost_model` | Architect | docs/domain/cost-model.md |
| 19 | `eval_framework` | Evaluator | docs/spec/eval.md |
| 20 | `pov` | Evaluator | docs/spec/pov-plan.md |
| 21 | `monitoring` | Ops | docs/ops/monitoring.md |
| 22 | `governance` | Ops | docs/ops/governance.md |
| 23 | `adlc_done` | — | Full ADLC lifecycle complete |

### Brownfield Discovery Steps (replaces greenfield steps 3-6)

Defined in `docs/workflow/brownfield.md`. Active when `approach = brownfield`.

| # | Step | Agent | Output |
|---|------|-------|--------|
| 3 | `codebase_setup` | Bootstrap | answers.json: codebase_setup |
| 4 | `seed_candidates` | Discovery | docs/discovery/candidates.md |
| 5 | `analyze_candidates` | Discovery | docs/discovery/analysis.md |
| 6 | `verify_coverage` | Discovery | docs/discovery/coverage.md |
| 7 | `lock_l1` | Discovery | docs/discovery/l1-capabilities.md |
| 8 | `define_l2` | Discovery | docs/discovery/l2-capabilities.md |
| 9 | `discovery_domain` | Discovery | docs/discovery/domain-model.md |
| 10 | `blueprint_comparison` | Discovery | docs/discovery/blueprint-comparison.md |

After discovery, the workflow continues with `prd` (step 11) → `capabilities` → `domain` → ... using discovery outputs as input. The generation skills (generate-prd, generate-capabilities, generate-domain) switch to brownfield mode automatically, reading from `docs/discovery/` instead of user-supplied answers.

### Questions Asked Per Step

| Step | Questions |
|------|-----------|
| `idea` | Describe your project idea; What is currently manual, slow, or error-prone?; Why is a human doing this today? |
| `project_info` | Name; type (`web-app` / `mobile` / `api` / `cli` / `agent` / `ai-system`); domain; approach (`greenfield` / `brownfield`) |
| `codebase_setup` | Codebase path; primary language; architecture style; DB access; pre-generated reports; has frontend *(brownfield only)* |
| `users` | Who are the users; what roles do they have |
| `features` | List 3–10 core features |
| `tech` | Backend, frontend, database/infra preferences |
| `complexity` | `simple` / `saas` / `enterprise`; autonomy level (agent/ai-system only) |
| `constraints` | Regulatory requirements; max error rate; forbidden actions; latency tolerance; data sources *(ADLC only)* |
| `kpis` | Primary business metric; 30-day success criteria; minimum accuracy; kill-switch criteria *(ADLC only)* |

---

## 6. Agents

Agents are defined in `.github/agents/`. Select an agent in the Copilot Chat panel before typing.

### Bootstrap
**File:** `.github/agents/bootstrap.agent.md`
**Tools:** `read`, `edit`, `agent`
**Visible in chat:** Yes

Collects all project answers step by step. Asks only missing questions. Saves answers to `answers.json` after each step. When all answer steps are complete, presents the **Generate PRD & Capabilities** handoff button.

For ADLC projects, also collects `constraints` and `kpis` answers, and sets `project.json → adlc = true`.

For brownfield projects, also collects `codebase_setup` answers. When complete, routes to the **Discovery** agent instead of Analyst.

**Hook:** Runs `./scripts/validate-state.sh` after every file edit to ensure `workflow.json` and `answers.json` remain valid JSON.

---

### Discovery *(brownfield only)*
**File:** `.github/agents/discovery.agent.md`
**Tools:** `read`, `edit`, `search/codebase`
**Visible in chat:** No (called via handoff from Bootstrap)

Analyzes an existing codebase using the 7-step capability extraction pipeline:

| Step | Skill | Output |
|------|-------|--------|
| `seed_candidates` | `discover-candidates` | docs/discovery/candidates.md |
| `analyze_candidates` | `analyze-candidates` | docs/discovery/analysis.md |
| `verify_coverage` | `verify-coverage` | docs/discovery/coverage.md |
| `lock_l1` | `lock-l1` | docs/discovery/l1-capabilities.md |
| `define_l2` | `define-l2` | docs/discovery/l2-capabilities.md |
| `discovery_domain` | `generate-discovery-domain` | docs/discovery/domain-model.md |
| `blueprint_comparison` | `compare-blueprint` | docs/discovery/blueprint-comparison.md |

Each step reads one input, produces one output, and feeds the next. The pipeline is adaptive — it skips unavailable signal sources (no DB, no frontend). Each step also accepts pre-generated inputs (if its output file already exists in `docs/discovery/`, it uses that instead of regenerating).

When done, presents the **Generate PRD from Discovery** handoff button.

---

### Analyst
**File:** `.github/agents/analyst.agent.md`
**Tools:** `read`, `edit`
**Visible in chat:** No (called via handoff from Bootstrap)

Generates analysis documents from `answers.json`:
1. `docs/analysis/prd.md` — Product Requirements Document (includes agentic sections for ADLC)
2. `docs/analysis/capabilities.md` — Capability map with dependencies and feature traceability

For ADLC projects, also generates:
3. `docs/analysis/kpis.md` — Business and technical KPIs with thresholds
4. `docs/analysis/human-agent-map.md` — Human vs agent responsibility matrix

When done, presents the **Model Domain & Architecture** handoff button.

---

### Architect
**File:** `.github/agents/architect.agent.md`
**Tools:** `read`, `edit`
**Visible in chat:** No (called via handoff from Analyst)

Generates domain architecture documents in order:
1. `docs/domain/model.md` — Entities, aggregates, bounded contexts, domain events
2. `docs/domain/rbac.md` — Roles, permission matrix, scope rules
3. `docs/domain/workflows.md` — Business workflows, state transitions, capability traceability

For ADLC projects, also generates:
4. `docs/domain/agent-pattern.md` — Agent architecture pattern, tool inventory, orchestration framework, context/memory design
5. `docs/domain/cost-model.md` — Token economics, monthly cost estimates at three usage tiers, cost optimisation options

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

Uses consistent naming across all four files.

When done:
- **ADLC active:** presents the **Generate Eval Framework & PoV Plan** handoff button (routes to Evaluator)
- **ADLC inactive:** presents the **Generate Scripts & Dev Skills** handoff button (routes to Script)

---

### Evaluator *(ADLC only)*
**File:** `.github/agents/evaluator.agent.md`
**Tools:** `read`, `edit`
**Visible in chat:** No (called via handoff from Spec)

Generates two evaluation documents:
1. `docs/spec/eval.md` — Evaluation framework: success metrics, evaluation methods per output type, golden dataset spec, regression testing strategy, tooling recommendation
2. `docs/spec/pov-plan.md` — Proof of Value plan: highest-risk assumption, PoV scope, golden dataset requirements, baseline metrics, go/no-go gate criteria

When done, presents the **Generate Scripts & Dev Skills** handoff button.

---

### Script
**File:** `.github/agents/script.agent.md`
**Tools:** `read`, `edit`, `run`
**Visible in chat:** No (called via handoff from Spec or Evaluator)

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

When done:
- **ADLC active:** presents the **Generate Monitoring & Governance** handoff button (routes to Ops)
- **ADLC inactive:** sets workflow to `done` and `project.json` stage to `ready`

**Hook:** Runs `./scripts/validate-state.sh` after every file edit.

---

### Ops *(ADLC only)*
**File:** `.github/agents/ops.agent.md`
**Tools:** `read`, `edit`
**Visible in chat:** No (called via handoff from Script)

Generates two operational documents:
1. `docs/ops/monitoring.md` — Observability dashboards, alert thresholds (tied to KPIs), escalation paths, rollback trigger criteria, logging requirements
2. `docs/ops/governance.md` — Model versioning policy, feedback loop setup, concept drift monitoring, knowledge base refresh schedule, audit log requirements

Sets workflow to `adlc_done` and `project.json` stage to `ready`.

---

## 7. Slash Commands

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

Print a dashboard showing current step, answers collected, and which output files exist. When ADLC is active, also shows ADLC-specific files.

```
/status
```

Example output:
```
Bootstrap Status
────────────────
Step:    prd (in_progress)
Type:    agent
ADLC:    true

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

ADLC files:
  docs/analysis/kpis.md              ❌ missing
  docs/analysis/human-agent-map.md   ❌ missing
  ...
```

---

### `/adlc-status`
**File:** `.github/prompts/adlc-status.prompt.md`

Extended status view organised by ADLC phase. Shows standard bootstrap status plus all ADLC-specific documents grouped by phase (Scope & KPIs, Architecture, PoV, Ops).

```
/adlc-status
```

---

### `/pov`
**File:** `.github/prompts/pov.prompt.md`

Print the Proof of Value plan and go/no-go criteria from `docs/spec/pov-plan.md`. Useful during PoV execution to keep the team aligned on what is being validated and what the thresholds are.

```
/pov
```

---

### `/discovery-status`
**File:** `.github/prompts/discovery-status.prompt.md`

Show the brownfield discovery pipeline progress. Lists each of the 7 discovery output files with completion status, candidate counts, coverage percentage, and summary statistics. Only available when approach is `brownfield`.

```
/discovery-status
```

---

### `/reset`
**File:** `.github/prompts/reset.prompt.md`

Jump the workflow to a specific step without deleting existing output files. Useful for re-running a phase after editing answers.

```
/reset prd
/reset domain
/reset spec
/reset constraints
```

Valid step names depend on the approach. For greenfield: `idea`, `project_info`, `users`, `features`, `tech`, `complexity`, `prd`, `capabilities`, `domain`, `design_workflow`, `skills`, `scripts`, `done` (+ ADLC steps). For brownfield: `idea`, `project_info`, `codebase_setup`, `seed_candidates`, `analyze_candidates`, `verify_coverage`, `lock_l1`, `define_l2`, `discovery_domain`, `blueprint_comparison`, `prd`, `capabilities`, `domain`, `design_workflow`, `skills`, `scripts`, `done` (+ ADLC steps).

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

### `/review-agent`
**File:** `.github/prompts/review-agent.prompt.md`

Cross-check all ADLC documents for consistency:
- KPIs in `kpis.md` have corresponding metrics in `eval.md`
- Human-agent map tasks map to capabilities in `capabilities.md`
- PoV go/no-go thresholds match KPI thresholds
- Agent pattern tools match integrations
- Cost model references the correct model
- Monitoring alerts reference KPI thresholds
- Governance addresses all compliance requirements from constraints

```
/review-agent
```

---

### `/stitch`
**File:** `.github/prompts/stitch.prompt.md`

Generate or regenerate UI screens via Google Stitch MCP.

```
/stitch
/stitch dashboard screen
```

---

## 8. Skills

Skills are reusable prompt workflows in `.github/skills/`. They are invoked by agents or directly via `/skill-name` in chat.

### Workflow Skills (internal)

| Skill | Purpose |
|-------|---------|
| `workflow-read` | Read current step and status from `workflow.json` |
| `workflow-update` | Update `workflow.json` and `project.json` after a step |
| `bootstrap-ask` | Ask only missing questions for the current step |
| `bootstrap-next` | Advance to the next step in `bootstrap.md` |

### Standard Generation Skills

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

### Brownfield Discovery Skills

These skills are only used when `project.json → approach = "brownfield"`. They are run by the Discovery agent.

| Skill | Triggered at step | Output |
|-------|------------------|--------|
| `discover-candidates` | `seed_candidates` | `docs/discovery/candidates.md` |
| `analyze-candidates` | `analyze_candidates` | `docs/discovery/analysis.md` |
| `verify-coverage` | `verify_coverage` | `docs/discovery/coverage.md` |
| `lock-l1` | `lock_l1` | `docs/discovery/l1-capabilities.md` |
| `define-l2` | `define_l2` | `docs/discovery/l2-capabilities.md` |
| `generate-discovery-domain` | `discovery_domain` | `docs/discovery/domain-model.md` |
| `compare-blueprint` | `blueprint_comparison` | `docs/discovery/blueprint-comparison.md` |

### What Each Discovery Skill Produces

**`discover-candidates`** — Extracts capability candidates from 4 signal sources: package structure, database schema, backend entry points (REST, jobs, consumers), frontend entry points (pages, routes). Cross-references signals and assigns HIGH/MEDIUM/LOW confidence. Produces 15-25 raw candidates with evidence trails. Adaptive: skips DB analysis if no access, skips frontend if API-only.

**`analyze-candidates`** — Deep analysis of each candidate: cohesion, coupling, boundary clarity. Forces each into a decision: confirm as capability, split into smaller ones, merge into broader domain, de-scope as non-business (infrastructure/cross-cutting), or flag for architect review. Key heuristic: deployment boundaries do not define business capabilities.

**`verify-coverage`** — Maps all significant source files to capabilities. Targets >90% code coverage. Identifies orphan code and recommends: assign to existing capability, create new capability, mark as infrastructure, or mark as dead code.

**`lock-l1`** — Finalizes the Level 1 capability list from confirmed, split, and merged candidates. Assigns stable IDs (BC-001, BC-002...) in logical domain order. Documents merge trace and excluded items.

**`define-l2`** — For each L1 capability, defines Level 2 sub-capabilities as executable units of work. Maps each L2 to specific code locations, entities (with ownership: OWNS/MANAGES/READS/CREATES), operations (with endpoints), and external dependencies. Calculates migration complexity indicators.

**`generate-discovery-domain`** — Consolidated domain model with capability hierarchy (L1→L2), entity catalog with ownership matrix, cross-capability dependencies, bounded context candidates, and infrastructure/cross-cutting concerns. Every entity, operation, and boundary is mapped to specific files.

**`compare-blueprint`** — Compares code-derived capabilities against industry reference frameworks (BIAN for banking, TM Forum for telecom, APQC cross-industry). Classifies each as aligned, org-specific, or missing-from-code. Code remains source of truth; comparison adds context for modernization planning.

### ADLC Generation Skills

These skills are only used when `project.json → adlc = true`.

| Skill | Triggered at step | Agent | Output |
|-------|------------------|-------|--------|
| `generate-kpis` | `kpis` | Analyst | `docs/analysis/kpis.md` |
| `generate-human-agent-map` | `human_agent_map` | Analyst | `docs/analysis/human-agent-map.md` |
| `generate-agent-pattern` | `agent_pattern` | Architect | `docs/domain/agent-pattern.md` |
| `generate-cost-model` | `cost_model` | Architect | `docs/domain/cost-model.md` |
| `generate-eval-framework` | `eval_framework` | Evaluator | `docs/spec/eval.md` |
| `generate-pov-plan` | `pov` | Evaluator | `docs/spec/pov-plan.md` |
| `generate-monitoring-spec` | `monitoring` | Ops | `docs/ops/monitoring.md` |
| `generate-governance` | `governance` | Ops | `docs/ops/governance.md` |

### What Each ADLC Skill Produces

**`generate-kpis`** — Business KPIs (cycle time, accuracy, cost per outcome, escalation rate), technical KPIs (hallucination rate, latency, token cost, tool call success rate), quality thresholds, 30-day success definition, kill-switch criteria, go/no-go gate.

**`generate-human-agent-map`** — Responsibility matrix mapping every task/decision to agent-can-do, human-must-do, or approval-required. Covers all features, failure modes, data access, and external system interactions. Includes hard boundaries, escalation rules, and risk assessment.

**`generate-agent-pattern`** — Recommended architecture pattern (ReAct / Plan-and-Execute / Multi-agent) with justification. Tool inventory with read-only/mutates flags. Orchestration framework recommendation. Context and memory design (static, dynamic, session, ephemeral). Model selection per component.

**`generate-cost-model`** — Token usage breakdown per request. Monthly cost estimates at three tiers (100 / 1,000 / 10,000 requests per day). Cost optimisation options (prompt caching, model tiering, batching, token reduction). Infrastructure costs (hosting, vector DB, external APIs, monitoring).

**`generate-eval-framework`** — Success metrics with thresholds from KPIs. Evaluation methods by output type (deterministic, NL, actions, multi-step). Golden dataset spec (size, coverage, governance). Regression testing strategy (per commit, pre-release, on model update). Tooling recommendation.

**`generate-pov-plan`** — PoV objective (highest-risk assumption, experiment, success criteria). PoV scope (included/excluded capabilities, timeboxed effort). Golden dataset for PoV. Baseline vs target metrics. Go/no-go gate criteria with proceed/investigate/stop thresholds.

**`generate-monitoring-spec`** — Agent health dashboard (request volume, success rate, latency, token usage, cost, tool call success, escalation rate). Quality dashboard (accuracy, hallucination rate, user satisfaction, drift). Alert thresholds tied to KPIs. Escalation paths. Rollback trigger criteria. Logging requirements.

**`generate-governance`** — Model versioning policy (when to test, how to test, decision criteria, rollout strategy). Feedback loop setup (collection, processing, improvement pipeline). Concept drift monitoring (signals, thresholds, response). Knowledge base refresh policy. Audit log requirements with compliance mapping.

---

## 9. Scripts

Shell scripts in `scripts/`. All require `jq`. Run `chmod +x scripts/*.sh` if needed.

### `init.sh`

Initialise a fresh project state. Safe — exits with an error if state already exists.

```sh
./scripts/init.sh
```

Creates:
- `.project/state/workflow.json` — step: `idea`, status: `in_progress`
- `.project/state/answers.json` — empty `{}`
- `project.json` — blank project metadata (includes `approach`, `codebase_path`, `autonomy_level`, and `adlc` fields)
- All output folders (including `docs/discovery/`)

---

### `next.sh`

Advance the workflow to the next step. Reads `workflow.json → approach` to determine which workflow file to use (`bootstrap.md` for greenfield, `brownfield.md` for brownfield).

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

## 10. File Structure

```
.github/
  copilot-instructions.md         Always-on project context

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

  prompts/
    bootstrap.prompt.md           /bootstrap    — start or resume
    status.prompt.md              /status       — show current state
    discovery-status.prompt.md    /discovery-status — show discovery pipeline progress**
    adlc-status.prompt.md         /adlc-status  — show ADLC-specific state*
    pov.prompt.md                 /pov          — print PoV plan*
    reset.prompt.md               /reset        — jump to a step
    review-spec.prompt.md         /review-spec  — validate spec consistency
    review-agent.prompt.md        /review-agent — validate ADLC doc consistency*
    stitch.prompt.md              /stitch       — generate UI screens

  skills/
    workflow-read/SKILL.md        Read workflow state
    workflow-update/SKILL.md      Update workflow state
    bootstrap-ask/SKILL.md        Ask missing questions
    bootstrap-next/SKILL.md       Advance to next step
    generate-prd/SKILL.md         Generate PRD
    generate-capabilities/SKILL.md Generate capability map
    generate-kpis/SKILL.md        Generate KPIs and thresholds*
    generate-human-agent-map/SKILL.md Generate human-agent responsibility map*
    generate-domain/SKILL.md      Generate domain model
    generate-rbac/SKILL.md        Generate RBAC policy
    generate-workflows/SKILL.md   Generate business workflows
    generate-agent-pattern/SKILL.md Generate agent architecture pattern*
    generate-cost-model/SKILL.md  Generate token economics and cost model*
    generate-design-workflow/SKILL.md Generate design plan
    generate-ia/SKILL.md          Generate information architecture
    generate-flows/SKILL.md       Generate user flows
    generate-spec/SKILL.md        Generate implementation spec
    generate-eval-framework/SKILL.md Generate evaluation framework*
    generate-pov-plan/SKILL.md    Generate Proof of Value plan*
    generate-skills/SKILL.md      Generate dev skill stubs
    generate-scripts/SKILL.md     Generate operational scripts
    generate-monitoring-spec/SKILL.md Generate monitoring spec*
    generate-governance/SKILL.md  Generate governance doc*
    discover-candidates/SKILL.md  Extract capability candidates from codebase**
    analyze-candidates/SKILL.md   Deep analysis of each candidate**
    verify-coverage/SKILL.md      Verify >90% code coverage by capabilities**
    lock-l1/SKILL.md              Finalize L1 capability list**
    define-l2/SKILL.md            Define L2 sub-capabilities**
    generate-discovery-domain/SKILL.md  Generate domain model from code**
    compare-blueprint/SKILL.md    Industry blueprint comparison**

.project/
  state/
    workflow.json                 { workflow, approach, step, status }
    answers.json                  { idea, pain_points, project_info, codebase_setup**, users, features, tech, complexity, autonomy_level, constraints*, kpis* }

docs/
  workflow/
    bootstrap.md                  Greenfield bootstrap sequence (13 standard + 10 ADLC)
    brownfield.md                 Brownfield bootstrap sequence (17 standard + 10 ADLC)**
    design.md                     13-step design sub-workflow
    adlc.md                       ADLC extended workflow definition*
    agents.md                     Routing table: step → agent → skill
  discovery/
    candidates.md                 Raw capability candidates with confidence ratings**
    analysis.md                   Candidate analysis (confirm/split/merge/de-scope)**
    coverage.md                   Code coverage verification**
    l1-capabilities.md            Locked L1 capability list with stable IDs**
    l2-capabilities.md            L2 sub-capabilities mapped to code**
    domain-model.md               Code-derived domain model with traceability**
    blueprint-comparison.md       Industry reference comparison**
  analysis/
    prd.md                        Product Requirements Document
    capabilities.md               Capability map
    kpis.md                       Business and technical KPIs*
    human-agent-map.md            Human-agent responsibility matrix*
  domain/
    model.md                      Entities, aggregates, domain events
    rbac.md                       Roles, permission matrix
    workflows.md                  Business workflows
    agent-pattern.md              Agent architecture, tools, memory design*
    cost-model.md                 Token economics, cost estimates*
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
    eval.md                       Evaluation framework and golden dataset*
    pov-plan.md                   Proof of Value plan and go/no-go criteria*
  ops/
    monitoring.md                 Observability, alerts, rollback criteria*
    governance.md                 Model versioning, feedback loops, audit*

scripts/
  init.sh                         Initialise project state
  next.sh                         Advance to next step
  step.sh                         Read or set current step
  ask.sh                          Print questions for a step
  validate-state.sh               Validate state file integrity

project.json                      Project metadata (name, type, domain, approach, codebase_path, step, autonomy_level, adlc)
```

*Files and entries marked with `*` are ADLC-specific — only generated/used when type is `agent` or `ai-system`. Files marked with `**` are brownfield-specific — only generated/used when approach is `brownfield`.*

---

## 11. Google Stitch Integration

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

## 12. ADLC Extended Workflow

The Agentic Development Lifecycle (ADLC) extends the standard bootstrap with phases designed specifically for building and operating AI agent systems in production.

### When It Activates

ADLC activates automatically when `project_info → type` is set to `agent` or `ai-system`. This sets `project.json → adlc = true`.

### ADLC Phases Mapped to Steps

| ADLC Phase | Bootstrap Steps | What Gets Produced |
|------------|----------------|-------------------|
| Phase 0 — Preparation & Hypotheses | `idea` (pain points) | Pain point framing alongside the project idea |
| Phase 1 — Scope Framing & Problem Definition | `constraints`, `kpis`, `prd` (agentic sections) | Regulatory constraints, error tolerance, KPI thresholds, agent role, failure modes |
| Phase 2 — Agent Definition & Architecture | `human_agent_map`, `agent_pattern`, `cost_model` | Autonomy boundaries, architecture pattern, tool inventory, token economics |
| Phase 3 — Simulation & Proof of Value | `eval_framework`, `pov` | Evaluation framework, golden dataset spec, PoV plan with go/no-go gate |
| Phase 4 — Implementation & Evals | `eval_framework` (regression strategy) | Per-commit and pre-release eval strategy |
| Phase 5 — Testing | `eval_framework` (golden dataset, tooling) | Dataset requirements, tooling recommendations |
| Phase 6 — Agent Activation & Deployment | `monitoring` | Observability dashboards, alert thresholds, rollback criteria |
| Phase 7 — Continuous Learning & Governance | `governance` | Model versioning, feedback loops, drift monitoring, audit policy |

### Key Concepts

**Human-Agent Responsibility Map** — Maps every task and decision to agent-can-do, human-must-do, or approval-required. This is the core ADLC concept with no equivalent in traditional SDLC. It defines the agent's autonomy boundaries.

**Autonomy Levels** — Set during the `complexity` step:
- `reactive` — responds to requests, no background action
- `assistive` — takes actions on user request within a defined scope
- `autonomous` — initiates tasks, makes decisions, acts without per-request approval

**Proof of Value (PoV)** — A hard validation gate. Before building the full system, test the highest-risk assumption with a minimal prototype against a golden dataset. The go/no-go criteria are derived from KPIs.

**ADLC Rules** — When `adlc = true`, these rules are enforced:
- Development and evaluation are inseparable — never build first and test later
- Every prompt change, model change, or tool addition requires a re-run of the eval suite
- Human-agent boundaries in `human-agent-map.md` are hard constraints
- Go/no-go thresholds in `pov-plan.md` are not negotiable
- Deployment is activation, not completion — `monitoring.md` defines what to watch
- Model updates from providers are not safe by default — always run evals first

### ADLC-Specific Slash Commands

| Command | Purpose |
|---------|---------|
| `/adlc-status` | Show all ADLC documents grouped by phase |
| `/pov` | Print the PoV plan and go/no-go thresholds |
| `/review-agent` | Cross-check all ADLC documents for consistency |

---

## 13. Brownfield Discovery Pipeline

The brownfield discovery pipeline extracts a complete business capability map from an existing codebase in 7 steps.

### When It Activates

Brownfield activates when `project_info → approach` is set to `brownfield`. This sets `project.json → approach = "brownfield"` and switches the workflow to `docs/workflow/brownfield.md`.

### Pipeline Steps

| Step | Phase | What Happens |
|------|-----------|-------------|
| A1: Seed Candidates | `seed_candidates` | Extract signals from 4 sources: package structure, DB schema, backend entry points, frontend entry points. Cross-reference and assign confidence. Produce 15-25 raw candidates. |
| A2: Analyze Candidates | `analyze_candidates` | Per candidate: assess cohesion, coupling, boundary clarity. Determine action: confirm/split/merge/de-scope/flag. |
| A3: Verify Coverage | `verify_coverage` | Map all source files to capabilities. Target >90% coverage. Resolve orphan code. |
| A4: Lock L1 | `lock_l1` | Finalize L1 capability list with stable IDs (BC-001, BC-002...). |
| A5: Define L2 | `define_l2` | Per L1: define L2 sub-capabilities mapped to code locations, entities, operations. L2 = executable units of work. |
| A6: Domain Model | `discovery_domain` | Consolidated domain model with capability hierarchy, entity ownership, cross-capability dependencies, code traceability. |
| A7: Blueprint Comparison | `blueprint_comparison` | Compare against industry reference (BIAN, TM Forum, APQC). Flag: aligned / org-specific / missing-from-code. |

### Design Principles

- **Adaptive by default** — Skips unavailable signals (no DB → skip schema, API-only → skip frontend). Extraction continues with fewer signals.
- **Pre-generated inputs accepted** — Each skill checks if its output file already exists. Feed it nDepend exports, JetBrains analysis, DBA reports, or architecture notes to anchor the analysis.
- **Confidence-driven** — Every candidate carries HIGH/MEDIUM/LOW confidence. Ambiguous candidates are flagged for human review, not silently resolved.
- **Code is truth** — Industry comparison adds context but does not override code-derived capabilities. Missing capabilities drive targeted questions, not assumptions.
- **Traceable throughout** — Every capability, entity, and operation is mapped to specific files and code locations.

### Key Concepts

**Capability vs Feature** — A capability is what the business does (e.g. "Payments"). Features are how capabilities are accessed or configured (e.g. "scheduled payments" is a feature of the Payments capability, not a separate capability).

**L1 vs L2** — L1 tells you what exists at a functional level. L2 tells you what can be acted on, migrated, extended, or replaced. L2 is where modernization plans become executable.

**Confidence Ratings** — HIGH means the candidate appears across 3+ signal sources. MEDIUM means 2 sources or strong in 1. LOW means 1 source with weak evidence. These guide architect review — HIGH candidates are almost certainly real capabilities, LOW ones need human judgment.

**Pre-Generated Inputs** — If you have better tooling (nDepend, SonarQube, JetBrains code analysis), export results to `docs/discovery/` before running the pipeline. The skills will use these files instead of regenerating. This anchors the AI analysis in higher-quality signals.

### Brownfield + ADLC

A brownfield project with type `agent` or `ai-system` gets both pipelines:

```
Bootstrap → Discovery → Analyst → Architect → Designer → Spec → Evaluator → Script → Ops
(answers)   (codebase)  (PRD+caps) (domain)   (design)  (spec) (eval+pov)  (scripts) (monitoring+governance)
```

Total steps: 3 (bootstrap) + 7 (discovery) + 7 (generation) + 10 (ADLC) = 27 steps.

### Brownfield-Specific Slash Commands

| Command | Purpose |
|---------|---------|
| `/discovery-status` | Show all 7 discovery pipeline outputs with statistics |

---

## 14. Extending the Framework

### Add a new bootstrap step

1. Add the step name to `docs/workflow/bootstrap.md` (and/or `docs/workflow/brownfield.md` if applicable) in the correct position
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

## 15. Troubleshooting

### Agent is not visible in the chat selector

- Check that the file has `.agent.md` extension and is in `.github/agents/`
- Check that `user-invocable` is not set to `false` (only the Bootstrap agent should be visible)

### Handoff button is not appearing

- The handoff only appears after the agent finishes its instructions
- Check that the `handoffs:` block is valid YAML in the agent frontmatter

### ADLC steps are not activating

- Check `project.json → adlc` is `true`
- Check `project.json → type` is `agent` or `ai-system`
- If type was set before the ADLC update, manually set `"adlc": true` in `project.json`

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

The step name in `workflow.json` does not match any step in the active workflow file. For brownfield projects, the scripts read `docs/workflow/brownfield.md`; for greenfield, `docs/workflow/bootstrap.md`. Check that `workflow.json → approach` matches the correct workflow file. Edit `workflow.json` directly and set `step` to a valid value from `./scripts/step.sh --list`.

### Discovery agent cannot read the codebase

Check that `answers.json → codebase_setup.path` is a valid absolute path or relative to the workspace root. If the codebase is in a different workspace, the agent needs the path to be accessible. Verify with `ls <path>`.

### Brownfield steps are not activating

Check `project.json → approach` is `"brownfield"` and `workflow.json → approach` is `"brownfield"`. If approach was set after workflow initialization, manually update both files.

---

*End of Manual*

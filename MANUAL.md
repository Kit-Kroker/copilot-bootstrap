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
12. [Brownfield Discovery Pipeline](#12-brownfield-discovery-pipeline)
13. [EDCR Security & QA Assessment Pipeline](#13-edcr-security--qa-assessment-pipeline)
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
copilot-bootstrap init   # copies framework files (.github/, docs/workflow/) to your project
code .
```

Everything after this runs in Copilot Chat:

```
/bootstrap idea: freelancer invoicing tool
```

Answer 6 questions conversationally (idea, project info, users, features, tech, complexity). Then:

```
/build-context   — derives context.json, decisions.json, scope.json from your answers
/spec            — creates the pipeline lock and runs all spec generation steps automatically
/generate        — generates Copilot configuration tailored to your stack and project domain
```

**Smart defaults**: pick React → Vite + ESLint + Prettier + Vitest are set automatically by `/build-context`. Pick Python → Pip + Ruff + Black + Pytest. All toolchain decisions are recorded in `.greenfield/decisions.json`.

**Resumable**: both the spec pipeline and generators track progress in lock files. Re-run `/spec` or `copilot-bootstrap generate` after an interruption — completed steps are skipped.

### Brownfield — existing codebase

```sh
cd /path/to/existing-project
copilot-bootstrap init
code .
```

In Copilot Chat — the full workflow runs here, no terminal needed after init:

```
/init            — initialize project state as brownfield (includes security + QA scope setup)
/scan            — auto-detect language, framework, database, tools, architecture + extract security + QA signals
/discover        — run capability extraction steps + attach security and QA context to each capability
/report          — generate stakeholder, architect, dev, SDET, and security reports  [optional, SDET always emitted]
/assess          — STRIDE threat modeling, vulnerability detection, control mapping, QA risk analysis, unified risk scoring
/generate        — generate AI-ready security + QA context packages + Copilot configuration
/finish          — remove bootstrap scaffolding
```

**No interview.** `/scan` captures the stack, security signals, and QA signals; `/discover` extracts capabilities and attaches security and QA context; `/report` (optional) produces five audience-specific reports (stakeholder, architect, dev, SDET always; security if `/assess` has run); `/assess` produces per-capability threat models, QA risk scores, and a unified composite risk score; `/generate` and `/finish` produce the final artifacts.

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

**Greenfield**:

```
/bootstrap (chat)    → .greenfield/answers.json
/build-context (chat)→ .greenfield/context.json + decisions.json + scope.json
/spec (chat)         → creates pipeline.lock.json, then runs:
    Analyst  → docs/analysis/prd.md, capabilities.md
    Architect→ docs/domain/model.md, rbac.md, workflows.md
    Designer → docs/design/overview.md, ia.md, flows.md
    Spec     → docs/spec/api.md
    Script   → .github/skills/ (dev skills)
/generate (chat)     → .github/copilot-instructions.md, skills/, prompts/, agents/, .vscode/settings.json
```

**Brownfield**:

```
/init (chat)         → project.json (approach: brownfield) + security_scope + qa_scope in answers.json
/scan (chat)         → .discovery/context.json + confidence.json + docs/security/security-signals.json + docs/qa/qa-signals.json
                       + docs/qa/test-inventory.json, coverage/, testability/, environments/
/discover (chat)     → creates pipeline.lock.json, then runs Discovery (capability steps + attach-security-context + attach-qa-context)
/report (chat)       → docs/discovery/stakeholder-report.md, architect-report.md, dev-report.md  [optional — run after /discover]
                       docs/qa/sdet-report.md  [always emitted; renders degraded when QA signals are partial]
                       docs/security/security-report.md  [only if /assess has been run]
/assess (chat)       → docs/security/threats/, vulnerabilities/, controls/, risk-scores.json
                       docs/qa/qa-risk-scores.json, qa-gaps.json
                       docs/risk/unified-risk-map.json
/generate (chat)     → docs/security/generate/ + docs/qa/generate/ + .github/copilot-instructions.md, skills/, prompts/, .claude/settings.json
/finish (chat)       → removes scaffolding
```

**ADLC extension** (appends when type = `agent` or `ai-system`):

```
... → Evaluator → Script → Ops
```

For brownfield, agents are chained via **handoff buttons**. Each agent completes its phase and presents a button that passes context to the next.

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

Brownfield uses a discovery chain instead of the interview:

```
.discovery/context.json (from /scan)
  └─► docs/security/security-signals.json (from /scan, parallel)
  └─► docs/qa/qa-signals.json + test-inventory.json + coverage/ + testability/ + environments/ (from /scan, parallel)
  └─► docs/discovery/candidates.md
        └─► docs/discovery/analysis.md
              └─► docs/discovery/coverage.md
                    └─► docs/discovery/l1-capabilities.md
                          └─► docs/discovery/l2-capabilities.md
                                └─► docs/discovery/domain-model.md
                                      └─► docs/discovery/blueprint-comparison.md
                                            ├─► docs/discovery/stakeholder-report.md  (/report, always)
                                            ├─► docs/discovery/architect-report.md    (/report, always; includes QA + security overlays)
                                            ├─► docs/discovery/dev-report.md           (/report, always; includes QA + security findings)
                                            ├─► docs/qa/sdet-report.md                 (/report, always; renders degraded when QA partial)
                                            ├─► docs/security/capability-security-contexts.json
                                            └─► docs/qa/qa-context.json
                                                  ├─► docs/security/threats/ (/assess)
                                                  │     └─► docs/security/vulnerabilities/
                                                  │           └─► docs/security/controls/
                                                  │                 └─► docs/security/risk-scores.json
                                                  ├─► docs/qa/qa-risk-scores.json + qa-gaps.json (/assess)
                                                  └─► docs/risk/unified-risk-map.json (/assess; security + QA composite)
                                                        └─► docs/security/generate/ + docs/qa/generate/ (/generate)
                                                              └─► docs/security/security-report.md (/report, if /assess ran)
                                                                                    .github/copilot-instructions.md
                                                                                    .github/skills/
                                                                                    .github/prompts/
                                                                                    .github/agents/project.agent.md
                                                                                    .claude/settings.json
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

When `brownfield`: there is no interview. `/scan` auto-detects the stack; `/discover` runs 7 capability extraction steps; `/generate` produces Copilot configuration from what was found. ADLC is not applicable to brownfield projects.

---

## 5. Workflow Steps

### Greenfield pipeline

| Phase | How to run | Output |
|-------|-----------|--------|
| Interview | `/bootstrap idea: <text>` in Copilot Chat | `.greenfield/answers.json` |
| Context build | `/build-context` in Copilot Chat | `.greenfield/context.json`, `decisions.json`, `scope.json` |
| Spec pipeline | `/spec` in Copilot Chat | `docs/analysis/`, `docs/domain/`, `docs/design/`, `docs/spec/`, `.github/skills/` |
| Generate | `/generate` in Copilot Chat | `.github/copilot-instructions.md`, `.github/skills/`, `.github/prompts/`, `.github/agents/project.agent.md`, `.vscode/settings.json` |

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

#### Generation steps (5 steps — run after spec pipeline via `/generate`)

| Step | Skill | Output |
|------|-------|--------|
| `generate_instructions` | `generate-greenfield-copilot-instructions` | `.github/copilot-instructions.md` |
| `generate_dev_skills` | `generate-greenfield-skills` | `.github/skills/` |
| `generate_dev_prompts` | `generate-greenfield-prompts` | `.github/prompts/` |
| `generate_hooks` | `generate-greenfield-hooks` | `.vscode/settings.json` |
| `generate_project_agent` | `generate-greenfield-agent` | `.github/agents/project.agent.md` |

### Standard bootstrap — greenfield (13 steps, brownfield reference)

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

### Brownfield workflow (replaces greenfield entirely — no interview)

**Scan phase** (`/scan`) — runs parallel signal extraction (capability + security + QA):

| Step | Skill | Output |
|------|-------|--------|
| `seed_candidates` | `discover-candidates` | docs/discovery/candidates.md |
| `scan_security` | `scan-security-signals` | docs/security/security-signals.json |
| `scan_qa` | `scan-qa-signals` | docs/qa/qa-signals.json, test-inventory.json, coverage/coverage-map.json, testability/testability-findings.json, environments/environment-map.json, environments/ci-map.json |

**Discovery phase** (`/discover`):

| # | Step | Skill | Output |
|---|------|-------|--------|
| 1 | `seed_candidates` | `discover-candidates` | docs/discovery/candidates.md |
| 2 | `analyze_candidates` | `analyze-candidates` | docs/discovery/analysis.md |
| 3 | `verify_coverage` | `verify-coverage` | docs/discovery/coverage.md |
| 4 | `lock_l1` | `lock-l1` | docs/discovery/l1-capabilities.md |
| 5 | `define_l2` | `define-l2` | docs/discovery/l2-capabilities.md |
| 6 | `discovery_domain` | `generate-discovery-domain` | docs/discovery/domain-model.md |
| 7 | `blueprint_comparison` | `compare-blueprint` | docs/discovery/blueprint-comparison.md |
| 8 | `attach_security_context` | `attach-security-context` | docs/security/capability-security-contexts.json |
| 9 | `attach_qa_context` | `attach-qa-context` | docs/qa/qa-context.json |

**Report suite** (`/report`) — optional, standalone:

| Step | Skill | Output |
|------|-------|--------|
| `generate_stakeholder_report` | `generate-stakeholder-report` | docs/discovery/stakeholder-report.md |
| `generate_architect_report` | `generate-architect-report` | docs/discovery/architect-report.md |
| `generate_dev_report` | `generate-dev-report` | docs/discovery/dev-report.md |
| `generate_sdet_report` | `generate-sdet-report` | docs/qa/sdet-report.md *(always emitted; renders degraded when QA signals are partial, with a Not-Collected Summary)* |
| `generate_security_report` | `generate-security-report` | docs/security/security-report.md *(only if `/assess` has been run)* |

**Security + QA assessment phase** (`/assess`):

| # | Step | Skill | Output |
|---|------|-------|--------|
| 1 | `threat_model` | `threat-model` | docs/security/threats/BC-{NNN}.json + threat-summary.md |
| 2 | `vulnerability_detection` | `detect-vulnerabilities` | docs/security/vulnerabilities/catalog.json + summary |
| 3 | `map_controls` | `map-controls` | docs/security/controls/control-map.json + summary |
| 3b | `qa_risk_analysis` | `analyze-qa-risk` | docs/qa/qa-risk-scores.json + qa-gaps.json |
| 4 | `score_risks` | `score-risks` | docs/security/risk-scores.json + cross-capability-risks.json + gaps.json + docs/risk/unified-risk-map.json |

**Generation phase** (`/generate`):

| # | Step | Skill | Output |
|---|------|-------|--------|
| 1 | `generate_security_contexts` | `generate-security-contexts` | docs/security/generate/ (AI context packages + remediation prompts + spec seeds) |
| 2 | `generate_instructions` | `generate-copilot-instructions` | .github/copilot-instructions.md |
| 3 | `generate_dev_skills` | `generate-brownfield-skills` | .github/skills/ |
| 4 | `generate_stack_skills` | `generate-stack-skills` | .github/skills/ |
| 5 | `generate_dev_prompts` | `generate-brownfield-prompts` | .github/prompts/ |
| 6 | `generate_hooks` | `generate-brownfield-hooks` | .vscode/settings.json |
| 7 | `generate_project_agent` | `generate-project-agent` | .github/agents/project.agent.md |

**Cleanup** (`/finish`):

After `/generate` completes, run `/finish` to remove all bootstrap scaffolding. This leaves a clean project with only the generated artifacts. See [Section 7 — `/finish`](#finish) for the full list of what is deleted and kept.

All steps are resumable — re-run the command after an interruption to continue from where it left off.

### Questions asked per step (greenfield only)

Brownfield has no interview. All inputs come from auto-detection (`/scan`) and code analysis (`/discover`).

| Step | Questions |
|------|-----------|
| `idea` | Describe your project; what is currently manual or slow; why is a human doing it today |
| `project_info` | Name; type; domain; approach |
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

### Project *(generated by `/generate` — both approaches)*
**File:** `.github/agents/project.agent.md` | **Visible in chat:** Yes

This agent is **not part of the bootstrap pipeline** — it is an output of the pipeline. Generated as the final step of `/generate`, it becomes the primary development agent once bootstrap is complete.

**Brownfield**: generated by `generate-project-agent`. References actual capability IDs (BC-001, BC-002...), real entity names from `docs/discovery/domain-model.md`, the detected tech stack, and the project-specific skills generated alongside it.

**Greenfield**: generated by `generate-greenfield-agent`. References capabilities from `docs/analysis/capabilities.md`, domain entities from `docs/domain/model.md`, the chosen tech stack from `.greenfield/context.json`, and the dev skills generated by the spec pipeline.

In both cases, developers select this agent in Copilot Chat to start feature work after bootstrap is complete. After running `/finish`, this is the only agent that remains in `.github/agents/`.

---

## 7. Slash Commands

Type `/` in Copilot Chat to access these commands. All commands run entirely in chat — no terminal required except where noted.

### Setup

#### `/init`
Initialize a new project. Creates `.project/state/workflow.json`, `.project/state/answers.json`, `project.json`, and `.greenfield/answers.json`. For brownfield projects, also collects security scope (standard, compliance targets, risk tolerance), QA scope (coverage/automation targets, test pyramid, environments, defect tracker, CI system), and creates the `docs/security/`, `docs/qa/`, and `docs/risk/` directory structures. Safe — exits if state already exists.

```
/init
```

Use this when opening a new empty folder in VS Code. If you ran `copilot-bootstrap init` from the terminal already, skip this.

---

#### `/scan`
Scan the current codebase to detect language, framework, database, tools, and architecture. Writes `.discovery/context.json` and `.discovery/confidence.json`. **Brownfield only.**

```
/scan
/scan path/to/codebase
```

Fields detected with confidence ≥ 0.85 are used automatically in the bootstrap interview. Fields with lower confidence are shown for confirmation. Fields not detected are asked directly.

---

### Greenfield workflow

#### `/bootstrap`
Start or resume the workflow. Routes to Bootstrap from the current step.

```
/bootstrap
/bootstrap idea: inventory management system
```

---

#### `/build-context`
Build `.greenfield/context.json`, `decisions.json`, and `scope.json` from interview answers. Applies derivation rules (runtime from language, architecture from project type) and smart toolchain defaults.

```
/build-context
```

Requires the bootstrap interview to be complete (all 6 steps in `.greenfield/answers.json`). Prints a summary of derived values and applied defaults on completion.

---

#### `/spec`
Initialize the greenfield spec pipeline and run it automatically. Creates `.greenfield/pipeline.lock.json`, applies skip-if-exists for any output files that already exist, then immediately executes all pending steps in sequence.

```
/spec
```

Requires `project.json → approach = "greenfield"` and `.greenfield/context.json`. If interrupted, re-run `/spec` to resume from the first incomplete step.

---

### Brownfield workflow

#### `/discover`
Initialize the brownfield discovery pipeline and run it automatically. Creates `.discovery/pipeline.lock.json`, applies skip-if-exists, then runs all 7 capability extraction steps plus security context attachment in sequence.

```
/discover
```

Requires `project.json → approach = "brownfield"` and `.discovery/context.json` (from `/scan`). Also requires `docs/security/security-signals.json` and `docs/qa/qa-signals.json` (both from `/scan`) for security and QA context attachment. No interview needed. Re-run to resume after an interruption.

---

#### `/report`
Generate the full discovery report suite from completed brownfield discovery results. Runs four report skills in sequence. **Optional — run after `/discover` completes.**

```
/report
```

Produces four reports unconditionally (requires all discovery steps complete, including QA context attachment):

**`docs/discovery/stakeholder-report.md`** — audience: executives, PMs, BAs
- Plain language throughout — no jargon, no file paths, no code
- Capability list with health signals (Strong / Needs Attention / At Risk)
- Industry alignment summary with genuine gaps flagged separately
- Modernisation posture (Retain / Extend / Refactor / Evaluate / Replace) per capability
- Proposed team ownership areas from bounded context analysis

**`docs/discovery/architect-report.md`** — audience: solutions architects, enterprise architects
- Capability topology with cohesion/coupling metrics and dependency graph
- Bounded context analysis with cross-context dependency table
- Decomposition options ranked by feasibility given current coupling
- Modernisation posture with metric-level rationale
- Orphan code hotspots with architectural risk assessment
- QA risk overlay per capability (coverage, automation, testability, defects)
- Security risk overlay per capability (if `/assess` has been run)
- Unified risk map — capabilities ranked by security + QA composite with drivers (if `/assess` has been run)

**`docs/discovery/dev-report.md`** — audience: developers, tech leads, engineering managers
- Capability-to-code map with exact file/module paths per capability
- Ownership assignments derived from bounded context candidates
- Health dashboard for sprint planning and tech debt backlog
- Refactor targets with specific techniques and scope estimates
- Orphan code hotspots with recommended actions
- QA findings: testability blockers with file:line pointers and specific refactoring hints, coverage gaps against highest-churn files, flaky tests to stabilise or retire
- Confirmed vulnerabilities and critical control gaps (if `/assess` has been run)
- Sprint recommendations as ticket-ready action items (including testability and coverage work)

**`docs/qa/sdet-report.md`** — audience: SDETs, QA engineers, QA leads, test architects, release managers

- Always emitted after `/discover`. Capabilities with no collected QA signals appear with explicit `not-collected` rows and a reason — absence of data is itself a finding
- Test strategy snapshot (current pyramid shape vs. target)
- Per-capability coverage map (unit / integration / e2e %, source = report vs proxy vs not-collected, confidence)
- Automation status matrix (regression / smoke / contract / performance per capability)
- Testability hotspots (ranked; recommended seams with file:line pointers)
- Defect and flakiness profile (open defects, flaky-test rates, top flakes by capability)
- Environment readiness and parity issues per capability
- CI quality gates (mandatory / optional / absent test levels; enforced thresholds)
- QA risk ranking and unified risk view (if `/assess` has run)
- Per-capability test strategy recommendations and sprint-ready QA backlog
- Not-Collected Summary — mandatory section enumerating every QA signal gap and its reason

Produces a fifth report if `/assess` has been run:

**`docs/security/security-report.md`** — audience: security team, tech leads
- Risk-ranked findings with CRITICAL/HIGH vulnerabilities and specific file:line references
- Mitigation priorities split into Immediate / Short-term / Medium-term
- Compliance posture per target standard (GDPR, PCI-DSS, HIPAA)
- Systemic risks spanning multiple capabilities
- Full capability risk map with composite scores
- Also produces: `docs/security/security-risk-map.json`, `docs/security/threat-catalog.json`, `docs/security/domain-model-secured.md`

If `/assess` has not been run, the security report step is skipped and the completion message directs to `/assess`.

---

#### `/assess`
Run the EDCR security + QA assessment pipeline. Applies STRIDE threat modeling to each capability, detects and classifies vulnerabilities, maps existing controls, computes per-capability QA risk (coverage gap, testability, defect density, change velocity), and combines security and QA into a unified composite risk score per capability with drivers. **Brownfield only.**

```
/assess
```

Requires `docs/security/capability-security-contexts.json` and `docs/qa/qa-context.json` (both from `/discover`). Runs 5 steps in sequence: threat modeling, vulnerability detection, control mapping, QA risk analysis, unified risk scoring. Outputs artifacts to `docs/security/`, `docs/qa/`, and `docs/risk/`. Re-run to resume after an interruption.

Steps:
- `threat_model` → `docs/security/threats/BC-{NNN}.json` + `threat-summary.md`
- `vulnerability_detection` → `docs/security/vulnerabilities/catalog.json` + summary
- `map_controls` → `docs/security/controls/control-map.json` + summary
- `qa_risk_analysis` → `docs/qa/qa-risk-scores.json` + `docs/qa/qa-gaps.json` (`"unknown"` posture explicit where signals were not collected — never substituted with defaults)
- `score_risks` → `docs/security/risk-scores.json`, `cross-capability-risks.json`, `gaps.json`, and `docs/risk/unified-risk-map.json` (per-capability unified composite with drivers)

---

#### `/generate`
Generate project-specific Copilot configuration. Works for both greenfield and brownfield — branches automatically on `project.json → approach`.

```
/generate
```

**Greenfield**: requires `.greenfield/context.json` and `docs/analysis/capabilities.md` (from `/spec`). Creates `.greenfield/generate.lock.json` and runs 4 steps: copilot instructions, project prompts, VS Code workspace settings, and the project agent.

**Brownfield**: requires `.discovery/context.json` and `docs/discovery/l1-capabilities.md` (from `/discover`). Creates `.discovery/generate.lock.json` and runs: security context packages (if `/assess` was run), copilot instructions, dev skills, stack skills, project prompts, workspace settings, and the project agent.

Outputs are tailored to the actual stack and domain — not generic templates. Re-run to resume after an interruption.

---

#### `/finish`
Remove bootstrap scaffolding after `/generate` completes. Works for both greenfield and brownfield. Leaves only the project agent, generated skills, generated prompts, VS Code settings, and all docs.

```
/finish
```

Pre-flight: verifies `.github/agents/project.agent.md`, `.github/copilot-instructions.md`, and at least one project-specific prompt exist before deleting anything. Shows a confirmation summary (what will be deleted, what will be kept) and waits for "yes" before proceeding.

**Deleted by `/finish`:**
- Greenfield: `.greenfield/` — interview answers, context, pipeline state
- Brownfield: `.discovery/` — scan outputs, pipeline state
- Both: `.project/` — workflow and answers state
- `project.json`, `MANUAL.md`
- `docs/workflow/` — bootstrap workflow docs
- `scripts/` — bootstrap init/next/step/ask scripts
- All bootstrap agents (bootstrap, analyst, architect, designer, spec, script, evaluator, ops, discovery)
- All bootstrap pipeline and generate skills (44 skill directories)
- All bootstrap prompts (16 prompt files including `finish.prompt.md` itself)

**Kept by `/finish`:**
- `.github/agents/project.agent.md`
- `.github/copilot-instructions.md`
- `.github/skills/` — project-specific generated skills
- `.github/prompts/` — project-specific generated prompts
- `.vscode/settings.json`
- `docs/` — all generated project documentation

After `/finish`, the repository contains only project-specific Copilot configuration with no bootstrap machinery.

---

### Status and review

#### `/status`
Show current step, collected answers, and which output files exist.

```
/status
```

---

#### `/discovery-status`
Show brownfield discovery pipeline progress: which of the 7 steps are complete, counts, and coverage stats.

```
/discovery-status
```

---

#### `/adlc-status`
Extended status view for ADLC projects. Shows all ADLC documents grouped by phase.

---

#### `/pov`
Print the Proof of Value plan and go/no-go thresholds from `docs/spec/pov-plan.md`. Use during PoV execution to stay aligned on the experiment scope and pass/fail criteria.

---

#### `/reset`
Jump the workflow to a specific step without deleting output files. Use when re-running a phase after editing answers.

```
/reset prd
/reset domain
/reset constraints
```

---

#### `/review-spec`
Cross-check all four spec files for consistency: resource naming, permission coverage for every API endpoint, event coverage for every state transition, role name consistency with `rbac.md`.

---

#### `/review-agent`
Cross-check all ADLC documents: KPI thresholds match eval thresholds, human-agent map tasks map to capabilities, PoV criteria match KPIs, monitoring alerts reference the correct thresholds.

---

#### `/stitch`
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

Used by `/discover` when `approach = brownfield`.

| Skill | Step | Output |
|-------|------|--------|
| `discover-candidates` | `seed_candidates` | `docs/discovery/candidates.md` |
| `analyze-candidates` | `analyze_candidates` | `docs/discovery/analysis.md` |
| `verify-coverage` | `verify_coverage` | `docs/discovery/coverage.md` |
| `lock-l1` | `lock_l1` | `docs/discovery/l1-capabilities.md` |
| `define-l2` | `define_l2` | `docs/discovery/l2-capabilities.md` |
| `generate-discovery-domain` | `discovery_domain` | `docs/discovery/domain-model.md` |
| `compare-blueprint` | `blueprint_comparison` | `docs/discovery/blueprint-comparison.md` |

### Brownfield reporting skills

Used by `/report` when `approach = brownfield`. Runs after `/discover` completes — independent of the generation phase. Security report requires `/assess` to have completed first.

| Skill | Step | Output |
|-------|------|--------|
| `generate-stakeholder-report` | `generate_stakeholder_report` | `docs/discovery/stakeholder-report.md` |
| `generate-architect-report` | `generate_architect_report` | `docs/discovery/architect-report.md` |
| `generate-dev-report` | `generate_dev_report` | `docs/discovery/dev-report.md` |
| `generate-security-report` | `generate_security_report` | `docs/security/security-report.md` + `security-risk-map.json` + `threat-catalog.json` + `domain-model-secured.md` |

**What each skill produces:**
- `generate-stakeholder-report` — non-technical report for executives, PMs, and BAs. Synthesises all 7 discovery outputs: capability list with health signals (Strong / Needs Attention / At Risk), industry alignment summary with genuine gaps separated from externally-handled capabilities, modernisation posture (Retain / Extend / Refactor / Evaluate / Replace) per capability, and proposed team ownership areas from bounded context analysis. No jargon, no file paths, no code.
- `generate-architect-report` — technical report for solutions and enterprise architects. Covers capability topology with cohesion/coupling metrics, bounded context analysis with cross-context dependency table, decomposition options ranked by feasibility, orphan code hotspots with architectural risk, and security risk overlay per capability (if available).
- `generate-dev-report` — engineering team report. Provides capability-to-code mapping with exact file paths, ownership assignments, a health dashboard for sprint planning, refactor targets with specific techniques and scope estimates, orphan code hotspots with recommended actions, and confirmed vulnerabilities with sprint-ready ticket items.
- `generate-security-report` — security and risk report for the security team and tech leads. Produces an executive security summary, risk-ranked CRITICAL/HIGH findings with file:line references, mitigation priorities (Immediate / Short-term / Medium-term), compliance posture per target standard, systemic cross-capability risks, and the domain model enriched with full security overlay per capability. Requires `/assess` to have completed.

### EDCR security assessment skills

Used by `/assess` when `approach = brownfield`. Each skill checks for pre-generated input (skip if output exists) so externally generated security analysis can be fed in.

| Skill | Step | Output |
|-------|------|--------|
| `scan-security-signals` | `scan_security` | `docs/security/security-signals.json` |
| `attach-security-context` | `attach_security_context` | `docs/security/capability-security-contexts.json` |
| `threat-model` | `threat_model` | `docs/security/threats/BC-{NNN}.json` + `threat-summary.md` |
| `detect-vulnerabilities` | `vulnerability_detection` | `docs/security/vulnerabilities/catalog.json` + summary |
| `map-controls` | `map_controls` | `docs/security/controls/control-map.json` + summary |
| `score-risks` | `score_risks` | `docs/security/risk-scores.json`, `cross-capability-risks.json`, `gaps.json` |
| `generate-security-contexts` | `generate_security_contexts` | `docs/security/generate/` |

**What each skill produces:**
- `scan-security-signals` — 4 signal sources (SS1–SS4): authentication/authorization patterns, dependency vulnerability flags, configuration risks, data sensitivity classification. Writes a single structured JSON with confidence levels and file references.
- `attach-security-context` — maps all security signals to each L1 and L2 capability; detects trust boundaries (where capabilities cross to external services or change privilege levels)
- `threat-model` — STRIDE threat model per capability, prioritized by criticality; one JSON file per capability plus a summary markdown
- `detect-vulnerabilities` — classifies each finding as confirmed (code evidence), probable (strong pattern), or potential (theoretical); maps every finding to a capability and code location
- `map-controls` — inventories existing controls from security signals, maps them to threats and vulnerabilities, identifies gaps where HIGH/CRITICAL threats have no mitigation
- `score-risks` — likelihood × impact × exposure composite score per capability; also detects shared vulnerabilities, cascading failure paths, and compliance gaps
- `generate-security-contexts` — per-capability AI context packages (self-contained files for Cursor/Copilot/Claude Code), targeted remediation prompts with file:line references, and spec seeds for high-risk capabilities

---

### Greenfield generation skills

Used by `/generate` when `approach = greenfield`. Reads from `.greenfield/context.json` and spec outputs — no generic templates.

| Skill | Step | Output |
|-------|------|--------|
| `run-greenfield-generate-pipeline` | orchestrator | runs all 5 generation steps in sequence |
| `generate-greenfield-copilot-instructions` | `generate_instructions` | `.github/copilot-instructions.md` |
| `generate-greenfield-skills` | `generate_dev_skills` | `.github/skills/` |
| `generate-greenfield-prompts` | `generate_dev_prompts` | `.github/prompts/` |
| `generate-greenfield-hooks` | `generate_hooks` | `.vscode/settings.json` |
| `generate-greenfield-agent` | `generate_project_agent` | `.github/agents/project.agent.md` |

**What each skill produces:**
- `generate-greenfield-copilot-instructions` — project identity, chosen stack, architecture, domain entities, capability map, coding conventions, and hard constraints for this specific stack
- `generate-greenfield-skills` — dev skills derived from the chosen stack (e.g. `add-endpoint` for FastAPI, `add-migration` for Prisma, `add-module` for NestJS); max 12 skills, plus up to 3 capability-derived skills; enhances stubs from the spec pipeline rather than duplicating them
- `generate-greenfield-prompts` — slash commands for common operations: `/status`, `/review-code`, `/implement-capability`, `/scaffold-feature`, plus conditional prompts (DB migrations, component review, lint-fix) and 3 capability-derived prompts
- `generate-greenfield-hooks` — VS Code workspace settings in `.vscode/settings.json` wiring the chosen linter and formatter to format-on-save
- `generate-greenfield-agent` — the primary development agent for the project: capability list, entity ownership, available skills, and working rules derived from the spec docs

### Brownfield generation skills

Used by `/generate` when `approach = brownfield`. Reads from `.discovery/` outputs — no generic templates.

| Skill | Step | Output |
|-------|------|--------|
| `run-generate-pipeline` | orchestrator | runs all 5 generation steps in sequence |
| `generate-copilot-instructions` | `generate_instructions` | `.github/copilot-instructions.md` |
| `generate-brownfield-skills` | `generate_dev_skills` | `.github/skills/` |
| `generate-stack-skills` | `generate_stack_skills` | `.github/skills/` |
| `generate-brownfield-prompts` | `generate_dev_prompts` | `.github/prompts/` |
| `generate-brownfield-hooks` | `generate_hooks` | `.vscode/settings.json` |
| `generate-project-agent` | `generate_project_agent` | `.github/agents/project.agent.md` |

**What each brownfield skill produces:**
- `generate-copilot-instructions` — project identity, detected stack, architecture, domain entities, capability map, coding conventions, hard constraints specific to this project
- `generate-brownfield-skills` — dev skills derived from the actual stack (e.g. `add-endpoint` for Express, `add-migration` for Alembic, `add-module` for NestJS); max 12 skills prioritized by use frequency
- `generate-stack-skills` — stack-specific procedural skills: `implement-feature`, `fix-bug`, `write-docs`, plus language-specific modernization skills (e.g. `modernize-go-handler`, `modernize-python-module`)
- `generate-brownfield-prompts` — slash commands for common operations: `/review-code`, `/explain-capability`, `/trace-flow`, plus conditional prompts for detected tools (DB migrations, integration tests, lint-fix)
- `generate-brownfield-hooks` — VS Code workspace settings in `.vscode/settings.json` wiring the detected linter and formatter to run automatically after file edits
- `generate-project-agent` — the primary development agent for the project: capability table with BC-NNN IDs and code paths, entity ownership rules, tech stack, available skills, and working rules derived from the domain model

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

The core workflow commands (`init`, `interview`, `build-context`, `spec`, `scan`, `discover`) are also available as Copilot Chat slash commands — see [Section 7](#7-slash-commands). Use whichever interface you prefer; both paths produce the same state files.

### `init`

Initialise a fresh project. Copies framework files (`.github/`, `docs/workflow/`) from the installed package to your project directory. Safe — exits if state already exists.

```sh
copilot-bootstrap init
```

Creates `.project/state/workflow.json`, `.project/state/answers.json`, `project.json`, and all output folders. **Note:** the CLI version also copies framework files from the package; the `/init` chat command only creates state files and requires the framework to already be present.

---

### `interview`

Start or resume the greenfield interview from the terminal. Opens a guided flow that shows progress and tells you to use `/bootstrap` in Copilot Chat for the actual Q&A.

```sh
copilot-bootstrap interview
```

Tracks 6 steps: `idea`, `project_info`, `users`, `features`, `tech`, `complexity`. Re-running is safe. Use `/bootstrap` in Copilot Chat as the primary interface; this command is a terminal-side progress view.

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

Initialise or resume the greenfield spec pipeline from the terminal. Validates prerequisites, creates `.greenfield/pipeline.lock.json`, reports step status, and auto-runs `copilot-bootstrap generate` when all steps complete.

```sh
copilot-bootstrap spec
```

Use `/spec` in Copilot Chat as the primary interface — it creates the lock file and immediately runs the full pipeline without switching back to the terminal.

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

Detects: languages, frontend framework, backend framework, database, package manager, linter, test runner, bundler, container tool, architecture style, monorepo flag, entry points. Writes detection confidence scores to `.discovery/confidence.json`. Use `/scan` in Copilot Chat as the primary interface — it reads the same config files and produces the same output.

Output example:
```json
{
  "stack": { "languages": ["typescript"], "backend": "express", "frontend": "react", "db": "postgres" },
  "tools": { "package_managers": [{"name":"npm","version":"10.2.4"}], "linters": [{"name":"eslint","version":"9.0.0"}], "formatters": [{"name":"prettier","version":"3.0.0"}], "test_runners": [{"name":"jest","version":"29.0.0"}], "bundler": {"name":"vite","version":"5.0.0"}, "container": "docker" },
  "arch": { "style": "layered", "monorepo": false, "services": 1 },
  "paths": { "src": "src/", "tests": "tests/" }
}
```

---

### `discover`

Initialise or resume the brownfield discovery pipeline from the terminal. Validates prerequisites, creates `.discovery/pipeline.lock.json`, reports step status, and auto-runs `copilot-bootstrap generate` when all 7 steps complete.

```sh
copilot-bootstrap discover
```

Use `/discover` in Copilot Chat as the primary interface — it creates the lock file and immediately runs the full pipeline without switching back to the terminal.

---

### `discovery-status`

Print current discovery pipeline progress.

```sh
copilot-bootstrap discovery-status
```

---

### `generate-status`

Print current generation pipeline progress.

```sh
copilot-bootstrap generate-status
```

The primary interface for `/generate` is Copilot Chat — use the `/generate` slash command after `/spec` (greenfield) or `/discover` (brownfield). Progress is tracked in `.greenfield/generate.lock.json` (greenfield) or `.discovery/generate.lock.json` (brownfield).

---

### `render-html`

Render the markdown report suite in `docs/` to styled HTML for sharing with stakeholders who don't read markdown in a repo viewer.

```sh
copilot-bootstrap render-html                 # walk docs/, emit .html next to each .md
copilot-bootstrap render-html docs/dev        # scope to a subtree
copilot-bootstrap render-html --out site      # mirror into site/ (for static hosting)
copilot-bootstrap render-html --clean         # delete every .html that has a matching .md
```

Uses pandoc (GFM parser, so tables and task lists render) with an embedded light/dark stylesheet. Relative `.md` cross-links are rewritten to `.html` so the generated pages remain navigable; absolute URLs and anchor-only links are left untouched.

**Requires:** pandoc (`apt install pandoc` / `brew install pandoc`).

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
    init.prompt.md                /init
    scan.prompt.md                /scan**
    bootstrap.prompt.md           /bootstrap
    build-context.prompt.md       /build-context
    spec.prompt.md                /spec
    discover.prompt.md            /discover**
    generate.prompt.md            /generate**
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
    scan-security-signals/SKILL.md**
    attach-security-context/SKILL.md**
    threat-model/SKILL.md**
    detect-vulnerabilities/SKILL.md**
    map-controls/SKILL.md**
    score-risks/SKILL.md**
    generate-security-contexts/SKILL.md**
    generate-security-report/SKILL.md**
    run-discovery-pipeline/SKILL.md**
    run-generate-pipeline/SKILL.md**
    generate-copilot-instructions/SKILL.md**
    generate-brownfield-skills/SKILL.md**
    generate-brownfield-prompts/SKILL.md**
    generate-brownfield-hooks/SKILL.md**
    run-greenfield-generate-pipeline/SKILL.md
    generate-greenfield-copilot-instructions/SKILL.md
    generate-greenfield-skills/SKILL.md
    generate-greenfield-prompts/SKILL.md
    generate-greenfield-hooks/SKILL.md
    generate-greenfield-agent/SKILL.md

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
    answers.json                  { idea, project_info, users, features, tech, complexity, constraints*, kpis* } (greenfield only)

.discovery/                       Machine-readable detection and generation state**
  context.json                    Unified detected stack (written by `/scan`)
  confidence.json                 Detection confidence scores per field
  pipeline.lock.json              Discovery pipeline step progress (written by `/discover`)
  generate.lock.json              Generation pipeline step progress (written by `/generate`)
  context.schema.json             Schema for context.json
  pipeline.lock.schema.json       Schema for pipeline.lock.json

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
  security/**                     EDCR security assessment artifacts (brownfield only)
    security-signals.json**       Extracted security signals (SS1–SS4) with confidence levels
    capability-security-contexts.json**  Per-capability security context and trust boundaries
    risk-scores.json**            Per-capability risk scores (likelihood, impact, exposure, composite)
    cross-capability-risks.json** Shared vulnerabilities, cascading risks, weak boundaries
    gaps.json**                   Prioritized actionable security gaps
    security-report.md**          Executive security summary (/finish output)
    security-risk-map.json**      Machine-readable risk map (/finish output)
    threat-catalog.json**         Complete threat catalog (/finish output)
    domain-model-secured.md**     Domain model with security overlay (/finish output)
    threats/**                    STRIDE threat models, one file per capability
      BC-{NNN}.json**
      threat-summary.md**
    vulnerabilities/**
      catalog.json**              Classified vulnerability catalog
      vulnerability-summary.md**
    controls/**
      control-map.json**          Control-to-threat mapping
      control-summary.md**
    findings/**                   Reserved for additional findings
    generate/**                   AI-ready artifacts for downstream tooling
      security-prompts.md**       Targeted security remediation prompts
      capability-contexts/**      Per-capability AI context packages
        BC-{NNN}-context.md**
      spec-seeds/**               Functional + security specification seeds
        BC-{NNN}-spec-seed.md**
  qa/**                           EDCR QA assessment artifacts (brownfield only)
    qa-signals.json**             Consolidated QA signals (QS1–QS4) with confidence levels
    test-inventory.json**         Classified test inventory with test-to-code mapping
    qa-context.json**             Per-capability QA context (coverage, automation, testability, defects, environments)
    qa-risk-scores.json**         Per-capability QA risk (coverage_gap, testability, defect_density, change_velocity, composite, posture)
    qa-gaps.json**                Prioritised coverage, testability, environment, and strategy gaps
    sdet-report.md**              SDET report — always emitted; includes Not-Collected Summary
    coverage/**
      coverage-map.json**         Per-file coverage (report-sourced or proxy, with confidence)
    testability/**
      testability-findings.json** Testability findings with severity (blocks/impedes/smell)
    defects/**
      flaky-tests.json**          Flaky-test rates from CI history (when registered)
    environments/**
      environment-map.json**      Environment inventory and parity diff
      ci-map.json**               CI pipeline map with test stages and gates
    generate/**                   AI-ready QA artifacts for downstream tooling
      qa-prompts.md**             Targeted testability refactor prompts with file:line pointers
      capability-contexts/**      Per-capability QA context packages
        BC-{NNN}-qa-context.md**
      spec-seeds/**               Test-strategy spec seeds per capability
        BC-{NNN}-test-seed.md**
  risk/**                         Unified risk artifacts (brownfield only)
    unified-risk-map.json**       Per-capability unified composite (security + QA) with drivers
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
`**` = brownfield only (approach is `brownfield`) or generated by `generate`/`assess`/`finish` commands
`†` = greenfield pipeline only (generated by `generate` when `.greenfield/context.json` is present)

---

## 11. Greenfield Pipeline

The greenfield pipeline transforms a project idea into a complete, implementation-ready Copilot configuration in four phases. The pipeline is resumable at any point via lock files.

### Full flow

```
# Terminal (once)
copilot-bootstrap init              → copies .github/, docs/workflow/ to your project
code .

# Copilot Chat
/bootstrap idea: <your idea>        → .greenfield/answers.json (6-step interview)
/build-context                      → .greenfield/context.json + decisions.json + scope.json
/spec                               → .greenfield/pipeline.lock.json, then runs:
                                        docs/analysis/prd.md, capabilities.md
                                        docs/domain/model.md, rbac.md, workflows.md
                                        docs/design/overview.md, ia.md, flows.md
                                        docs/spec/api.md
                                        .github/skills/ (dev skills)

# Terminal (once)
copilot-bootstrap generate          → .github/copilot-instructions.md + instructions/
                                      .github/agents/ (backend, frontend, test, refactor, devops, scaffold)
                                      .github/skills/ (build, test, lint, format, deploy)
                                      .github/prompts/ (new-feature, fix-bug, write-tests, review-pr, ...)
                                      .vscode/mcp.json
                                      .github/docs/getting-started.md
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

`.greenfield/pipeline.lock.json` tracks each step's status. Steps whose output files already exist are automatically marked `skipped` when `/spec` (or `copilot-bootstrap spec`) runs — so you can pre-populate `docs/` with existing content and the pipeline will not overwrite it.

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

## 12. Brownfield Discovery Pipeline

The brownfield discovery pipeline extracts a complete business capability map from an existing codebase in 7 steps, then attaches security context to every capability. Each step reads one input, produces one output, and feeds the next.

### When it activates

Run `/init brownfield` (or `/init` and set `approach = brownfield` when prompted). This creates `project.json` with `approach: brownfield`.

### Before running the pipeline

In Copilot Chat:

```
/scan
```

Writes:
- `.discovery/context.json` — unified stack/tools/architecture context
- `.discovery/confidence.json` — detection confidence per field

Review `.discovery/context.json` before proceeding. Correct any misdetections manually or by re-running `/scan`.

### Running the pipeline

In Copilot Chat:

```
/discover
```

`/discover` validates that `project.json → approach = "brownfield"` and `.discovery/context.json` exists, creates `.discovery/pipeline.lock.json`, applies skip-if-exists checks, and immediately runs all 7 steps in sequence. No interview required. Re-run to resume after an interruption.

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
| A8: Security context attachment | Map security signals from `/scan` to each L1 and L2 capability; detect trust boundaries; assess criticality | `docs/security/capability-security-contexts.json` |

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

When all 8 steps finish (including security context attachment), run in Copilot Chat:

```
/assess
```

This runs STRIDE threat modeling, vulnerability detection, control mapping, and risk scoring across all capabilities. See [Section 13 — EDCR Security Assessment Pipeline](#13-edcr-security-assessment-pipeline) for details.

After `/assess`, run:

```
/generate
```

This produces AI-ready security context packages and project-specific Copilot configuration — tailored instructions, dev skills for the actual stack, domain-aware prompts, and tool hooks. No generic templates.

---

## 13. EDCR Security & QA Assessment Pipeline

The EDCR (Evidence-Driven Capability Reconstruction) Security & QA Assessment extends the brownfield discovery pipeline with capability-aware security **and QA** intelligence. Threats, vulnerabilities, coverage gaps, testability issues, and risks are always mapped to specific capabilities, not to the system as a whole. Security and QA scores combine into a single unified composite per capability so prioritisation is consistent.

### When it runs

After `/discover` completes (which ends with `attach-security-context`), run:

```
/assess
```

### Design principles

- **Capability-aware** — Every threat, vulnerability, coverage gap, and risk score is tied to a specific capability (BC-NNN). A SQL injection in a public payment endpoint and one in an internal admin tool are not the same risk. A 40% coverage gap in a seldom-changed reporting module and a 40% gap in a high-velocity payment capability are not the same risk. Context determines priority.
- **Evidence-driven** — Every finding traces back to a specific file, line, and detection method. No finding exists without evidence. Confidence levels (HIGH/MEDIUM/LOW) are explicit.
- **Pre-generated inputs accepted** — Each skill checks whether its output file already exists. Feed in results from external tools — Snyk / SonarQube / Checkmarx for security, JaCoCo / Cobertura / Istanbul / coverlet for coverage, Jira / Azure DevOps exports for defects, CI run history for flakiness — and the skill skips regeneration.
- **Composite scoring** — Security score combines likelihood, impact, and exposure. QA score combines coverage gap, testability, defect density, and change velocity. Unified composite combines both (0.55 × security + 0.45 × qa by default, overridable in `context.json`). High finding counts alone do not drive priority — business criticality, attack surface, and release readiness do.
- **Honest about missing data** — QA signals that cannot be collected (no coverage report registered, no defect tracker, no CI config) are flagged as `not-collected` with a reason. Missing dimensions make the composite `"unknown"` rather than silently substituting zero. The SDET report's Not-Collected Summary makes every gap visible.
- **False positive management** — Theoretical vulnerabilities, mitigated patterns, and unreachable code paths are flagged separately — never silently removed, but not mixed with real findings.

### Pipeline steps

| Phase | Step | What it produces |
|-------|------|-----------------|
| `/scan` | `scan_security` | Security signals (SS1–SS4): auth patterns, dependency risks, config issues, data sensitivity classifications |
| `/scan` | `scan_qa` | QA signals (QS1–QS4): test inventory, coverage signals, testability findings, environment & CI parsing. Missing inputs emit explicit `not-collected` markers |
| `/discover` | `attach_security_context` | Per-capability security context: data sensitivity, auth, exposure, criticality, trust boundaries |
| `/discover` | `attach_qa_context` | Per-capability QA context: coverage (unit/integration/e2e), automation status, testability rating, defect profile, environment coverage, test-strategy gaps |
| `/assess` | `threat_model` | STRIDE threat model per capability: 6 categories × per-capability security context |
| `/assess` | `vulnerability_detection` | Classified vulnerability catalog: confirmed / probable / potential, each mapped to a capability and code location |
| `/assess` | `map_controls` | Control inventory mapped to threats; coverage gaps for CRITICAL/HIGH unmitigated threats |
| `/assess` | `qa_risk_analysis` | Per-capability QA risk scores and gaps. Posture classified as release-ready / needs work / high-risk / unknown |
| `/assess` | `score_risks` | Per-capability security composite; unified composite combining security + QA with drivers; cross-capability systemic risks; compliance gaps |
| `/report` | `generate_sdet_report` | SDET report — coverage, automation, testability, defects, environments, CI gates, QA risk ranking, QA backlog, Not-Collected Summary. Always emitted |
| `/generate` | `generate_security_contexts` | AI-ready context packages per capability, targeted security remediation prompts, spec seeds for high-risk capabilities |
| `/generate` | `generate_qa_contexts` | Per-capability QA context packages, testability refactor prompts with file:line pointers, test-strategy spec seeds, coverage backlog seeds |
| `/report` | `generate_security_report` | Security report, machine-readable risk map, threat catalog, domain model with security overlay (if `/assess` has run) |

### Key output: domain-model-secured.md

The primary handoff artifact. Contains the full discovery domain model enriched with a security overlay for each capability:

```
BC-001: Customer Onboarding                                    3 L2s
─────────────────────────────────────────────────────────────────────
{capability description from discovery}

{L2 operations...}

Security Assessment:
  Risk Score:       0.63 (#2 of 12)
  Criticality:      high
  Data Handled:     PII, Authentication
  Top Threats:      Spoofing: Account creation with stolen identity (HIGH)
                    Information Disclosure: PII leak via verbose errors (MEDIUM)
  Confirmed Vulns:  1 — VULN-003: Hardcoded API key at config/kyc.js:14
  Control Gaps:     2 — Rate limiting on registration endpoint missing
  Priority:         SHORT-TERM

QA Assessment:
  QA Score:         0.71 (#1 of 12)                          [posture: high-risk]
  Coverage:         unit 34% · integration 8% · e2e 0%       [source: jacoco, HIGH confidence]
  Automation:       regression partial · smoke manual · contract absent
  Testability:      impeded (9 findings; 2 blocks)
                    — static HttpClient in kyc.js:42 blocks unit test of KYC verify flow
  Defect Profile:   4 open · 2 flaky tests · velocity HIGH (18 commits/30d)
  Environments:     dev, staging · missing: pre-prod
  Not-Collected:    flaky-test rate partial (CI history only last 14d)

Unified Risk:       0.66                                      [drivers: PII + public exposure + missing integration tests]
```

### Security scope configuration

During `/init` (brownfield), the following is collected and saved to `answers.json → security_scope`:

| Setting | Default | Options |
|---------|---------|---------|
| `standard` | `OWASP_ASVS` | `OWASP_ASVS`, `NIST`, `custom` |
| `threat_modeling` | `true` | Always enabled |
| `compliance_targets` | `[]` | `GDPR`, `PCI-DSS`, `HIPAA`, `SOC2` |
| `risk_tolerance` | `medium` | `low`, `medium`, `high` |

Compliance targets affect gap analysis: GDPR gaps check PII-handling capabilities for data minimization and audit logging; PCI-DSS gaps check financial capabilities for encryption and access control.

### QA scope configuration

`/init` also collects the QA scope, saved to `answers.json → qa_scope`:

| Setting | Default | Purpose |
|---------|---------|---------|
| `coverage_targets.unit` | `0.70` | Unit coverage target; drives the coverage-gap dimension |
| `coverage_targets.integration` | `0.40` | Integration coverage target |
| `coverage_targets.e2e` | `0.20` | E2E coverage target |
| `automation_targets.regression` | `0.80` | Expected regression automation |
| `automation_targets.smoke` | `1.00` | Expected smoke automation |
| `test_pyramid` | `standard` | `standard`, `inverted`, `trophy`, `custom`; report calls out deviations |
| `environments` | `["dev", "staging", "prod"]` | Environment inventory used for parity checks |
| `defect_tracker` | `none` | `jira`, `azure_devops`, `linear`, `none`; determines whether defect signals are collected |
| `ci_system` | detected | `github_actions`, `jenkins`, `azure_pipelines`, `none` |

The QA scope is informational — missing fields never block the pipeline. They surface as `not-collected` markers in the SDET report rather than gating it.

### Risk scope configuration

The unified composite weighting is overridable via `answers.json → risk_scope.weights`:

| Setting | Default | Purpose |
|---------|---------|---------|
| `weights.security` | `0.55` | Weight of the security sub-score in the unified composite |
| `weights.qa` | `0.45` | Weight of the QA sub-score in the unified composite |

Raise the security weight when breach risk dominates release risk; raise the QA weight when release cadence and regression cost dominate.

---

## 14. Generator Orchestrator

The generator orchestrator differs by approach:

- **Greenfield**: `copilot-bootstrap generate` (CLI) — reads `.greenfield/context.json` and produces instructions, agents, skills, prompts, MCP config, hooks, plugins, and docs
- **Brownfield**: `/generate` (Copilot Chat) — reads `.discovery/context.json` and discovery outputs; produces 4 targeted artifacts specific to the detected stack and domain

### Greenfield generator (CLI)

`copilot-bootstrap generate` reads `.greenfield/context.json`, `decisions.json`, `scope.json`, and spec pipeline outputs. Runs 8 generators in sequence.

**Inputs:**

| File | Required | Purpose |
|------|----------|---------|
| `.greenfield/context.json` | Yes | Stack, tools, architecture |
| `.greenfield/decisions.json` | No | Stack rationale → `decisions.instructions.md` |
| `.greenfield/scope.json` | No | Complexity → `getting-started.md` |
| `docs/analysis/prd.md`, `capabilities.md` | No | Requirements context |
| `docs/domain/model.md` | No | Domain context |
| `docs/spec/api.md` | No | API contracts |

**Generator order:**

```
1. instructions  — foundational conventions
2. agents        — stack-specific agent personas
3. skills        — runnable skill definitions
4. prompts       — reusable slash commands
5. mcp           — external tool integrations
6. hooks         — lifecycle automation
7. plugins       — project manifest
8. docs          — documentation of all generated artifacts
```

**Greenfield-specific outputs:**

| Generator | Extra output | Purpose |
|-----------|-------------|---------|
| `instructions` | `decisions.instructions.md` | Stack rationale from `decisions.json` |
| `agents` | `scaffold.agent.md` | Guides initial project setup from spec docs |
| `prompts` | `scaffold-project.prompt.md`, `implement-feature.prompt.md` | Kickoff and feature implementation |
| `docs` | `getting-started.md` | Onboarding guide for this project |

Progress tracked in `.greenfield/generators.lock.json`. Re-run `copilot-bootstrap generate` to resume; use `--force` to re-run all.

---

### Brownfield generator (Chat — `/generate`)

`/generate` runs in Copilot Chat after `/discover` completes. Uses 4 skills in sequence; all output is derived from actual discovery data.

**Inputs (read-only):**
- `.discovery/context.json` — detected stack, tools, architecture
- `docs/discovery/l1-capabilities.md` — L1 capabilities
- `docs/discovery/l2-capabilities.md` — L2 sub-capabilities with code locations
- `docs/discovery/domain-model.md` — entity ownership and relationships
- `docs/discovery/blueprint-comparison.md` — industry alignment (if present)

**Steps and outputs:**

| Step | Skill | Output |
|------|-------|--------|
| `generate_instructions` | `generate-copilot-instructions` | `.github/copilot-instructions.md` — project identity, stack, entities, capabilities, conventions, hard constraints |
| `generate_dev_skills` | `generate-brownfield-skills` | `.github/skills/` — dev skills for the actual stack; max 12, prioritized by frequency |
| `generate_dev_prompts` | `generate-brownfield-prompts` | `.github/prompts/` — `/review-code`, `/explain-capability`, `/trace-flow`, plus conditional prompts for detected tools |
| `generate_hooks` | `generate-brownfield-hooks` | `.claude/settings.json` — PostToolUse hooks for detected linter and formatter |

Progress tracked in `.discovery/generate.lock.json`. Re-run `/generate` to resume.

**What makes brownfield generation different from greenfield:** brownfield generation reads from discovery artifacts (capabilities, domain model, code locations) and produces configuration that names real entities, real file paths, and real tools from the codebase. Greenfield generation uses templates filled from interview answers. Both approaches refuse to generate generic placeholders.

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

### `/scan` detected the wrong language or framework

Edit `.discovery/context.json` directly and correct the value. The schema is in `.discovery/context.schema.json`. Re-run `copilot-bootstrap generate` to regenerate config from the corrected context.

### `/build-context` says interview is incomplete

Check `.greenfield/answers.json → steps_completed`. If a step is missing, run `/bootstrap` to resume the interview from the incomplete step.

### `/spec` or `/discover` says context not found

`/spec` requires `.greenfield/context.json`. Run `/build-context` first.
`/discover` requires `.discovery/context.json`. Run `/scan` first.

### Pipeline resumes from wrong step after interruption

The pipeline reads `.greenfield/pipeline.lock.json` (or `.discovery/pipeline.lock.json`). If a step shows `in_progress` but never completed, its output file is likely absent. The next `/spec` or `/discover` run will re-run it automatically.

### Greenfield `generate` failed partway through

Check `.greenfield/generators.lock.json` to see which generator failed. Fix the issue, then re-run `copilot-bootstrap generate` — completed generators are skipped automatically.

### Brownfield `/generate` failed partway through

Check `.discovery/generate.lock.json` to see which step failed. Fix the issue, then re-run `/generate` — completed steps are skipped automatically.

### Discovery skills cannot read the codebase

Check `.discovery/context.json → paths.src` is a valid path accessible from the workspace. Re-run `/scan` if the path is wrong or missing.

### Brownfield steps are not activating

Check both `project.json → approach` and `workflow.json → approach` are `"brownfield"`. If set after initialization, update both files manually.

### `/assess` says security signals not found

`/assess` requires `docs/security/security-signals.json` (from `/scan`). If scan ran before the security skills were added, re-run `/scan` or manually trigger `scan-security-signals` to generate the file.

### Security context was not attached after `/discover`

Check `workflow.json → step` after `/discover` completes. If it shows `prd` (old pipeline) rather than `attach_security_context`, the security signals file may not exist. Create `docs/security/security-signals.json` (run `scan-security-signals` manually), then re-run `/discover`.

### Risk scores look identical for all capabilities

The scoring formula needs differentiated inputs. If all capabilities score the same, check: (1) `capability-security-contexts.json` has varying criticality levels, (2) the vulnerability catalog has findings mapped to specific capabilities (not all cross-cutting), (3) the domain model dependency graph shows varied dependency counts.

### `/finish` did not generate the security report

`generate-security-report` requires `docs/security/risk-scores.json` (from `/assess`). If `/assess` was skipped, run it before `/finish`. The report step runs first in `/finish` before any cleanup.

### `next` or `step` says step not found

The step name in `workflow.json` does not match the active workflow file. For brownfield, scripts read `docs/workflow/brownfield.md`; for greenfield, `docs/workflow/bootstrap.md`. Set `step` to a valid value: `copilot-bootstrap step --list`.

---

*End of Manual*

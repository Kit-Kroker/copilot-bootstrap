# Copilot Instructions

This repository uses a multi-agent bootstrap workflow. Agents are defined in `.github/agents/`. Skills are defined in `.github/skills/`.

## How to Start

Open Copilot Chat, select the **Bootstrap** agent, and type:

```
idea: <your project idea>
```

The agents will guide you through the full workflow step by step.

## Agent Pipeline

### Greenfield (default)

```
Bootstrap  →  Analyst  →  Architect  →  Designer  →  Spec  →  Script
(answers)     (docs)       (domain)      (design)    (spec)   (scripts+skills)
```

### Brownfield (approach = brownfield)

```
Bootstrap  →  Discovery  →  Analyst  →  Architect  →  Designer  →  Spec  →  Script
(answers)     (codebase      (docs)       (domain)      (design)    (spec)   (scripts)
               analysis)
```

When `approach` is `brownfield`, the Discovery agent extracts capabilities from the existing codebase using a 7-step pipeline before handing off to the Analyst.

### ADLC Extension (type = agent or ai-system)

Appends to either pipeline:

```
... →  Evaluator  →  Script  →  Ops
       (eval+pov)    (scripts)   (monitoring+governance)
```

Each agent uses a **handoff button** to pass control to the next agent when its phase is complete.

## Agents

| Agent | File | Responsibility |
|-------|------|----------------|
| Bootstrap | `bootstrap.agent.md` | Collect project answers (idea → complexity, + constraints/kpis for ADLC). Routes to Discovery (brownfield) or Analyst (greenfield). |
| Analyst | `analyst.agent.md` | Generate PRD, capability map, + KPIs and human-agent map (ADLC) |
| Architect | `architect.agent.md` | Generate domain model, RBAC, workflows, + agent pattern and cost model (ADLC) |
| Designer | `designer.agent.md` | Generate design overview, IA, user flows |
| Spec | `spec.agent.md` | Generate API, events, permissions, state machines |
| Evaluator | `evaluator.agent.md` | Generate eval framework and PoV plan (ADLC only) |
| Script | `script.agent.md` | Generate dev skill stubs and operational scripts |
| Discovery | `discovery.agent.md` | Extract capabilities from existing codebase using 7-step pipeline (brownfield only) |
| Ops | `ops.agent.md` | Generate monitoring spec and governance doc (ADLC only) |

## Skills

Skills in `.github/skills/` are invocable prompts used by agents and directly via `/skill-name` in chat.

| Skill | Triggered By |
|-------|-------------|
| `bootstrap-ask` | Bootstrap agent |
| `bootstrap-next` | Bootstrap agent |
| `workflow-read` | All agents (internal) |
| `workflow-update` | All agents (internal) |
| `generate-prd` | Analyst agent |
| `generate-capabilities` | Analyst agent |
| `generate-kpis` | Analyst agent (ADLC) |
| `generate-human-agent-map` | Analyst agent (ADLC) |
| `generate-domain` | Architect agent |
| `generate-rbac` | Architect agent |
| `generate-workflows` | Architect agent |
| `generate-agent-pattern` | Architect agent (ADLC) |
| `generate-cost-model` | Architect agent (ADLC) |
| `generate-design-workflow` | Designer agent |
| `generate-ia` | Designer agent |
| `generate-flows` | Designer agent |
| `generate-spec` | Spec agent |
| `generate-eval-framework` | Evaluator agent (ADLC) |
| `generate-pov-plan` | Evaluator agent (ADLC) |
| `generate-skills` | Script agent |
| `generate-scripts` | Script agent |
| `discover-candidates` | Discovery agent (brownfield) |
| `analyze-candidates` | Discovery agent (brownfield) |
| `verify-coverage` | Discovery agent (brownfield) |
| `lock-l1` | Discovery agent (brownfield) |
| `define-l2` | Discovery agent (brownfield) |
| `generate-discovery-domain` | Discovery agent (brownfield) |
| `compare-blueprint` | Discovery agent (brownfield) |
| `generate-monitoring-spec` | Ops agent (ADLC) |
| `generate-governance` | Ops agent (ADLC) |

## Workflow State

State is stored in:
- `.project/state/workflow.json` — current step and status
- `.project/state/answers.json` — all collected answers
- `project.json` — project metadata (includes `approach`, `adlc` flag, and `autonomy_level`)

## Project Types

Valid project types (set during `project_info` step):

| Type | Description |
|------|-------------|
| `web-app` | Traditional UI-driven application |
| `mobile` | Native or hybrid mobile application |
| `api` | Headless API service or backend |
| `cli` | Command-line tool |
| `agent` | Single LLM-driven agent with tool use |
| `ai-system` | Multi-agent or LLM-core product |

When type is `agent` or `ai-system`, the ADLC extended workflow activates automatically.

## Project Approach

| Approach | Description |
|----------|-------------|
| `greenfield` | Building from scratch — user provides idea, features, tech stack |
| `brownfield` | Modernizing existing code — 7-step capability extraction pipeline analyzes the codebase first |

Approach is set during `project_info` step. When `brownfield`, the Discovery agent runs before generation.

## Prompt Files (Slash Commands)

Type `/` in chat to invoke these directly:

| Command | File | Purpose |
|---------|------|---------|
| `/bootstrap` | `prompts/bootstrap.prompt.md` | Start or resume the workflow |
| `/status` | `prompts/status.prompt.md` | Show current step, answers, and generated files |
| `/adlc-status` | `prompts/adlc-status.prompt.md` | Show ADLC-specific output status |
| `/pov` | `prompts/pov.prompt.md` | Print PoV plan and go/no-go thresholds |
| `/review-spec` | `prompts/review-spec.prompt.md` | Validate consistency across spec files |
| `/review-agent` | `prompts/review-agent.prompt.md` | Cross-check ADLC document consistency |
| `/discovery-status` | `prompts/discovery-status.prompt.md` | Show brownfield discovery pipeline progress |
| `/reset` | `prompts/reset.prompt.md` | Jump workflow to a specific step |
| `/stitch` | `prompts/stitch.prompt.md` | Generate or regenerate UI screens via Google Stitch |

## Hooks

`PostToolUse` hooks run automatically after agent file edits:

| Agent | Hook | Purpose |
|-------|------|---------|
| Bootstrap | `validate-state.sh` | Validate workflow.json and answers.json after every edit |
| Script | `validate-state.sh` | Validate state files after script generation |

Hooks require `chat.useCustomAgentHooks: true` in VS Code settings.

## Output Structure

```
docs/analysis/    prd.md, capabilities.md, kpis.md*, human-agent-map.md*
docs/discovery/   candidates.md**, analysis.md**, coverage.md**, l1-capabilities.md**,
                  l2-capabilities.md**, domain-model.md**, blueprint-comparison.md**
docs/domain/      model.md, rbac.md, workflows.md, agent-pattern.md*, cost-model.md*
docs/design/      overview.md, ia.md, flows.md, screens/*.html
docs/spec/        api.md, events.md, permissions.md, state-machines.md, eval.md*, pov-plan.md*
docs/ops/         monitoring.md*, governance.md*
docs/workflow/    bootstrap.md, brownfield.md, design.md, adlc.md*, agents.md
.github/agents/   one .agent.md per agent
.github/skills/   one SKILL.md per skill
scripts/          init.sh, next.sh, step.sh, ask.sh
```

*Files marked with `*` are generated only when ADLC is active (type = agent | ai-system).*
*Files marked with `**` are generated only when approach = brownfield.*

## ADLC Rules (active for agent and ai-system projects)

When `project.json → adlc = true`, these rules are enforced:

- Development and evaluation are inseparable. Never build first and test later.
- Every prompt change, model change, or tool addition requires a re-run of the eval suite.
- Human-agent boundaries defined in human-agent-map.md are hard constraints. Never generate code that crosses them without an explicit override from the user.
- The go/no-go thresholds in pov-plan.md are not negotiable. Do not advance to full build if PoV metrics are below threshold.
- Deployment is activation, not completion. After deploy, the agent is under active supervision — monitoring.md defines what to watch.
- Model updates from providers are not safe by default. Always run the full eval suite before adopting a new model version.

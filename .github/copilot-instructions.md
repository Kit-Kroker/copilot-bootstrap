# Copilot Instructions

This repository uses a multi-agent bootstrap workflow. Agents are defined in `.github/agents/`. Skills are defined in `.github/skills/`.

## How to Start

Open Copilot Chat, select the **Bootstrap** agent, and type:

```
idea: <your project idea>
```

The agents will guide you through the full workflow step by step.

## Agent Pipeline

```
Bootstrap  →  Analyst  →  Architect  →  Designer  →  Spec  →  Script
(answers)     (docs)       (domain)      (design)    (spec)   (scripts+skills)
```

Each agent uses a **handoff button** to pass control to the next agent when its phase is complete.

## Agents

| Agent | File | Responsibility |
|-------|------|----------------|
| Bootstrap | `bootstrap.agent.md` | Collect project answers (idea → complexity) |
| Analyst | `analyst.agent.md` | Generate PRD and capability map |
| Architect | `architect.agent.md` | Generate domain model, RBAC, workflows |
| Designer | `designer.agent.md` | Generate design overview, IA, user flows |
| Spec | `spec.agent.md` | Generate API, events, permissions, state machines |
| Script | `script.agent.md` | Generate dev skill stubs and operational scripts |

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
| `generate-domain` | Architect agent |
| `generate-rbac` | Architect agent |
| `generate-workflows` | Architect agent |
| `generate-design-workflow` | Designer agent |
| `generate-ia` | Designer agent |
| `generate-flows` | Designer agent |
| `generate-spec` | Spec agent |
| `generate-skills` | Script agent |
| `generate-scripts` | Script agent |

## Workflow State

State is stored in:
- `.project/state/workflow.json` — current step and status
- `.project/state/answers.json` — all collected answers
- `project.json` — project metadata

## Prompt Files (Slash Commands)

Type `/` in chat to invoke these directly:

| Command | File | Purpose |
|---------|------|---------|
| `/bootstrap` | `prompts/bootstrap.prompt.md` | Start or resume the workflow |
| `/status` | `prompts/status.prompt.md` | Show current step, answers, and generated files |
| `/reset` | `prompts/reset.prompt.md` | Jump workflow to a specific step |
| `/review-spec` | `prompts/review-spec.prompt.md` | Validate consistency across spec files |
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
docs/analysis/    prd.md, capabilities.md
docs/domain/      model.md, rbac.md, workflows.md
docs/design/      overview.md, ia.md, flows.md, screens/*.html
docs/spec/        api.md, events.md, permissions.md, state-machines.md
docs/workflow/    bootstrap.md, design.md, agents.md
.github/agents/   one .agent.md per agent
.github/skills/   one SKILL.md per skill
scripts/          init.sh, next.sh, step.sh, ask.sh
```

# Copilot Agents Bootstrap System Guide

This guide describes how to build a multi-agent bootstrap workflow for GitHub Copilot Agents.

The goal:

idea → questions → PRD → design → spec → scripts → dev workflow

System must work using:

* .github/skills
* copilot-instructions.md
* workflow state files
* docs/workflow
* manual state machine
* question driven bootstrap

This guide contains:

V1 — minimal bootstrap
V2 — PRD generation
V3 — design workflow
V4 — spec generator
V5 — scripts generator
V6 — full multi-agent pipeline

---

## V1 — Minimal Bootstrap System

Create folders:

.github/
.github/skills/
.project/state/
docs/workflow/

Create file:

project.json

{
"name": "",
"type": "",
"domain": "",
"stage": "bootstrap",
"workflow": "bootstrap",
"step": "idea"
}

Create:

.project/state/workflow.json

{
"workflow": "bootstrap",
"step": "idea",
"status": "in_progress"
}

Create:

.project/state/answers.json

{}

Create:

docs/workflow/bootstrap.md

steps:

1 idea
2 project_info
3 users
4 features
5 tech
6 complexity
7 prd
8 capabilities
9 domain
10 design_workflow
11 skills
12 scripts
13 done

Create:

.github/copilot-instructions.md

Follow workflow in docs/workflow/bootstrap.md

Always read:

.project/state/workflow.json
.project/state/answers.json

Use skills from .github/skills

Rules:

Only one step active
Ask questions if data missing
Save answers
Update workflow
Generate docs when ready

Create skill:

.github/skills/workflow-read/skill.json

{
"name": "workflow_read",
"description": "Read workflow",
"prompt": "prompt.md"
}

.github/skills/workflow-read/prompt.md

Read .project/state/workflow.json
Return step and status

Create skill:

.github/skills/workflow-update/skill.json

{
"name": "workflow_update",
"description": "Update workflow",
"prompt": "prompt.md"
}

prompt.md

Update .project/state/workflow.json

Create skill:

.github/skills/bootstrap-ask/skill.json

{
"name": "bootstrap_ask",
"description": "Ask questions",
"prompt": "prompt.md"
}

prompt.md

Read workflow.json
Ask questions based on step

idea:
project idea

project_info:
name
type
domain

users:
roles

features:
features list

tech:
backend
frontend

complexity:
simple
saas
enterprise

Save to answers.json

Create skill:

.github/skills/bootstrap-next/skill.json

{
"name": "bootstrap_next",
"description": "Next step",
"prompt": "prompt.md"
}

prompt.md

Move to next step in bootstrap.md
Update workflow.json

V1 DONE

---

## V2 — PRD generator

Create:

docs/analysis/

Create skill:

.github/skills/generate-prd/skill.json

{
"name": "generate_prd",
"description": "Create PRD",
"prompt": "prompt.md"
}

prompt.md

Read answers.json

Generate:

docs/analysis/prd.md

Include:

goal
users
features
scope
non goals
constraints

Add step to bootstrap.md

7 prd

---

## V3 — Design workflow generator

Create:

docs/design/
docs/workflow/design.md

Create skill:

generate-design-workflow

prompt.md

Create design workflow

steps:

capabilities
domain
rbac
workflow
integration
metrics
ia
flows
wireframes
ux
design-system
hi-fi
spec

Add step:

design_workflow

---

## V4 — Spec generator

Create:

docs/spec/

Skill:

generate-spec

prompt.md

Create:

api.md
events.md
permissions.md
state-machines.md

Add step:

spec

---

## V5 — Scripts generator

Create:

scripts/

Skill:

generate-scripts

Create:

init.sh
next.sh
step.sh
ask.sh

Add step:

scripts

---

## V6 — Multi agent mode

Use skill groups as agents

bootstrap agent:

bootstrap-ask
bootstrap-next
workflow-read
workflow-update

analyst agent:

generate-prd
generate-capabilities

architect agent:

generate-domain
generate-rbac
generate-workflows

designer agent:

generate-design-workflow
generate-ia
generate-flows

spec agent:

generate-spec

script agent:

generate-scripts

dev agent:

code generation

Add to copilot-instructions.md

Follow workflow

Use correct skills

Do not skip steps

Always read workflow.json

Always update workflow.json

---

## Usage

Open Copilot Chat

Type:

idea: helpdesk system

Agent should ask questions

After answers:

PRD generated

Design workflow generated

Spec generated

Scripts generated

Workflow done

End of guide

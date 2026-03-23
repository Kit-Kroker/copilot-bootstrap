---
name: generate-agent-pattern
description: Define the agent architecture pattern, tool inventory, orchestration framework, and context/memory design. Use this when the workflow step is "agent_pattern" (ADLC). Reads capabilities, answers, and constraints.
---

# Skill Instructions

Read:
- `.project/state/answers.json` (specifically `features`, `autonomy_level`, `constraints`, `tech`)
- `docs/analysis/capabilities.md`
- `docs/analysis/human-agent-map.md`

Generate `docs/domain/agent-pattern.md` using this structure:

```markdown
# Agent Architecture Pattern

## Recommended Pattern

**Pattern:** {ReAct | Plan-and-Execute | Multi-agent}

**Justification:**
{Why this pattern fits the task complexity and autonomy level. Reference specific features and constraints.}

### Pattern Descriptions
- **ReAct** — for single-agent reasoning + tool use in a loop. Best for simple, reactive agents.
- **Plan-and-Execute** — for tasks requiring multi-step planning before acting. Best for assistive agents with complex workflows.
- **Multi-agent** — for parallel subtasks or specialised sub-agents. Best for autonomous systems with diverse capabilities.

## Tool Inventory

| Tool Name | Purpose | Read-Only / Mutates | Human Approval Required | Source |
|-----------|---------|---------------------|------------------------|--------|
| {tool} | {what it does} | read-only / mutates | yes / no | {API / database / service} |

## Orchestration Framework

**Recommended:** {LangChain / LangGraph / CrewAI / AutoGen / Claude Agent SDK / custom}

**Justification:**
{Why this framework suits the chosen pattern, tech stack, and complexity.}

## Context & Memory Design

### Static Context (System Prompt)
- {What goes in the system prompt — role definition, rules, constraints}
- Estimated size: {token count}

### Dynamic Context (Retrieved per request)
- {What is retrieved via RAG, database lookup, or API call}
- Retrieval method: {vector search / SQL / API}
- Estimated size: {token count}

### Conversation Memory (Per session)
- {What is carried across turns within a session}
- Storage: {in-memory / database / cache}
- Retention policy: {how long, when to summarise}

### Ephemeral Context (Per request)
- {What is used only for the current request and discarded}
- Examples: {tool call results, intermediate reasoning}

## Model Selection

| Component | Model | Reasoning |
|-----------|-------|-----------|
| Primary reasoning | {model} | {why} |
| Classification / routing | {model, if different} | {cheaper, faster} |
| Evaluation / judge | {model, if applicable} | {different perspective} |
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `cost_model`, `status` to `in_progress`
- Tell the user what was generated and what comes next

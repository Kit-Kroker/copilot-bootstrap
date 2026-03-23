---
name: generate-human-agent-map
description: Generate a human vs agent responsibility matrix. Maps every task and decision to agent-can-do, human-must-do, or approval-required with risk levels. Use this when the workflow step is "human_agent_map" (ADLC).
---

# Skill Instructions

Read:
- `.project/state/answers.json` (specifically `idea`, `users`, `features`, `constraints`, `autonomy_level`)
- `docs/analysis/prd.md`

Generate `docs/analysis/human-agent-map.md` using this structure:

```markdown
# Human–Agent Responsibility Map

## Autonomy Level

**Configured level:** {autonomy_level from answers.json}
- `reactive` — responds to requests, no background action
- `assistive` — takes actions on user request within a defined scope
- `autonomous` — initiates tasks, makes decisions, acts without per-request approval

## Responsibility Matrix

| Task / Decision | Agent Can Do | Human Must Do | Approval Required | Risk Level |
|----------------|-------------|---------------|-------------------|------------|
| {task from features} | {yes/no + detail} | {yes/no + detail} | {yes/no} | low / medium / high / critical |

### Coverage Requirements

This table must cover at minimum:
- Every feature listed in answers.json `features`
- Every failure mode described in `prd.md`
- Data access decisions (read vs write vs delete)
- Any action that modifies external systems (email, database writes, API calls)
- Escalation and override scenarios

## Hard Boundaries

Actions the agent must NEVER take without explicit human approval (from constraints):

{List from answers.json → constraints → never_without_approval}

## Escalation Rules

| Condition | Escalation Action | Who Is Notified |
|-----------|------------------|-----------------|
| {trigger} | {what happens} | {role} |

## Risk Assessment

| Risk Level | Count | Examples |
|------------|-------|---------|
| Critical | {n} | {list} |
| High | {n} | {list} |
| Medium | {n} | {list} |
| Low | {n} | {list} |
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `agent_pattern`, `status` to `in_progress`
- Tell the user what was generated and what comes next

## Rules

- Derive tasks from features and PRD — do not invent tasks
- When `autonomy_level` is `reactive`, most tasks should require human initiation
- When `autonomy_level` is `autonomous`, explicitly call out which autonomous actions carry risk
- Every "critical" risk item must have an escalation rule

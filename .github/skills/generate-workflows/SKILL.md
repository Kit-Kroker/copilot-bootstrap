---
name: generate-workflows
description: Generate core business workflows and state transitions for the domain. Use this when the design workflow step is "workflow". Requires the domain model and RBAC to be defined.
argument-hint: "[workflow name to generate, or leave blank for all core workflows]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`
- `docs/domain/model.md`
- `docs/domain/rbac.md` (if present)

Generate `docs/domain/workflows.md` using this structure:

```markdown
# Business Workflows

## Workflow Index

| Workflow | Actor | Trigger | Outcome |
|----------|-------|---------|---------|
| {name} | {role} | {event or action} | {end state} |

---

## {Workflow Name}

**Actor:** {role who initiates}
**Trigger:** {what starts this workflow}
**Preconditions:** {what must be true before it starts}
**Outcome:** {what is true when it completes successfully}

### Steps

| # | Actor | Action | System Response |
|---|-------|--------|----------------|
| 1 | {actor} | {action taken} | {what the system does} |
| 2 | ... | ... | ... |

### State Transitions

{EntityName}: `{from_state}` → `{to_state}` on `{trigger}`

### Exceptions

| Condition | Handling |
|-----------|----------|
| {what goes wrong} | {how it is handled} |

### Capability Traceability

- Requires: {capability names from capabilities.md}

---

{Repeat for each core workflow}
```

Cover at minimum one workflow per core feature in answers.json.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `integration`, `status` to `in_progress`

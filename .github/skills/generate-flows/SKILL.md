---
name: generate-flows
description: Generate user flows and interaction paths for all core features and user roles. Use this when the design workflow step is "flows". Requires the IA to be defined first.
argument-hint: "[feature or role to focus on, or leave blank for all]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`
- `docs/design/ia.md`

Generate `docs/design/flows.md` using this structure:

```markdown
# User Flows

## Flow Index

| Flow | Role | Entry Point | Goal |
|------|------|-------------|------|
| {flow name} | {role} | {screen or trigger} | {what user achieves} |

---

## {Flow Name}

**Role:** {role}
**Entry:** {screen or event that starts this flow}
**Goal:** {what the user is trying to accomplish}

### Happy Path

1. {Step 1}
2. {Step 2}
3. ...
n. {Completion state}

### Alternate Paths

- {Condition}: {alternate step sequence}

### Failure Paths

- {Error condition}: {what happens, how user recovers}

### UX Risks

- {Friction point or risk}

---

{Repeat for each core flow}
```

Cover at minimum:
- One flow per core feature listed in answers.json
- One flow per user role listed in answers.json

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `wireframes`, `status` to `in_progress`

---
name: generate-capabilities
description: Generate a capability map from the PRD and collected answers. Use this when the workflow step is "capabilities". Produces docs/analysis/capabilities.md with core capabilities, dependencies, and feature traceability.
argument-hint: "[capability area to focus on, or leave blank for full map]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`

Generate `docs/analysis/capabilities.md` using this structure:

```markdown
# Capability Map

## Core Capabilities

| Capability | Description | Priority |
|------------|-------------|----------|
| {name} | {what the system can do} | must-have / should-have / nice-to-have |

## Supporting Capabilities

| Capability | Description | Depends On |
|------------|-------------|------------|
| {name} | {enables or supports a core capability} | {core capability} |

## Capability Dependencies

```
{CapabilityA}
  └─► {CapabilityB} (required before A can function)
        └─► {CapabilityC}
```

## Feature → Capability Mapping

| Feature (from PRD) | Capabilities Required |
|--------------------|-----------------------|
| {feature} | {capability1}, {capability2} |

## Out of Scope Capabilities

| Capability | Reason Excluded |
|------------|----------------|
| {name} | {why it is not included in this version} |
```

Keep capability names stable. They will be reused across domain, RBAC, and spec documents.
Derive capabilities directly from the features and constraints in the PRD.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `domain`, `status` to `in_progress`

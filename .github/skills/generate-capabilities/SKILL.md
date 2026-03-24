---
name: generate-capabilities
description: Generate a capability map from the PRD and collected answers. Use this when the workflow step is "capabilities". Produces docs/analysis/capabilities.md with core capabilities, dependencies, and feature traceability.
argument-hint: "[capability area to focus on, or leave blank for full map]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`
- `project.json` (check `approach` field)

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

### Brownfield Mode (when approach = brownfield)

When `project.json → approach = "brownfield"`, also read:
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required
- `docs/discovery/coverage.md`

**Changes to capability map:**

1. **Core Capabilities** — Derive from discovered L1 capabilities (not invented from PRD features). Use the same capability names and IDs (BC-001, BC-002, etc.) from `l1-capabilities.md`.

2. **Add Code Traceability column** to Core Capabilities table:

| Capability | Description | Priority | Files | LOC | Code Packages |
|------------|-------------|----------|-------|-----|--------------|
| BC-001: {name} | {description} | must-have | {count} | {count} | {paths} |

3. **Add Migration Priority column** based on coupling and complexity from discovery analysis:

| Capability | Migration Priority | Coupling | Complexity | Rationale |
|------------|-------------------|----------|------------|-----------|
| BC-001: {name} | HIGH / MEDIUM / LOW | {score} | {SIMPLE/MODERATE/COMPLEX} | {why} |

4. **Feature → Capability Mapping** becomes **L2 → Capability Mapping**, showing how L2 sub-capabilities map to L1 capabilities (from discovery, not PRD features).

5. **Add Discovery Provenance section:**

```markdown
## Discovery Provenance

This capability map is derived from codebase analysis, not user-supplied features.
- Source: docs/discovery/l1-capabilities.md, docs/discovery/l2-capabilities.md
- Code coverage: {percentage}%
- Confidence distribution: {HIGH count}, {MEDIUM count}, {LOW count}
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `domain`, `status` to `in_progress`

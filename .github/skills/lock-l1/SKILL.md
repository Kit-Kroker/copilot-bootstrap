---
name: lock-l1
description: Finalize the Level 1 capability list from confirmed, split, and merged candidates. Assigns stable IDs (BC-001, BC-002, etc.). Use this when workflow step is "lock_l1" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/l1-capabilities.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/discovery/analysis.md` ← required
- `docs/discovery/coverage.md` ← required
- `docs/discovery/candidates.md` (for reference)

## L1 Finalization Process

### A4.1 — Build Final L1 List

Starting from the analysis.md actions:

1. **Confirmed candidates** → include as-is
2. **Split candidates** → include each split part as a separate L1
3. **Merged candidates** → absorbed into their target capability (do not list separately)
4. **New capabilities from coverage** → include any new capabilities discovered during orphan resolution
5. **De-scoped and flagged** → excluded from L1 list (documented for reference)

### Assign Stable IDs

Each L1 capability gets a stable ID: `BC-001`, `BC-002`, etc.

IDs are assigned in logical domain order (not discovery order):
- Group related capabilities together
- Core capabilities first, supporting capabilities after

## Output

Generate `docs/discovery/l1-capabilities.md`:

```markdown
# L1 Capabilities (Locked)

## Summary

- **Total L1 capabilities**: {count}
- **From confirmed candidates**: {count}
- **From split candidates**: {count}
- **From coverage discovery**: {count}
- **Merged into others**: {count}
- **De-scoped**: {count}

## L1 Capability List

| ID | Capability Name | Origin | Confidence | Files | LOC | Description |
|----|----------------|--------|------------|-------|-----|-------------|
| BC-001 | {name} | confirmed | HIGH | {count} | {count} | {1-line description} |
| BC-002 | {name} | split from {original} | HIGH | {count} | {count} | {description} |

## Capability Details

### BC-001: {Capability Name}

**Description**: {2-3 sentence description of what this capability does}
**Origin**: {confirmed / split from X / discovered in coverage}
**Confidence**: {HIGH/MEDIUM}
**Code Footprint**: {N} files, {N} lines of code
**Key Packages**: {list of package/module paths}
**Entry Points**: {list of key controllers/handlers/consumers}
**Database Tables**: {list of owned tables, or "N/A"}
**Evidence Summary**: {brief evidence from signal sources}

{Repeat for each L1}

## Excluded Items

### De-Scoped (Not Business Capabilities)

| Original Candidate | Classification | Rationale |
|--------------------|---------------|-----------|
| {name} | {infrastructure/cross-cutting/delivery channel} | {reason} |

### Flagged (Pending Review)

| Original Candidate | Question |
|--------------------|---------|
| {name} | {question for architect/domain expert} |

## Merge Trace

| Merged Candidate | Absorbed Into | Rationale |
|-----------------|--------------|-----------|
| {name} | BC-{NNN}: {target} | {reason} |
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `define_l2`, `status` to `in_progress`
- Tell the user: "{N} L1 capabilities locked. Next: define L2 sub-capabilities for each."

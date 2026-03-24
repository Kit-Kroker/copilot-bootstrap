---
name: verify-coverage
description: Map all source files to discovered capabilities and verify >90% coverage. Identify orphan code and recommend resolution. Use this when workflow step is "verify_coverage" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/coverage.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/discovery/analysis.md` ← required
- `docs/discovery/candidates.md` ← required
- `.project/state/answers.json` (specifically `codebase_setup`)
- The existing codebase at the configured path

## Coverage Check Process

### A3.1 — Map Files to Capabilities

For each confirmed capability (from analysis.md):
1. List all source files that belong to it (by package, module, or explicit reference)
2. Count files and lines of code
3. Note any files shared between multiple capabilities

For split capabilities, map files to the new post-split capability names.

### A3.2 — Orphan Resolution

Identify all significant source files NOT mapped to any capability:

For each orphan file/directory:
- **Assign to existing capability** — if it's clearly part of a capability but was missed
- **Create new capability** — if it represents undiscovered business functionality
- **Mark as infrastructure** — if it's cross-cutting (logging, config, middleware, build scripts)
- **Mark as dead code** — if it appears unused or is a leftover artifact

## Output

Generate `docs/discovery/coverage.md`:

```markdown
# Coverage Verification

## Summary

- **Total source files**: {count}
- **Total lines of code**: {count}
- **Files mapped to capabilities**: {count} ({percentage}%)
- **Lines mapped to capabilities**: {count} ({percentage}%)
- **Orphan files**: {count}
- **Coverage target**: >90%
- **Coverage status**: {MET / NOT MET}

## Capability Coverage Map

| Capability | Files | Lines of Code | % of Codebase | Key Packages |
|-----------|-------|--------------|---------------|-------------|
| {name} | {count} | {count} | {%} | {package paths} |

## Shared Files

Files that serve multiple capabilities (potential coupling indicators):

| File | Capabilities | Notes |
|------|-------------|-------|
| {path} | {cap1}, {cap2} | {why it's shared} |

## Orphan Resolution

### Assigned to Existing Capability

| File/Directory | Assigned To | Rationale |
|---------------|-------------|-----------|
| {path} | {capability} | {why} |

### New Capabilities Discovered

| File/Directory | Proposed Capability | Evidence |
|---------------|-------------------|----------|
| {path} | {name} | {why it's a business capability} |

### Infrastructure (Not Capabilities)

| File/Directory | Classification | Notes |
|---------------|---------------|-------|
| {path} | {logging/config/middleware/build/test} | {description} |

### Dead Code

| File/Directory | Evidence | Recommendation |
|---------------|----------|---------------|
| {path} | {why it appears dead} | Remove / Investigate |

## Coverage Gap Analysis

{If coverage < 90%, explain what's missing and recommend next steps}
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `lock_l1`, `status` to `in_progress`
- Tell the user: "Coverage: {percentage}%. {orphan_count} orphan files resolved. Next: lock L1 capability list."

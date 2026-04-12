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

### File Significance Rules

Count and map these as significant source files:
- All files containing business logic (services, controllers, handlers, models, entities, repositories)
- All configuration files that define business behavior (routing, feature flags, business rules)
- All database migrations and schema definitions

Exclude from coverage counting (but note their existence):
- Unit and integration test files
- Build scripts and CI/CD configuration
- IDE configuration and editor settings
- Documentation files (README, CHANGELOG)
- Static assets (images, fonts, CSS unless it's a frontend capability)
- Generated code (auto-generated clients, compiled output)
- Dependency lock files

When reporting coverage percentage, report both:
- **Business file coverage**: significant files mapped / total significant files
- **LOC coverage**: significant LOC mapped / total significant LOC

The >90% target applies to business file coverage, not total file count.

### A3.2 — Orphan Resolution

Identify all significant source files NOT mapped to any capability:

For each orphan file/directory:
- **Assign to existing capability** — if it's clearly part of a capability but was missed
- **Create new capability** — if it represents undiscovered business functionality
- **Mark as infrastructure** — if it's cross-cutting (logging, config, middleware, build scripts)
- **Mark as dead code** — if it appears unused or is a leftover artifact

### Coupling Analysis from Shared Files

Shared files are not just a coverage accounting detail — they are the strongest signal for coupling between capabilities. For each shared file:

1. **Determine the sharing pattern**:
   - **Shared utility**: Generic helper used by many capabilities (e.g., date formatting, validation helpers). Not a coupling concern.
   - **Shared entity**: A domain entity read or written by multiple capabilities. This is coupling — document which capability OWNS the entity and which READS it.
   - **Shared service**: A service class called by multiple capabilities. This is coupling — it may indicate a missing capability or a cross-cutting concern.
   - **Circular dependency**: Capability A calls Capability B's internals, and B calls A's internals. This is a boundary problem — flag for the L1 locking step.

2. **Record coupling strength**:
   - STRONG: Shared entity with write access from multiple capabilities
   - MODERATE: Shared service or shared entity with read-only access
   - WEAK: Shared utility with no domain semantics

This coupling data feeds directly into the dependency graph in the domain model and into migration complexity scoring in L2.

### Dead Code Identification

Mark as dead code if ANY of these apply:
- No references from other source files (no imports, no calls, no inheritance)
- Last modified date is >2 years ago AND no other file references it
- Sits in a package named `deprecated`, `old`, `legacy`, `v1` (when v2+ exists)
- Contains commented-out code blocks that constitute >50% of the file
- Is a copy/clone of another file with minor differences (likely a failed refactor)

Mark as "Investigate" (not dead code) if:
- It's referenced only through reflection, dependency injection, or configuration (common in Java/C# — the code IS used, just not through static references)
- It's a plugin or extension loaded dynamically
- It's a scheduled job that runs infrequently

When in doubt, mark as "Investigate" — removing live code is worse than keeping dead code.

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

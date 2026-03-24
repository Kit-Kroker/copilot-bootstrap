---
name: define-l2
description: Define Level 2 sub-capabilities for each L1 capability. Maps each L2 to code locations, entities, and operations. L2 = executable units of work. Use this when workflow step is "define_l2" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/l2-capabilities.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/analysis.md` (for detailed code references)
- `.project/state/answers.json` (specifically `codebase_setup`)
- The existing codebase at the configured path (for deep analysis per L1)

## L2 Extraction Process

For each L1 capability:

### A5.1 — Scope L2 Candidates

Identify distinct business operations within the L1:
- What separate workflows or processes exist?
- What distinct entity lifecycle stages are managed?
- What external integrations are handled?

Each L2 should be an executable unit of work — something a team can own, migrate, extend, or replace independently.

### A5.2 — Refine L2 Analysis

For each L2 candidate:
1. Map to specific code locations (files, classes, functions)
2. Identify key entities (with ownership: OWNS, MANAGES, READS, CREATES)
3. List key operations (with API endpoints, job triggers, message topics)
4. Identify external dependencies (APIs, services, third-party providers)

### A5.3 — Lock L2 List

Finalize L2 sub-capabilities. Each L2 gets an ID: `BC-{L1}-{NN}` (e.g. BC-001-01, BC-001-02).

## Output

Generate `docs/discovery/l2-capabilities.md`:

```markdown
# L2 Sub-Capabilities

## Summary

- **Total L1 capabilities**: {count}
- **Total L2 sub-capabilities**: {count}
- **Average L2 per L1**: {avg}

## Capability Hierarchy

{L1 Name}
├── {L2 Name}
├── {L2 Name}
└── {L2 Name}

{Repeat for each L1}

## L2 Details

### BC-001: {L1 Capability Name}

#### BC-001-01: {L2 Name}

**Description**: {what this sub-capability does}

**Key Operations**:
- {operation description} ({HTTP method} {endpoint} or {trigger type})
- {operation description}

**Code Location**:
- {package/module path}
- {specific files if notable}

**Key Entities**:
- {EntityName} ({OWNS/MANAGES/READS/CREATES} — {table or source})
- {EntityName} ({relationship})

**External Dependencies**:
- {service/API name} ({purpose})

#### BC-001-02: {L2 Name}

{Same structure as above}

---

### BC-002: {L1 Capability Name}

{Same structure}

## Cross-Capability Dependencies

| Source L2 | Depends On | Dependency Type | Notes |
|-----------|-----------|----------------|-------|
| BC-001-01 | BC-002-01 | Creates entity used by | {detail} |
| BC-003-02 | BC-001-01 | Calls API | {detail} |

## Migration Complexity Indicators

| L1 Capability | L2 Count | Total Files | External Deps | Coupling Score | Migration Complexity |
|--------------|----------|-------------|---------------|---------------|---------------------|
| BC-001: {name} | {count} | {files} | {ext deps} | {LOW/MEDIUM/HIGH} | {SIMPLE/MODERATE/COMPLEX} |
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `discovery_domain`, `status` to `in_progress`
- Tell the user: "{N} L2 sub-capabilities defined across {M} L1 capabilities. Next: generate consolidated domain model."

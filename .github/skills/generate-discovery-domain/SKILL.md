---
name: generate-discovery-domain
description: Generate a consolidated domain model from discovered L1/L2 capabilities with full code traceability. Use this when workflow step is "discovery_domain" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/domain-model.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required
- `docs/discovery/coverage.md` (for file mapping)
- `.project/state/answers.json` (specifically `codebase_setup`)

## Domain Model Generation

Build a single, traceable representation of what the system actually does. Both L1 capabilities and L2 operations, with each element backed by code-level evidence.

The model answers not just what exists, but where it lives and how it is implemented.

## Output

Generate `docs/discovery/domain-model.md`:

```markdown
# Domain Model (Code-Derived)

## System Overview

- **System**: {project name}
- **Domain**: {domain from answers}
- **Architecture**: {monolith/modular-monolith/microservices}
- **Language**: {primary language}
- **Total L1 Capabilities**: {count}
- **Total L2 Operations**: {count}
- **Total Entities**: {count}

## Capability Hierarchy

{System Name}
├── BC-001: {Capability Name}
│   ├── BC-001-01: {L2 Name}
│   └── BC-001-02: {L2 Name}
├── BC-002: {Capability Name}
│   └── ...
└── ...

## Entity Catalog

| Entity | Owning Capability | Table/Source | Key Attributes | Relationships |
|--------|------------------|-------------|----------------|--------------|
| {name} | BC-{NNN}: {cap} | {table name} | {key fields} | {FK relationships} |

## Entity Ownership Matrix

| Entity | BC-001 | BC-002 | BC-003 | ... |
|--------|--------|--------|--------|-----|
| {name} | OWNS | READS | — | ... |

Legend: OWNS = source of truth, CREATES = creates instances, MANAGES = full CRUD, READS = read-only consumer

## Capability Detail

### BC-001: {Capability Name}

**Description**: {2-3 sentences}
**Code Footprint**: {N} files, {N} LOC across {packages}
**Owned Entities**: {list with tables}

#### L2 Operations

**BC-001-01: {L2 Name}**
- Code: {package/module path}
- Entities: {OWNS EntityA, CREATES EntityB}
- Operations:
  - {operation} ({endpoint or trigger})
  - {operation}
- External: {third-party dependencies}

**BC-001-02: {L2 Name}**
- {same structure}

#### Cross-Capability Dependencies
- → BC-002: {dependency description}
- → BC-003: {dependency description}

---

{Repeat for each L1 capability}

## Dependency Graph

| Source | Target | Dependency Type | Strength |
|--------|--------|----------------|----------|
| BC-001 | BC-002 | Entity creation | Strong — BC-001 creates entities consumed by BC-002 |
| BC-003 | BC-001 | API call | Weak — optional enrichment |

## Bounded Context Candidates

Based on coupling analysis, these capability clusters could form bounded contexts:

| Context Name | Capabilities | Rationale |
|-------------|-------------|-----------|
| {name} | BC-001, BC-002 | {low coupling between groups, high cohesion within} |

## Infrastructure & Cross-Cutting Concerns

| Concern | Implementation | Used By |
|---------|---------------|---------|
| Authentication | {package/approach} | All capabilities |
| Logging | {package/approach} | All capabilities |
| {other} | {detail} | {which capabilities} |
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `blueprint_comparison`, `status` to `in_progress`
- Tell the user: "Domain model generated with {N} capabilities, {M} entities, {K} cross-capability dependencies. Next: industry blueprint comparison."

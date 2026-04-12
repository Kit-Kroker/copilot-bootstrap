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

The model answers not just what exists, but **where it lives and how it is implemented**. Every capability, operation, and boundary must be traceable to specific files, entry points, and entities in the codebase. A capability map without traceability tells you "the system handles Payments." Useful for slides. With traceability, you know Payments spans N files across M packages, owns K entities, exposes N endpoints, and depends on Account Management through a specific service. That is a real boundary — something you can hand to a team and say "this is your migration slice."

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
- **Total Source Files (business)**: {count}
- **Total LOC (business)**: {count}
- **Coverage**: {percentage from coverage.md}
- **Largest Capability**: BC-{NNN} ({name}) — {files} files, {loc} LOC
- **Most Connected Capability**: BC-{NNN} ({name}) — {dep_count} dependencies
- **External Integrations**: {count} ({list names})

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

Use this format for each L1 capability entry. It must be self-contained — a team handed a single entry should know exactly what to own, where to find it, and what it depends on.

```
BC-{NNN}: {Capability Name}                              {L2 count} L2s
─────────────────────────────────────────────────────────────────────────
{2-3 sentence description of what this capability orchestrates.
 Name external integrations if present.}

L2 Operations:

  BC-{NNN}-01: {L2 Name}
    Code:     {package/module path}
    Entities: {OWNS EntityA, CREATES EntityB, MANAGES EntityC}
    Operations:
      - {operation description} ({HTTP method} {endpoint} or {trigger type})
      - {operation description}
    External: {third-party service} ({purpose}) — or omit if none

  BC-{NNN}-02: {L2 Name}
    Code:     {package/module path}
    Entities: {OWNS EntityD, MANAGES EntityE}
    Operations:
      - {operation description}
    External: {third-party service} ({purpose}) — or omit if none

Cross-Capability Dependencies:
  → BC-{NNN} {Capability Name} ({what is shared or created})
  → BC-{NNN} {Capability Name} ({what is shared or created})
```

Entity ownership notation:
- **OWNS** — source of truth, single writer
- **CREATES** — creates new instances; another capability owns the record
- **MANAGES** — full CRUD via an external API (no local table)
- **TRACKS** — reads and monitors state owned elsewhere
- **READS** — read-only consumer

Omit `Cross-Capability Dependencies` block if there are none.

---

{Repeat the full entry block for each L1 capability}

## Dependency Graph

| Source | Target | Dependency Type | Strength |
|--------|--------|----------------|----------|
| BC-001 | BC-002 | Entity creation | Strong — BC-001 creates entities consumed by BC-002 |
| BC-003 | BC-001 | API call | Weak — optional enrichment |

## Key Interaction Patterns

Describe the 3-5 most significant interaction patterns between capabilities. These are the workflows that span multiple capabilities and represent the system's core business processes.

### {Pattern Name} (e.g., "Customer Acquisition Flow")

**Trigger**: {what starts this flow}
**Capabilities involved**: BC-001 → BC-002 → BC-003
**Flow**:
1. {BC-001 action} — produces {entity/event}
2. {BC-002 action} — consumes {entity/event}, produces {entity/event}
3. {BC-003 action} — completes the flow

**Coupling assessment**: {how tightly coupled is this flow — does it use events/APIs/direct DB access?}

## Bounded Context Candidates

Propose bounded context groupings based on three concrete criteria:

1. **Low inter-group coupling**: Capabilities in different contexts should have WEAK or no coupling between them (from the dependency graph and shared file analysis in coverage.md)
2. **High intra-group cohesion**: Capabilities in the same context should share entities, have STRONG coupling, or participate in the same business workflows
3. **Clear data ownership**: Each bounded context should own a distinct set of entities with minimal cross-context write access

| Context Name | Capabilities | Shared Entities | Inter-Context Dependencies | Rationale |
|-------------|-------------|-----------------|---------------------------|-----------|
| {name} | BC-001, BC-002 | Customer, Person | → {other context}: reads Account | {cohesion + coupling evidence} |

For each proposed boundary between contexts, note:
- What data crosses the boundary (entity names)
- What direction (which context is the source of truth)
- Whether the current code enforces this boundary (API call) or violates it (direct DB access)

## Infrastructure & Cross-Cutting Concerns

| Concern | Implementation | Package/Location | Used By | Notes |
|---------|---------------|-----------------|---------|-------|
| Authentication | {mechanism — JWT/OAuth/session} | {package path} | All capabilities | {implementation quality notes} |
| Authorization | {mechanism — RBAC/ABAC/custom} | {package path} | {which capabilities} | {notes on consistency} |
| Logging | {framework} | {package path} | All capabilities | {structured/unstructured, centralized/distributed} |
| Error Handling | {pattern — global handler/per-service} | {package path} | All capabilities | {notes} |
| Database Access | {ORM/raw SQL/mixed} | {package path} | {which capabilities} | {connection pooling, transaction management} |
| Messaging | {broker — Kafka/RabbitMQ/none} | {package path} | {which capabilities} | {event patterns used} |
| Caching | {mechanism — Redis/in-memory/none} | {package path} | {which capabilities} | {cache invalidation strategy} |
| External HTTP | {client library} | {package path} | {which capabilities} | {retry/circuit breaker patterns} |

These are explicitly NOT capabilities — they serve capabilities. They are documented here because migration plans need to account for them: either they move with a capability slice, or they become shared infrastructure.
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `blueprint_comparison`, `status` to `in_progress`
- Tell the user: "Domain model generated with {N} capabilities, {M} entities, {K} cross-capability dependencies. Next: industry blueprint comparison."

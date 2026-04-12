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

### L2 Granularity Rules

An L2 is correctly scoped when:

1. **A team can own it.** One team or one developer can be responsible for this L2 without needing to coordinate with other L2 owners within the same L1. If two L2s can't be worked on independently, they're either one L2 or the split is wrong.

2. **It has a clear lifecycle.** The L2 manages a distinct workflow or entity lifecycle stage — not just a single endpoint. "Create customer" alone is too small. "Customer Registration & Account Provisioning" (which includes validation, creation, provisioning, and integration triggers) is the right granularity.

3. **It maps to a business conversation.** A product owner should recognize the L2 as something they can discuss requirements for. "Database access layer for payments" is not an L2 — it's an implementation detail. "Payment Execution & Settlement" is an L2.

**Target**: 2-5 L2s per L1 capability. If you have:
- **1 L2**: The L1 is too granular, or the analysis hasn't gone deep enough
- **2-5 L2s**: Correct range for most capabilities
- **6-8 L2s**: Acceptable for large, complex capabilities
- **9+ L2s**: The L1 likely needs splitting into multiple L1s — revisit the lock-l1 decision

### A5.2 — Refine L2 Analysis

For each L2 candidate:
1. Map to specific code locations (files, classes, functions)
2. Identify key entities (with ownership: OWNS, MANAGES, READS, CREATES, TRACKS)
3. List key operations (with API endpoints, job triggers, message topics)
4. Identify external dependencies (APIs, services, third-party providers)

### Entity Ownership Determination

For each entity referenced by an L2, determine the ownership relationship by asking: "Who is the source of truth for this entity's state?"

- **OWNS**: This L2 is the single writer. It creates, updates, and deletes this entity. No other L2 writes to this entity's table. Example: Customer Onboarding OWNS the Customer entity.
- **CREATES**: This L2 creates new instances, but another capability owns the entity going forward. Example: Customer Onboarding CREATES a Person record, but Customer Profile Management OWNS it after creation.
- **MANAGES**: This L2 performs full CRUD but through an external API — there is no local database table. Example: Identity Verification MANAGES FourthlineCustomer via the Fourthline API.
- **TRACKS**: This L2 reads and monitors state changes but never writes. It may cache or project the data. Example: Transaction History TRACKS Account balances.
- **READS**: Pure read-only consumption. No caching, no projection, no state tracking. Example: Reporting READS data from multiple capabilities.

**Ownership conflicts**: If two L2s both write to the same entity, you have a boundary problem. Either:
- The entity should be split (different fields owned by different L2s)
- One L2 is the true owner and the other should go through an API/event instead of direct write
- The two L2s belong in the same L2 (they're not independent)

Document ownership conflicts explicitly — they are critical signals for migration planning.

### Migration Complexity Scoring

For each L1 capability, calculate migration complexity from these factors:

**Coupling Score** (from coverage.md shared files and cross-capability dependencies):
- LOW: 0-1 dependencies on other capabilities, no shared entities with write access
- MEDIUM: 2-3 dependencies, or shared entities with read-only access from others
- HIGH: 4+ dependencies, or shared entities with write access from multiple capabilities, or circular dependencies

**External Dependency Factor**:
- Each external integration (third-party API, payment gateway, KYC provider) adds complexity
- 0 external deps: no addition
- 1-2 external deps: +1 complexity level
- 3+ external deps: +2 complexity levels

**Migration Complexity** (composite):
- SIMPLE: LOW coupling, ≤2 L2s, 0 external deps
- MODERATE: MEDIUM coupling, 3-5 L2s, 1-2 external deps
- COMPLEX: HIGH coupling, 5+ L2s, or 3+ external deps, or circular dependencies

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

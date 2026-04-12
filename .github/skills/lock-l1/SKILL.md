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

### ID Assignment Strategy

Group capabilities by business domain, then assign sequential IDs within groups. The grouping creates natural reading order and makes the capability hierarchy intuitive.

Suggested grouping (adapt to the actual domain):

1. **Customer-facing core**: The primary business operations that external users interact with (onboarding, account management, transactions)
2. **Product domains**: Distinct product lines the system supports (deposits, lending, insurance, investments)
3. **Operational support**: Internal operations that support the core (reporting, administration, compliance)
4. **Platform services**: Capabilities that serve other capabilities (notifications, document generation, integrations)

Within each group, order by dependency: capabilities that others depend on come first. This means if BC-003 (Account Management) is a dependency for BC-007 (Payments), Account Management gets the lower number.

The ID assignment is a one-time decision. Once locked, IDs never change — even if capabilities are later reordered or regrouped. Stability of IDs is more important than perfect ordering.

### Pre-Lock Validation

Before locking the L1 list, verify:

1. **No overlapping scope.** No two L1 capabilities should own the same entity or cover the same business operation. If they do, one should be merged into the other. Check the entity lists from analysis.md.

2. **No gaps in confirmed capabilities.** Every CONFIRMED candidate from analysis.md must appear in the L1 list (or be accounted for as absorbed by a split). Count: confirmed + split outputs + coverage discoveries = total L1.

3. **Reasonable count.** For most systems:
   - 8-12 L1 capabilities: typical for a focused product
   - 12-20 L1 capabilities: typical for a platform with multiple product lines
   - 20-30 L1 capabilities: large enterprise system
   - 30+: likely over-granular — review whether some L1s should be merged

4. **No L1 without code.** Every L1 must have at least one package/module with business logic. A capability that exists only as a database table cluster or only as an API endpoint without implementation is suspicious — flag it.

5. **Flagged items documented.** All FLAG candidates from analysis.md must appear in the "Flagged (Pending Review)" section with their original question. Flagged items do not silently disappear.

### Capability Description Quality

Each L1 description should answer three questions in 2-3 sentences:

1. **What business operation does this capability perform?** (not what code it contains)
2. **Who or what triggers it?** (user action, scheduled job, event from another capability)
3. **What is the primary business outcome?** (account created, payment processed, report generated)

Bad: "Contains the customer-related services and controllers for managing customer data."
Good: "Orchestrates customer acquisition from registration through KYC verification and account activation. Triggered by new customer sign-up. Results in a verified customer with an active primary account."

The description is the first thing a team reads when they receive their migration slice. It must communicate business meaning, not code structure.

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

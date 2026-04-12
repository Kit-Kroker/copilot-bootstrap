---
name: discover-candidates
description: Extract capability candidates from an existing codebase by analyzing package structure, database schema, backend entry points, and frontend entry points. Produces 15-25 raw candidates with confidence ratings. Use this when workflow step is "seed_candidates" (brownfield).
argument-hint: "[codebase path, or leave blank to use answers.json codebase_setup.path]"
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/candidates.md` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated analysis.

Read:
- `.project/state/answers.json` (specifically `codebase_setup`: path, language, architecture, database_path, reports, has_frontend)
- The existing codebase at the configured path

## Pre-Generated External Inputs

Check `codebase_setup.reports` for externally generated analysis files.

When pre-generated inputs are present:
- **They anchor confidence upward.** A candidate corroborated by an external tool (nDepend, Structure101, IDE analyzer) AND by code signals gets HIGH confidence even if it only appears in 2 code-level sources.
- **They resolve ambiguity.** If a DBA-provided schema groups tables differently than the code packages suggest, the schema is a stronger signal for data domain boundaries — note the disagreement and prefer the schema grouping.
- **They do not replace analysis.** External inputs supplement signal extraction. Run all applicable sub-steps regardless.
- **Document usage.** In the output, record which sub-steps used pre-generated inputs and how they affected confidence ratings.

## Critical Rule — Business Operations, Not Technical Types

Before extracting signals, internalize this: a `PaymentController`, a `RecurringPaymentJob`, a `PaymentEventConsumer`, and a `MoneyTransferPage` are NOT four candidates. They are all evidence of the same "Payments" capability. Group by what the business does, not by how the code is organized.

This rule applies across ALL signal sources. A table cluster, a controller group, and a frontend route that serve the same business operation are one candidate with strong cross-source corroboration — not three separate candidates.

## Signal Extraction (6 sub-steps)

### A1.1 — Package Structure Analysis

Scan the top-level directory structure and module/package organization of the codebase.

Look for domain-suggestive names:
- **Strong signals**: `payments`, `customers`, `orders`, `lending`, `accounts`, `notifications`, `auth`
- **Ambiguous signals**: `processing`, `management`, `utils`, `common`, `shared`, `core`
- **Infrastructure (not capabilities)**: `config`, `middleware`, `migrations`, `tests`, `scripts`

For each package/module, note:
- Package name and path
- File count and estimated line count
- Whether it contains business logic or is infrastructure
- **Size flag**: If a single package exceeds 20% of the total codebase, flag it as "OVERSIZED — likely contains multiple capabilities, candidate for splitting in A2"

### A1.2 — Database Schema Analysis

*(Skip this sub-step if `codebase_setup.database_path` is empty/null and no migration files found)*

Analyze database schemas, migrations, or ORM model definitions:
- Table clusters that suggest business domains
- Foreign key relationships that reveal entity dependencies
- Stored procedures or triggers grouped by domain
- Enum types that encode business concepts

In legacy systems, the database often reveals business domains more clearly than the code.

### A1.3 — Backend Entry Point Analysis

Identify all backend entry points:
- **REST/API controllers** — group by resource/domain, not by HTTP method
- **Scheduled jobs / cron tasks** — background business operations
- **Message consumers** — event-driven operations (Kafka, RabbitMQ, SQS, etc.)
- **CLI commands** — administrative operations
- **RPC/gRPC services** — service-to-service operations

**Key rule:** Group by business operation, not by technical type. A `PaymentController`, a `RecurringPaymentJob`, and a `PaymentEventConsumer` are all evidence of the same "Payments" capability.

### A1.4 — Frontend/UI Entry Point Analysis

*(Skip this sub-step if `codebase_setup.has_frontend = false`)*

Identify frontend entry points:
- **Pages/routes** — each route maps to a user journey
- **Navigation structure** — menus, sidebars, breadcrumbs reveal capability hierarchy
- **Feature folders** — frontend module organization
- **Screen components** — major views and their purpose

### A1.5 — Merge Signals

Cross-reference signals from all sources (A1.1–A1.4):

Assign confidence ratings:
- **HIGH**: Candidate appears in 3+ signal sources (package + DB + entry points)
- **MEDIUM**: Candidate appears in 2 signal sources, or strong in 1 but ambiguous
- **LOW**: Candidate appears in only 1 source with weak evidence

Flag ambiguous candidates with the specific reason:
- "Is this a standalone capability or a feature within another domain?"
- "Is this active in the system or a leftover artifact?"
- "Is this a business capability or infrastructure/cross-cutting concern?"

### A1.6 — Common Misclassification Traps

Before formatting the candidate list, review for these patterns:

1. **Delivery channels disguised as capabilities.** A "Mobile Banking" or "Web Portal" package that spans 40%+ of the codebase is almost certainly a delivery channel, not a capability. It's how capabilities are accessed, not a capability itself. Flag as MEDIUM confidence with ambiguity reason: "Likely delivery channel, not a business capability."

2. **Infrastructure disguised as capabilities.** "Core Banking Integration", "Product Catalog" (when it's a config layer), "Customer Communications" (when it's a notification service) — these serve other capabilities, they don't represent independent business operations. Flag with reason: "Possible infrastructure/cross-cutting concern."

3. **Test harnesses and demo environments.** Any package named `demo`, `test`, `sandbox`, `mock`, or `seed` that contains business-like code. Flag with reason: "Test harness or demo environment, not production capability."

4. **Parameter variations.** "Scheduled Payments" vs "Payments", "Group Deposits" vs "Personal Deposits" — these may be the same capability with different parameters. If the code shares >70% of its logic, they're likely one capability. Flag with reason: "Possible parameter variation of {other candidate}."

### A1.7 — Format Candidate List

Generate `docs/discovery/candidates.md` using this structure:

```markdown
# Capability Candidates

## Codebase Summary

- **Path**: {codebase path}
- **Language**: {primary language}
- **Architecture**: {monolith/modular-monolith/microservices}
- **Total files scanned**: {count}
- **Signal sources used**: {list which of A1.1-A1.4 were active}
- **Signal sources skipped**: {list which were skipped and why}

## Candidate List

### HIGH Confidence ({count})

| # | Candidate Name | Signal Sources | Package(s) | Entry Points | DB Tables | Est. LOC | Evidence Summary |
|---|---------------|----------------|------------|--------------|-----------|----------|-----------------|
| 1 | {name} | pkg, db, api, ui | {paths} | {count} endpoints | {tables} | {count} | {1-line summary} |

### MEDIUM Confidence ({count})

| # | Candidate Name | Signal Sources | Evidence | Ambiguity Reason |
|---|---------------|----------------|----------|-----------------|
| 1 | {name} | {sources} | {evidence} | {why it's ambiguous} |

### LOW Confidence ({count})

| # | Candidate Name | Signal Source | Evidence | Ambiguity Reason |
|---|---------------|--------------|----------|-----------------|
| 1 | {name} | {source} | {evidence} | {why it's weak} |

## Signal Source Details

### Package Structure (A1.1)
{detailed findings}

### Database Schema (A1.2)
{detailed findings or "Skipped: no database access"}

### Backend Entry Points (A1.3)
{detailed findings}

### Frontend Entry Points (A1.4)
{detailed findings or "Skipped: no frontend layer"}

## Pre-Generated Inputs Used
{list any external reports that were included, or "None"}

## Size Distribution

| Candidate | Est. Files | Est. LOC | % of Codebase | Size Flag |
|-----------|-----------|----------|---------------|-----------|
| {name} | {count} | {count} | {%} | {NORMAL / OVERSIZED / TINY} |

Total codebase: {files} files, {loc} lines of code.
Candidates cover: {covered_loc} lines ({coverage_pct}% — rough pre-coverage estimate).
```

Target: 15-25 raw candidates total across all confidence levels.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `analyze_candidates`, `status` to `in_progress`
- Tell the user: "{N} capability candidates discovered ({high} HIGH, {medium} MEDIUM, {low} LOW confidence). Next: deep analysis of each candidate."

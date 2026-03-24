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

## Signal Extraction (6 sub-steps)

### A1.1 — Package Structure Analysis

Scan the top-level directory structure and module/package organization of the codebase.

Look for domain-suggestive names:
- **Strong signals**: `payments`, `customers`, `orders`, `lending`, `accounts`, `notifications`, `auth`
- **Ambiguous signals**: `processing`, `management`, `utils`, `common`, `shared`, `core`
- **Infrastructure (not capabilities)**: `config`, `middleware`, `migrations`, `tests`, `scripts`

For each package/module, note:
- Package name and path
- Approximate file count and line count
- Whether it contains business logic or is infrastructure

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

### A1.6 — Format Candidate List

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

| # | Candidate Name | Signal Sources | Package(s) | Entry Points | DB Tables | Evidence Summary |
|---|---------------|----------------|------------|--------------|-----------|-----------------|
| 1 | {name} | pkg, db, api, ui | {paths} | {count} endpoints | {tables} | {1-line summary} |

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
```

Target: 15-25 raw candidates total across all confidence levels.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `analyze_candidates`, `status` to `in_progress`
- Tell the user: "{N} capability candidates discovered ({high} HIGH, {medium} MEDIUM, {low} LOW confidence). Next: deep analysis of each candidate."

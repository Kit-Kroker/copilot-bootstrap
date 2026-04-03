# Brownfield Workflow

This workflow activates when `project.json → approach = "brownfield"`. It replaces the greenfield interview steps (users, features, tech, complexity) with a 7-phase codebase discovery pipeline, then merges into the standard generation pipeline.

## Activation Condition

```
project.json → approach = "brownfield"
```

## Commands

| Command | Description |
|---------|-------------|
| `/init brownfield` | Initialize project as brownfield |
| `/scan` | Auto-detect stack and write `.discovery/context.json` |
| `/discover` | Run 7-phase capability extraction pipeline |
| `/generate` | Run specification generation pipeline |

## Steps

### Discovery (`/discover`)
1. seed_candidates
2. analyze_candidates
3. verify_coverage
4. lock_l1
5. define_l2
6. discovery_domain
7. blueprint_comparison

### Generation (`/generate`)
8. generate_instructions
9. generate_dev_skills
10. generate_dev_prompts
11. generate_hooks
12. done

## ADLC Extended Steps

Not applicable to the brownfield flow. Brownfield generates Copilot configuration only — ADLC analysis docs (KPIs, agent patterns, eval framework, etc.) are out of scope.

## Step Descriptions

### Discovery Pipeline (steps 1-7) — Capability Extraction

- **seed_candidates**: (A1) Extract capability candidates from 4 signal sources — package structure, database schema, backend entry points, frontend entry points. Cross-reference and assign HIGH/MEDIUM/LOW confidence. Produces 15-25 raw candidates.
- **analyze_candidates**: (A2) Deep analysis of each candidate — cohesion, coupling, boundary clarity. Determine action per candidate: confirm / split / merge / de-scope / flag.
- **verify_coverage**: (A3) Map all source files to capabilities. Target >90% coverage. Identify and resolve orphan code.
- **lock_l1**: (A4) Finalize the Level 1 capability list from confirmed, split, and merged candidates.
- **define_l2**: (A5) Define Level 2 sub-capabilities per L1. Map each L2 to code locations, entities, and operations. L2 = executable units of work.
- **discovery_domain**: (A6) Generate consolidated domain model with capability hierarchy, entity ownership, cross-capability dependencies, and full code traceability.
- **blueprint_comparison**: (A7) Compare code-derived capabilities against industry reference framework (BIAN for banking, TM Forum for telecom, APQC cross-industry). Flag: aligned / org-specific / missing-from-code.

### Generation Phase (steps 8-11) — Copilot Configuration

Generates configuration artifacts tailored to the detected stack and discovered domain. Does NOT re-generate analysis docs — those come from the discovery phase.

- **generate_instructions**: Generate `.github/copilot-instructions.md` — stack-specific, domain-aware AI instructions
- **generate_dev_skills**: Generate `.github/skills/` — dev skills matching the actual stack (e.g., `add-endpoint`, `add-migration`, `add-test`)
- **generate_dev_prompts**: Generate `.github/prompts/` — slash commands for common operations on this codebase
- **generate_hooks**: Configure `.claude/settings.json` — PostToolUse hooks for the detected linter and formatter
- **done**: Bootstrap complete

## Routing Table

### Discovery (`/discover`)

| Step | Skill | Output |
|------|-------|--------|
| `seed_candidates` | `discover-candidates` | docs/discovery/candidates.md |
| `analyze_candidates` | `analyze-candidates` | docs/discovery/analysis.md |
| `verify_coverage` | `verify-coverage` | docs/discovery/coverage.md |
| `lock_l1` | `lock-l1` | docs/discovery/l1-capabilities.md |
| `define_l2` | `define-l2` | docs/discovery/l2-capabilities.md |
| `discovery_domain` | `generate-discovery-domain` | docs/discovery/domain-model.md |
| `blueprint_comparison` | `compare-blueprint` | docs/discovery/blueprint-comparison.md |

### Generation (`/generate`)

| Step | Skill | Output |
|------|-------|--------|
| `generate_instructions` | `generate-copilot-instructions` | .github/copilot-instructions.md |
| `generate_dev_skills` | `generate-brownfield-skills` | .github/skills/ |
| `generate_dev_prompts` | `generate-brownfield-prompts` | .github/prompts/ |
| `generate_hooks` | `generate-brownfield-hooks` | .claude/settings.json |

## Design Principles

- **Adaptive by default** — Pipeline skips steps when signals are unavailable (no DB → skip schema analysis, API-only → skip frontend analysis). Extraction continues with fewer signals.
- **Pre-generated inputs accepted** — Each discovery skill checks if its output file already exists in `docs/discovery/`. Feed it exports from nDepend, JetBrains, DBA tools, or architecture notes to anchor analysis in higher-quality signals.
- **Confidence-driven** — Every candidate carries a confidence rating (HIGH/MEDIUM/LOW) based on cross-source evidence. Ambiguous candidates are explicitly flagged for architect review.
- **Code is source of truth** — Industry blueprint comparison (A7) adds context but does not override code-derived capabilities. Missing capabilities drive targeted questions, not assumptions.
- **Traceable throughout** — Every capability, operation, and entity is mapped to specific files, entry points, and code locations. The domain model is actionable, not decorative.

## Decision Loop

Each command manages its own pipeline lock file:

- `/discover` uses `.discovery/pipeline.lock.json`
- `/generate` uses `.discovery/generate.lock.json`

Loop per pipeline:
1. Read lock file → identify first non-completed step
2. Mark step `in_progress`
3. Run the corresponding skill
4. Mark `completed` (or `failed` on error)
5. Advance to next step — no user confirmation needed between steps
6. Stop on failure with instructions to fix and resume

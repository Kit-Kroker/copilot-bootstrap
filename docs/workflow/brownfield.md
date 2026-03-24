# Brownfield Workflow

This workflow activates when `project.json → approach = "brownfield"`. It replaces the greenfield interview steps (users, features, tech, complexity) with a 7-phase codebase discovery pipeline, then merges into the standard generation pipeline.

## Activation Condition

```
project.json → approach = "brownfield"
```

## Steps

1. idea
2. project_info
3. codebase_setup
4. seed_candidates
5. analyze_candidates
6. verify_coverage
7. lock_l1
8. define_l2
9. discovery_domain
10. blueprint_comparison
11. prd
12. capabilities
13. domain
14. design_workflow
15. skills
16. scripts
17. done

## ADLC Extended Steps

When `project.json → adlc = true` (type is `agent` or `ai-system`), the following steps activate after `done`:

18. constraints
19. kpis
20. human_agent_map
21. agent_pattern
22. cost_model
23. eval_framework
24. pov
25. monitoring
26. governance
27. adlc_done

## Step Descriptions

### Bootstrap Phase (steps 1-3)

- **idea**: Capture the modernization goal and pain points with the legacy system
- **project_info**: Collect project name, type, domain, and confirm brownfield approach
- **codebase_setup**: Collect codebase path, primary language, architecture style, database availability, and any pre-generated analysis reports

### Discovery Pipeline (steps 4-10) — Capability Extraction

- **seed_candidates**: (A1) Extract capability candidates from 4 signal sources — package structure, database schema, backend entry points, frontend entry points. Cross-reference and assign HIGH/MEDIUM/LOW confidence. Produces 15-25 raw candidates.
- **analyze_candidates**: (A2) Deep analysis of each candidate — cohesion, coupling, boundary clarity. Determine action per candidate: confirm / split / merge / de-scope / flag.
- **verify_coverage**: (A3) Map all source files to capabilities. Target >90% coverage. Identify and resolve orphan code.
- **lock_l1**: (A4) Finalize the Level 1 capability list from confirmed, split, and merged candidates.
- **define_l2**: (A5) Define Level 2 sub-capabilities per L1. Map each L2 to code locations, entities, and operations. L2 = executable units of work.
- **discovery_domain**: (A6) Generate consolidated domain model with capability hierarchy, entity ownership, cross-capability dependencies, and full code traceability.
- **blueprint_comparison**: (A7) Compare code-derived capabilities against industry reference framework (BIAN for banking, TM Forum for telecom, APQC cross-industry). Flag: aligned / org-specific / missing-from-code.

### Generation Phase (steps 11-17) — Same as Greenfield

- **prd**: Generate PRD from discovered capabilities (brownfield mode reads `docs/discovery/`)
- **capabilities**: Generate capability map from discovery L1/L2 outputs
- **domain**: Generate domain model enriched by discovery domain model
- **design_workflow**: Generate design workflow
- **skills**: Define required skills and agents
- **scripts**: Generate automation scripts
- **done**: Bootstrap complete

## Routing Table

| Step | Agent | Skill | Output |
|------|-------|-------|--------|
| `idea` | bootstrap | `bootstrap-ask` | answers.json: idea, pain_points |
| `project_info` | bootstrap | `bootstrap-ask` | answers.json: project_info (incl. approach) |
| `codebase_setup` | bootstrap | `bootstrap-ask` | answers.json: codebase_setup |
| `seed_candidates` | discovery | `discover-candidates` | docs/discovery/candidates.md |
| `analyze_candidates` | discovery | `analyze-candidates` | docs/discovery/analysis.md |
| `verify_coverage` | discovery | `verify-coverage` | docs/discovery/coverage.md |
| `lock_l1` | discovery | `lock-l1` | docs/discovery/l1-capabilities.md |
| `define_l2` | discovery | `define-l2` | docs/discovery/l2-capabilities.md |
| `discovery_domain` | discovery | `generate-discovery-domain` | docs/discovery/domain-model.md |
| `blueprint_comparison` | discovery | `compare-blueprint` | docs/discovery/blueprint-comparison.md |
| `prd` | analyst | `generate-prd` | docs/analysis/prd.md |
| `capabilities` | analyst | `generate-capabilities` | docs/analysis/capabilities.md |
| `domain` | architect | `generate-domain` | docs/domain/model.md |
| `design_workflow` | designer | `generate-design-workflow` | docs/workflow/design.md |
| `skills` | script | `generate-skills` | .github/skills/ (dev skills) |
| `scripts` | script | `generate-scripts` | scripts/*.sh |
| `done` | — | — | Bootstrap complete |

## Design Principles

- **Adaptive by default** — Pipeline skips steps when signals are unavailable (no DB → skip schema analysis, API-only → skip frontend analysis). Extraction continues with fewer signals.
- **Pre-generated inputs accepted** — Each discovery skill checks if its output file already exists in `docs/discovery/`. Feed it exports from nDepend, JetBrains, DBA tools, or architecture notes to anchor analysis in higher-quality signals.
- **Confidence-driven** — Every candidate carries a confidence rating (HIGH/MEDIUM/LOW) based on cross-source evidence. Ambiguous candidates are explicitly flagged for architect review.
- **Code is source of truth** — Industry blueprint comparison (A7) adds context but does not override code-derived capabilities. Missing capabilities drive targeted questions, not assumptions.
- **Traceable throughout** — Every capability, operation, and entity is mapped to specific files, entry points, and code locations. The domain model is actionable, not decorative.

## Decision Loop

Same as the standard bootstrap decision loop, extended for brownfield:

- Read workflow.json → current step + status
- Look up step in brownfield routing table → agent + skill
- Check answers.json → if data missing for step, run bootstrap-ask first
- Run the skill for the current step
- Save outputs to the correct file
- Run workflow-update → advance to next step
- Report what was done and what comes next

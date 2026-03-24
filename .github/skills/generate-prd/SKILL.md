---
name: generate-prd
description: Generate a Product Requirements Document from collected bootstrap answers. Use this when the workflow step is "prd". Reads answers.json and produces docs/analysis/prd.md covering goal, users, features, scope, non-goals, and constraints. Adds agentic sections when type is agent or ai-system.
argument-hint: "[project name or leave blank to use answers.json]"
---

# Skill Instructions

Read `.project/state/answers.json`.
Read `project.json` to check the `type`, `adlc`, and `approach` fields.

Generate `docs/analysis/prd.md` using this exact structure:

```markdown
# Product Requirements Document

## Overview

**Project:** {name}
**Type:** {type}
**Domain:** {domain}
**Complexity:** {complexity}

## Goal

{One paragraph: what this product does and why it exists, derived from the idea.}

## Pain Points

**Manual process:** {from answers.pain_points.manual_process}
**Why human today:** {from answers.pain_points.why_human}

## Users

| Role | Description |
|------|-------------|
| {role} | {what they do in the system} |

## Core Features

{Numbered list of features from answers.}

## Scope

### In Scope
- {Features and capabilities included in V1.}

### Out of Scope
- {Explicitly excluded items.}

## Non-Goals

- {Things intentionally not addressed.}

## Constraints

### Technical
- Backend: {backend}
- Frontend: {frontend}
- Database: {database if specified}

### Business
- {Any business constraints implied by domain or complexity.}

## Open Questions

- {Any gaps in the answers that need resolution before implementation.}
```

### Agentic Sections (when type is `agent` or `ai-system`)

When `project.json → adlc = true`, add these sections after "Open Questions":

```markdown
## Agent Role

{One-sentence statement of what the agent does and does not do.}

## Non-Determinism Acknowledgement

This system uses LLM-based reasoning. Outputs are probabilistic and not guaranteed to be identical across runs. The evaluation framework (docs/spec/eval.md) defines acceptable variance thresholds.

## Failure Modes

| Failure Mode | Impact | Handling |
|-------------|--------|----------|
| {how the agent can fail} | {what happens} | {escalation / fallback / human review} |

## Early Failure Signals

| Signal | Measurement | Threshold |
|--------|------------|-----------|
| {indicator that the system is drifting} | {how to measure} | {when to act} |
```

### Brownfield Sections (when approach is `brownfield`)

When `project.json → approach = "brownfield"`, adapt the PRD as follows:

**Additional inputs to read:**
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required
- `docs/discovery/domain-model.md`
- `docs/discovery/blueprint-comparison.md`

**Changes to standard sections:**
- **Overview**: Add `**Approach:** Brownfield (modernizing existing system)`
- **Core Features**: Derive from discovered L1/L2 capabilities instead of user-supplied feature list. Group by L1 capability.
- **Constraints → Technical**: Derive from auto-discovered tech stack in `codebase_setup` (language, architecture, existing infrastructure)
- **Users**: If not explicitly collected (brownfield skips the users step), infer user roles from frontend entry points and RBAC patterns found in the codebase. Flag as "inferred from code — confirm with stakeholders."

**Add these brownfield-specific sections after "Open Questions":**

```markdown
## Legacy Context

This PRD is derived from codebase analysis of an existing system.

- **Discovery artifacts**: See `docs/discovery/` for full extraction pipeline outputs
- **L1 Capabilities**: {count} business capabilities extracted (see docs/discovery/l1-capabilities.md)
- **L2 Operations**: {count} operational sub-capabilities (see docs/discovery/l2-capabilities.md)
- **Code coverage**: {percentage}% of codebase mapped to capabilities

## Modernization Goals

| Goal | Current State | Target State | Priority |
|------|-------------|-------------|----------|
| {goal} | {what exists today} | {what should change} | {HIGH/MEDIUM/LOW} |

## Industry Alignment

{Summary from docs/discovery/blueprint-comparison.md}
- Aligned capabilities: {count}
- Org-specific: {count}
- Missing from code: {count} (see blueprint-comparison.md for details)
```

If required data is missing, ask focused follow-up questions before generating.

After writing the file:
- Update `.project/state/workflow.json`: set `step` to `capabilities`, `status` to `in_progress`
- Update `project.json` fields `name`, `type`, `domain` from answers

---
name: generate-design-workflow
description: Generate the design workflow plan and design overview. Use this when the workflow step is "design_workflow". Reads the PRD and answers, then produces docs/workflow/design.md and docs/design/overview.md with phases, deliverables, and entry/exit criteria.
argument-hint: "[project name or leave blank to use answers.json]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`
- `docs/analysis/capabilities.md` (if present)

Generate two files:

---

## 1. `docs/workflow/design.md`

Already exists as a template. Verify it covers all steps needed for this project. Add or remove steps based on complexity from answers.json.

---

## 2. `docs/design/overview.md`

Use this structure:

```markdown
# Design Overview

## Approach

{One paragraph describing the design strategy based on project type and complexity.}

## Phases

### Phase 1 — Discovery & Architecture
Steps: capabilities, domain, rbac, workflow, integration, metrics
Goal: Understand the system before designing screens.

### Phase 2 — Information Architecture & Flows
Steps: ia, flows
Goal: Define navigation and user journeys.

### Phase 3 — Wireframes & UX
Steps: wireframes, ux
Goal: Low-fidelity layout and interaction rules.

### Phase 4 — Visual Design
Steps: design-system, hi-fi
Goal: Visual language and high-fidelity screens.

### Phase 5 — Handoff
Steps: spec
Goal: Implementation-ready specification.

## Deliverables

| Phase | Deliverable | Owner |
|-------|-------------|-------|
| Discovery | capabilities.md, domain model, RBAC | Architect Agent |
| IA & Flows | ia.md, flows.md | Designer Agent |
| Wireframes | wireframes.md | Designer Agent |
| Visual | design-system.md, hi-fi.md | Designer Agent |
| Handoff | design-spec.md | Spec Agent |

## Entry Criteria

- PRD is complete (`docs/analysis/prd.md` exists)
- Complexity level is defined

## Exit Criteria

- All phase deliverables are generated
- Design spec is ready for development handoff
```

After generating both files:
- Update `.project/state/workflow.json`: set `step` to `skills`, `status` to `in_progress`

---
name: Architect
description: Generates the domain model, RBAC policy, business workflows, and (for ADLC) agent architecture pattern and cost model. Called after the analyst phase is complete.
tools: ['read', 'edit']
user-invocable: false
handoffs:
  - label: "Design Workflow & IA"
    agent: designer
    prompt: "Domain architecture is complete. Read docs/domain/ and docs/analysis/ then run the full designer workflow: design overview, information architecture, and user flows."
    send: false
---

# Architect Agent

You generate the domain architecture documents for the project.

## On Start

Read these files in order (stop and report if any required file is missing):
1. `docs/analysis/prd.md` ← required
2. `docs/analysis/capabilities.md` ← required
3. `project.json` ← check `adlc` flag
4. `docs/domain/model.md` — if exists, skip to rbac
5. `docs/domain/rbac.md` — if exists, skip to workflows

## Documents to Generate (in order)

### 1. `docs/domain/model.md`

```markdown
# Domain Model

## Glossary
| Term | Definition |
|------|------------|

## Entities
### {EntityName}
**Identity:** {unique identifier}
**Attributes:**
- `{field}`: {type} — {description}
**Invariants:**
- {rule that must always hold}

## Value Objects
### {ValueObjectName}
**Attributes:** ...
**Rules:** ...

## Aggregates
| Aggregate Root | Included Entities | Consistency Boundary |
|---------------|-------------------|----------------------|

## Bounded Contexts
| Context | Responsibility | Key Entities | Exposes |
|---------|---------------|--------------|---------|

## Domain Events
| Event | Trigger | Source | Consumers |
|-------|---------|--------|-----------|

## Open Questions
- {modelling decisions needing clarification}
```

### 2. `docs/domain/rbac.md`

```markdown
# Role-Based Access Control

## Roles
| Role | Description | Scope |
|------|-------------|-------|

## Permission Matrix
| Resource | Action | {Role1} | {Role2} |
|----------|--------|---------|---------|
| {resource} | create | ✅ | ❌ |
| {resource} | read   | ✅ | ✅ |
| {resource} | update | ✅ | ❌ |
| {resource} | delete | ✅ | ❌ |

## Scope Rules
| Role | Can Access |
|------|-----------|

## Elevation Rules
- {conditions for temporary permission elevation}

## Conflicts and Assumptions
- {permission conflicts or missing role assumptions}
```

### 3. `docs/domain/workflows.md`

```markdown
# Business Workflows

## Workflow Index
| Workflow | Actor | Trigger | Outcome |
|----------|-------|---------|---------|

## {Workflow Name}
**Actor:** {role}
**Trigger:** {event}
**Preconditions:** {what must be true}
**Outcome:** {end state}

### Steps
| # | Actor | Action | System Response |
|---|-------|--------|----------------|

### State Transitions
{Entity}: `{from}` → `{to}` on `{trigger}`

### Exceptions
| Condition | Handling |
|-----------|----------|

### Capability Traceability
- Requires: {capabilities from capabilities.md}
```

### 4. `docs/domain/agent-pattern.md` *(ADLC only)*

When `adlc = true`, generate this document using the `generate-agent-pattern` skill. See that skill for the full template.

### 5. `docs/domain/cost-model.md` *(ADLC only)*

When `adlc = true`, generate this document using the `generate-cost-model` skill. See that skill for the full template.

## After All Documents Are Generated

- Update `.project/state/workflow.json`: `{ "step": "design_workflow", "status": "in_progress" }`
  - For ADLC: if generating agent-pattern and cost-model, update step to `eval_framework` after those complete
- Tell the user: "Domain architecture is complete. Click **Design Workflow & IA** to continue."

## Rules

- Always generate in order: model → rbac → workflows (→ agent-pattern → cost-model for ADLC)
- Derive resources in rbac directly from entities in model.md
- Cover at least one workflow per core feature
- Use consistent naming across all documents

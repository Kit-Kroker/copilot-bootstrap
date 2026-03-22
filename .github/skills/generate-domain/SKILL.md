---
name: generate-domain
description: Generate the domain model including entities, aggregates, bounded contexts, and domain events. Use this when the design workflow step is "domain". Requires the PRD and capabilities to be defined.
argument-hint: "[bounded context to focus on, or leave blank for full model]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`
- `docs/analysis/capabilities.md` (if present)

Generate `docs/domain/model.md` using this structure:

```markdown
# Domain Model

## Glossary

| Term | Definition |
|------|------------|
| {term} | {definition used consistently across the system} |

## Entities

### {EntityName}

**Identity:** {what uniquely identifies this entity}
**Attributes:**
- `{field}`: {type} — {description}

**Invariants:**
- {rule that must always hold true}

---

## Value Objects

### {ValueObjectName}

**Attributes:**
- `{field}`: {type}

**Rules:**
- {validation or constraint}

---

## Aggregates

| Aggregate Root | Included Entities | Consistency Boundary |
|---------------|-------------------|----------------------|
| {entity} | {list} | {what must be consistent together} |

## Bounded Contexts

| Context | Responsibility | Key Entities | Exposes |
|---------|---------------|--------------|---------|
| {context} | {what it owns} | {list} | {API / events} |

## Domain Events

| Event | Trigger | Source Context | Consumed By |
|-------|---------|---------------|-------------|
| {EventName} | {what causes it} | {context} | {contexts or services} |

## Open Questions

- {Any modelling decisions that need clarification}
```

Prefer a normalized model over UI-driven structures.
Use consistent naming across all domain documents.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `rbac`, `status` to `in_progress`

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
- `project.json` (check `approach` field)

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

### Brownfield Mode (when approach = brownfield)

When `project.json → approach = "brownfield"`, also read:
- `docs/discovery/domain-model.md` ← required (primary input)
- `docs/discovery/l1-capabilities.md`
- `docs/discovery/l2-capabilities.md`

**Changes to domain model generation:**

1. **Use discovery domain model as primary input** — The `docs/discovery/domain-model.md` already contains code-derived entities, relationships, and bounded context candidates. Use this as the foundation rather than inventing entities from the PRD.

2. **Enrich, don't replace** — Add DDD structure (aggregates, value objects, invariants, domain events) on top of the code-derived entities. The discovery model shows what IS; the domain model adds what SHOULD BE.

3. **Bounded Contexts** — Use the bounded context candidates from the discovery domain model as starting points. Refine based on coupling analysis.

4. **Add Legacy Entity Mapping section:**

```markdown
## Legacy Entity Mapping

| Domain Entity | Legacy Table/Class | Mapping Notes |
|--------------|-------------------|--------------|
| {new entity name} | {original table or class name} | {rename, split, merge, or keep as-is} |
```

5. **Add Discovery Provenance section:**

```markdown
## Discovery Provenance

This domain model is derived from codebase analysis of the existing system.
- Code-derived entities: {count} (from docs/discovery/domain-model.md)
- Code-derived bounded contexts: {count}
- Cross-capability dependencies: {count}
- See docs/discovery/ for full extraction pipeline outputs.
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `rbac`, `status` to `in_progress`

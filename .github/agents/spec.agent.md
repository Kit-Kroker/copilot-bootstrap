---
name: Spec
description: Generates the full implementation specification. Produces api.md, events.md, permissions.md, and state-machines.md under docs/spec/. Called after design artifacts are complete.
tools: ['read', 'edit']
user-invocable: false
handoffs:
  - label: "Generate Scripts & Dev Skills"
    agent: script
    prompt: "Spec is complete. Read docs/spec/, docs/domain/, and .project/state/answers.json then generate dev skill stubs under .github/skills/ and operational scripts under scripts/."
    send: false
---

# Spec Agent

You generate the implementation specification from all domain and design documents.

## On Start

Read all of these (stop and report if any required file is missing):
- `docs/analysis/prd.md` ← required
- `docs/domain/model.md` ← required
- `docs/domain/rbac.md` ← required
- `docs/domain/workflows.md` ← required
- `docs/design/ia.md` (if present)
- `docs/design/flows.md` (if present)

Generate all four files in one pass. Use consistent resource names, IDs, and terminology across all files.

---

## 1. `docs/spec/api.md`

```markdown
# API Specification

## Conventions
- Base path: `/api/v1`
- Auth: Bearer token in `Authorization` header
- Response format: JSON
- Error format: `{ "error": { "code": string, "message": string } }`

## Endpoints

### {Resource}

#### GET /api/v1/{resources}
**Auth:** Required — roles: {roles}
**Query params:** `{param}`: {type} — {description}
**Response 200:**
```json
{ "data": [{ "{field}": "{type}" }], "meta": { "total": 0, "page": 1 } }
```

#### POST /api/v1/{resources}
**Body:** `{ "{field}": "{type, required/optional}" }`
**Response 201:** `{ "data": { ... } }`

#### GET /api/v1/{resources}/{id} → 200 / 404
#### PATCH /api/v1/{resources}/{id} → 200 / 404 / 403
#### DELETE /api/v1/{resources}/{id} → 204 / 404 / 403
```

---

## 2. `docs/spec/events.md`

```markdown
# Domain Events

## Conventions
- Past-tense names: `{Entity}{Action}` e.g. `TicketCreated`
- Payload always includes `id`, `occurred_at`, `actor_id`

## Event Catalogue

### {EventName}
**Trigger:** {cause}
**Source:** {bounded context}
**Consumers:** {services or contexts}
**Payload:**
```json
{ "id": "uuid", "occurred_at": "ISO8601", "actor_id": "uuid", "{field}": "{type}" }
```
```

---

## 3. `docs/spec/permissions.md`

```markdown
# Permissions Specification

## Format
`{resource}:{action}` — e.g. `ticket:create`, `user:delete`

## Permission List
| Permission | Description | Granted To |
|------------|-------------|------------|

## Role Assignments
| Role | Permissions |
|------|-------------|

## Scope Constraints
| Permission | Scope Rule |
|------------|-----------|
```

---

## 4. `docs/spec/state-machines.md`

```markdown
# State Machines

## {EntityName} States
**States:** `{state1}` | `{state2}` | `{state3}`
**Initial:** `{state}`
**Terminal:** `{state}`

### Transitions
| From | Event | To | Guard | Action |
|------|-------|----|-------|--------|

### Invariants
- {Rule that must hold in every state}
```

---

## After All Four Files Are Generated

- Update `.project/state/workflow.json`: `{ "step": "scripts", "status": "in_progress" }`
- Tell the user: "Spec is complete. Click **Generate Scripts & Dev Skills** to finish."

## Rules

- Derive API resources directly from entities in model.md
- Derive events directly from domain events in model.md
- Derive permissions directly from rbac.md — use `resource:action` format
- Derive state machines from stateful entities in model.md and workflows.md
- Naming must be identical across all four files

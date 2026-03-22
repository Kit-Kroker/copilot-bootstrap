---
name: generate-spec
description: Generate the full implementation specification including API contracts, domain events, permissions, and state machines. Use this when the workflow step is "spec". Requires domain model, RBAC, and workflows to be complete.
argument-hint: "[spec file to generate: api | events | permissions | state-machines | all]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`
- `docs/domain/model.md`
- `docs/domain/rbac.md`
- `docs/domain/workflows.md`
- `docs/design/flows.md` (if present)

Generate all four files under `docs/spec/`. Use consistent resource names, IDs, and terminology across all files.

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

#### `GET /api/v1/{resources}`
**Description:** {what it returns}
**Auth:** Required — roles: {roles}
**Query params:**
- `{param}`: {type} — {description}

**Response 200:**
```json
{
  "data": [ { "{field}": "{type}" } ],
  "meta": { "total": 0, "page": 1 }
}
```

#### `POST /api/v1/{resources}`
**Description:** {what it creates}
**Auth:** Required — roles: {roles}
**Body:**
```json
{ "{field}": "{type, required/optional}" }
```
**Response 201:** `{ "data": { ... } }`

#### `GET /api/v1/{resources}/{id}`
**Response 200 / 404**

#### `PATCH /api/v1/{resources}/{id}`
**Response 200 / 404 / 403**

#### `DELETE /api/v1/{resources}/{id}`
**Response 204 / 404 / 403**

---
{Repeat for each resource from domain model}
```

---

## 2. `docs/spec/events.md`

```markdown
# Domain Events

## Conventions

- Events are past-tense: `{Entity}{Action}` e.g. `TicketCreated`
- Payload always includes `id`, `occurred_at`, `actor_id`

## Event Catalogue

### {EventName}

**Trigger:** {what causes this event}
**Source:** {bounded context}
**Consumers:** {services or contexts that react}

**Payload:**
```json
{
  "id": "uuid",
  "occurred_at": "ISO8601",
  "actor_id": "uuid",
  "{domain_field}": "{type}"
}
```

---
{Repeat for each domain event from model.md}
```

---

## 3. `docs/spec/permissions.md`

```markdown
# Permissions Specification

## Permission Format

`{resource}:{action}` — e.g. `ticket:create`, `user:delete`

## Permission List

| Permission | Description | Granted To |
|------------|-------------|------------|
| `{resource}:{action}` | {what it allows} | {roles} |

## Role Assignments

| Role | Permissions |
|------|-------------|
| {role} | `{perm1}`, `{perm2}` |

## Scope Constraints

| Permission | Scope Rule |
|------------|-----------|
| `{perm}` | {e.g. own records only / tenant-wide / global} |
```

---

## 4. `docs/spec/state-machines.md`

```markdown
# State Machines

## {EntityName} States

**States:** `{state1}` | `{state2}` | `{state3}`
**Initial state:** `{state}`
**Terminal states:** `{state}`

### Transitions

| From | Event | To | Guard | Action |
|------|-------|----|-------|--------|
| {state} | {EventName} | {state} | {condition or —} | {side effect} |

### Invariants

- {Rule that must hold in every state}

---
{Repeat for each stateful entity from model.md}
```

---

After generating all four files:
- Update `.project/state/workflow.json`: set `step` to `scripts`, `status` to `in_progress`

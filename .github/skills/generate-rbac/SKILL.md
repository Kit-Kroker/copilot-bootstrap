---
name: generate-rbac
description: Generate the role-based access control model including roles, permissions, and resource-action matrix. Use this when the design workflow step is "rbac". Requires the domain model and user roles from answers.
argument-hint: "[role to focus on, or leave blank for full RBAC model]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`
- `docs/domain/model.md`

Generate `docs/domain/rbac.md` using this structure:

```markdown
# Role-Based Access Control

## Roles

| Role | Description | Scope |
|------|-------------|-------|
| {role} | {what this role does} | {global / tenant / project / own} |

## Permission Matrix

| Resource | Action | {Role 1} | {Role 2} | {Role N} |
|----------|--------|----------|----------|----------|
| {resource} | create | ✅ | ❌ | ✅ |
| {resource} | read | ✅ | ✅ | ✅ |
| {resource} | update | ✅ | ❌ | ❌ |
| {resource} | delete | ✅ | ❌ | ❌ |

## Scope Rules

| Role | Can Access |
|------|-----------|
| {role} | {own records / tenant records / all records} |

## Elevation Rules

- {Condition under which a role may temporarily gain higher permissions}

## Least-Privilege Notes

- {Resources or actions that should be restricted by default}

## Conflicts and Assumptions

- {Any permission conflicts or missing role assumptions to resolve}
```

Derive resources directly from entities in `docs/domain/model.md`.
Call out any conflicts or gaps that need product decisions.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `workflow`, `status` to `in_progress`

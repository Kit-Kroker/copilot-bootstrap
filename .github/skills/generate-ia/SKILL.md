---
name: generate-ia
description: Generate the product information architecture including sitemap, navigation model, and screen ownership. Use this when the design workflow step is "ia". Requires the PRD and user roles to be defined.
argument-hint: "[role to focus on, or leave blank for all roles]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`
- `docs/analysis/capabilities.md` (if present)
- `docs/domain/rbac.md` (if present)

Generate `docs/design/ia.md` using this structure:

```markdown
# Information Architecture

## Sitemap

{Tree structure of all screens/sections grouped by area.}

## Navigation Model

| Level | Type | Items |
|-------|------|-------|
| Primary | {sidebar / top-nav / tab-bar} | {list of nav items} |
| Secondary | {sub-nav / breadcrumb} | {list} |
| Contextual | {inline / modal / drawer} | {list} |

## Screen Inventory

| Screen | Path | Owner Role | Capability |
|--------|------|------------|------------|
| {screen name} | {/path} | {role} | {capability it serves} |

## Content Hierarchy

{Describe priority of information on key screens.}

## Access Rules

| Screen | Visible To | Hidden From |
|--------|------------|-------------|
| {screen} | {roles} | {roles} |

## Cross-Linking Rules

- {Rule 1: e.g., every list screen links to detail screen}
- {Rule 2}
```

Ensure every user role defined in answers.json has at least one primary screen.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `flows`, `status` to `in_progress`

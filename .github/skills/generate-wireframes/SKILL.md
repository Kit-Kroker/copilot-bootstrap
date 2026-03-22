---
name: generate-wireframes
description: Generate low-fidelity wireframes for all screens defined in the IA. Use this when the design workflow step is "wireframes". Requires ia.md and flows.md to exist.
argument-hint: "[screen name to wireframe, or leave blank for all screens]"
---

# Skill Instructions

## Prerequisites

- `docs/design/ia.md` must exist (screen inventory)
- `docs/design/flows.md` must exist (user flows)

## Inputs to Read

1. `docs/design/ia.md` — Screen Inventory, Navigation Model, Access Rules
2. `docs/design/flows.md` — steps and actions per flow
3. `docs/analysis/prd.md` — project goal and user context
4. `.project/state/answers.json` — project name, type, complexity, frontend tech

## Workflow

For each screen in the Screen Inventory, produce a wireframe section describing:

- **Layout zones** — which regions exist (header, sidebar, main, drawer, modal)
- **Key components** — what goes in each zone (list, card, table, form, chart, panel)
- **States** — default loaded state, empty state, and error/validation state where applicable
- **Actions** — primary and secondary actions available on screen
- **Navigation** — where the user arrives from and can go to

Generate `docs/design/wireframes.md` using this structure:

```markdown
# Wireframes

## Conventions

- Layout described as zones: [Header] [Sidebar] [Main] [Drawer/Panel] [Modal]
- Components: List, Card, Table, Form, Chart, Stat, Badge, Button, Banner
- States covered per screen: Default, Empty, Error (forms only)

---

## {Screen Name}

**Path:** {route}
**Role:** {owner role(s)}
**Entry from:** {source screens or triggers}
**Leads to:** {destination screens}

### Layout

```
+--------------------------------------------------+
| Header: {logo, nav, user menu, global actions}   |
+------------+-------------------------------------+
| Sidebar    | Main Content                        |
| {nav items}| {primary content zone description}  |
|            |                                     |
|            | {secondary zone if applicable}      |
+------------+-------------------------------------+
```

### Zones

| Zone | Content | Components |
|------|---------|------------|
| Header | {what appears here} | {component types} |
| Sidebar | {what appears here} | {component types} |
| Main | {what appears here} | {component types} |
| Drawer/Panel | {if applicable} | {component types} |

### Actions

| Action | Type | Trigger |
|--------|------|---------|
| {action label} | Primary / Secondary / Destructive | {button, row click, etc.} |

### States

**Default:** {description of loaded state with real-looking data}
**Empty:** {description of zero-data state with call-to-action}
**Error:** {for forms — field-level validation and inline error messages}

---

{Repeat for each screen}
```

## Rules

- Keep descriptions layout-level only — no visual design, colors, or typography
- Use ASCII box diagrams for layout zones
- Every screen must have at minimum Default and Empty states
- Form screens must also include an Error state
- Actions must map to steps in `flows.md` for the corresponding flow

## After All Wireframes Are Generated

- Update `.project/state/workflow.json`: set `step` to `stitch`, `status` to `in_progress`

---
name: generate-stitch-screens
description: Generate high-fidelity UI screens using Google Stitch. Reads the IA and user flows to build prompts, calls the Stitch MCP tools, and saves HTML outputs to docs/design/screens/. Use this after flows are complete.
argument-hint: "[screen name to generate, or leave blank for all screens]"
---

# Skill Instructions

## Prerequisites

- `docs/design/ia.md` must exist (screen inventory)
- `docs/design/flows.md` must exist (user flows)
- Stitch MCP server must be running (see docs/design/stitch-setup.md)

## Inputs to Read

1. `docs/design/ia.md` — Screen Inventory table and Access Rules
2. `docs/design/flows.md` — steps and actions per flow
3. `docs/analysis/prd.md` — project goal and user context
4. `.project/state/answers.json` — project name, type, complexity, frontend tech

## Workflow

### 1. Create a Stitch project

Call `stitch/create_project` once per bootstrap run:
```
title: "{project name} — Bootstrap"
```

Save the returned project ID for subsequent calls.

### 2. For each screen in the Screen Inventory

Build a prompt from the screen's data in `ia.md` and the matching flow in `flows.md`:

**Prompt template:**
```
Design a {screen name} screen for a {type} application called "{name}".

Users who access this screen: {roles from access rules}
Purpose: {what the user does here}
Navigation: arrives from {source screens}, can navigate to {destination screens}

Content to display:
{key content elements from ia.md}

Available actions:
{actions from the matching flow in flows.md}

Current state: {default loaded state with real-looking sample data}
Style: Clean, professional {simple/saas/enterprise} product UI.
Technology: {frontend from answers.json} component patterns where applicable.
```

Call `stitch/generate_screen_from_text` with this prompt.

### 3. Generate additional states

For each screen, generate two more states using the same tool:

**Empty state prompt:**
```
Same screen as above but showing an empty state — no data yet.
Include a helpful empty state message and a clear call-to-action.
```

**Error state prompt** (for form screens only):
```
Same screen as above but showing a validation error state.
Highlight the fields with errors and show inline error messages.
```

### 4. Retrieve and save

Call `stitch/get_screen` to retrieve each generated screen's HTML output.
Save to `docs/design/screens/{screen-name}.html`.
Save empty state to `docs/design/screens/{screen-name}-empty.html`.
Save error state to `docs/design/screens/{screen-name}-error.html`.

### 5. Update the index

Update `docs/design/screens/index.md`:

```markdown
# Screen Index

| Screen | Files | States | Notes |
|--------|-------|--------|-------|
| {screen name} | {name}.html | default, empty | {any notes} |
| {form screen} | {name}.html | default, error | |
```

## If Stitch MCP Is Not Available

Write to `docs/design/screens/index.md`:

```markdown
# Screen Index

Stitch MCP server not configured. See docs/design/stitch-setup.md.

Run `/stitch` after setup to generate screens.
```

Do not block — the workflow continues to the spec phase without screens.

## After All Screens Are Generated

- Update `.project/state/workflow.json`: set `step` to `spec`, `status` to `in_progress`

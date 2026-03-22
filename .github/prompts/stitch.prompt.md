---
name: stitch
description: Generate or regenerate UI screens for one or all screens using Google Stitch. Reads the IA and flows to build prompts, then calls the Stitch MCP tool.
agent: Designer
tools: ['read', 'edit', 'stitch/*']
argument-hint: "[screen name to regenerate, or leave blank for all screens]"
---

Read `docs/design/ia.md` to get the screen inventory.
Read `docs/design/flows.md` to get actions and steps per screen.
Read `.project/state/answers.json` for project name, type, and complexity.

If the user specified a screen name: generate only that screen.
If no screen specified: generate all screens from the Screen Inventory in ia.md.

For each screen, call the Stitch MCP tool with a prompt built from:
- Screen name and purpose (from ia.md)
- Roles who access it (from ia.md access rules)
- Key content and actions (from the matching flow in flows.md)
- Project context (from answers.json)

Generate: default state, empty state (for lists/dashboards), error state (for forms).

Save each result to `docs/design/screens/{screen-name}.html`.
Update `docs/design/screens/index.md` with the result.

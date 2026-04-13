---
name: report
description: Generate a non-technical stakeholder report from brownfield discovery results. Synthesises capability map, health signals, industry alignment, and modernisation posture into a single shareable document. Run after /discover completes.
tools: ['read', 'edit']
---

Generate a stakeholder report from completed brownfield discovery.

## Pre-flight

1. Read `project.json`. If it doesn't exist: "project.json not found. Run `/init` first."
2. If `approach` is not `"brownfield"`: "Stakeholder report requires brownfield approach. Current: {approach}."
3. Check `.discovery/context.json` exists. If not: "context.json not found. Run `/scan` first."
4. Check that `docs/discovery/l1-capabilities.md` exists. If not: "Discovery not complete. Run `/discover` first."
5. Check that `docs/discovery/blueprint-comparison.md` exists. If not: "Blueprint comparison not found. Discovery pipeline must complete all 7 steps before generating the report. Run `/discover` to finish."

## Generate the report

Use the `generate-stakeholder-report` skill to produce `docs/discovery/stakeholder-report.md`.

Do NOT wait for user confirmation before starting.

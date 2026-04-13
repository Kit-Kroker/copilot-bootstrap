---
name: report
description: Generate all discovery reports (stakeholder, architect, dev, and security if available) from brownfield discovery results. Runs all report skills in sequence. Run after /discover completes.
tools: ['read', 'edit']
skills: ['generate-stakeholder-report', 'generate-architect-report', 'generate-dev-report', 'generate-security-report']
---

Generate the full discovery report suite from completed brownfield discovery.

## Pre-flight

1. Read `project.json`. If it doesn't exist: "project.json not found. Run `/init` first."
2. If `approach` is not `"brownfield"`: "Discovery reports require brownfield approach. Current: {approach}."
3. Check `.discovery/context.json` exists. If not: "context.json not found. Run `/scan` first."
4. Check that `docs/discovery/l1-capabilities.md` exists. If not: "Discovery not complete. Run `/discover` first."
5. Check that `docs/discovery/blueprint-comparison.md` exists. If not: "Blueprint comparison not found. Discovery pipeline must complete all 7 steps before generating reports. Run `/discover` to finish."
6. Check whether `docs/security/risk-scores.json` exists. Record the result as `security_available` (true/false) — do not fail if absent.

## Generate the reports

Run all applicable skills in sequence. Do NOT wait for user confirmation before starting.

### Report 1 — Stakeholder

Use the `generate-stakeholder-report` skill to produce `docs/discovery/stakeholder-report.md`.

### Report 2 — Architect

Use the `generate-architect-report` skill to produce `docs/discovery/architect-report.md`.

### Report 3 — Dev

Use the `generate-dev-report` skill to produce `docs/discovery/dev-report.md`.

### Report 4 — Security

If `security_available` is true: use the `generate-security-report` skill to produce `docs/security/security-report.md`.

If `security_available` is false: skip this step and note it in the completion message.

## Complete

After all reports are generated, tell the user:

```
Discovery reports generated:

  Stakeholder  docs/discovery/stakeholder-report.md   — executives, PMs, BAs
  Architect    docs/discovery/architect-report.md     — solutions and enterprise architects
  Dev          docs/discovery/dev-report.md            — engineering teams
  Security     docs/security/security-report.md        — security team, tech leads
               docs/security/domain-model-secured.md  — architecture handoff with risk overlays

Share the stakeholder report as a standalone document. Use the architect, dev, and security reports as internal planning artifacts.
```

If `security_available` was false, replace the Security lines with:

```
  Security     not generated — run `/assess` first, then re-run `/report`
```

---
name: status
description: Show the current bootstrap workflow state — active step, status, collected answers, and generated files.
agent: agent
tools: ['read']
---

Read `.project/state/workflow.json` and `.project/state/answers.json`.

Then check which output files exist from this list:
- `docs/analysis/prd.md`
- `docs/analysis/capabilities.md`
- `docs/domain/model.md`
- `docs/domain/rbac.md`
- `docs/domain/workflows.md`
- `docs/design/overview.md`
- `docs/design/ia.md`
- `docs/design/flows.md`
- `docs/spec/api.md`
- `docs/spec/events.md`
- `docs/spec/permissions.md`
- `docs/spec/state-machines.md`

Print a concise status report:

```
Bootstrap Status
────────────────
Step:    {step}
Status:  {status}

Answers collected:
  {list each key in answers.json with ✅ or ❌ if missing}

Generated files:
  {list each file with ✅ exists or ❌ missing}

Next action:
  {what should happen next based on the current step}
```

---
name: status
description: Show the current bootstrap workflow state — active step, status, collected answers, and generated files. Includes ADLC status when active.
agent: agent
tools: ['read']
---

Read `.project/state/workflow.json`, `.project/state/answers.json`, and `project.json`.

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

If `project.json → adlc = true`, also check:
- `docs/analysis/kpis.md`
- `docs/analysis/human-agent-map.md`
- `docs/domain/agent-pattern.md`
- `docs/domain/cost-model.md`
- `docs/spec/eval.md`
- `docs/spec/pov-plan.md`
- `docs/ops/monitoring.md`
- `docs/ops/governance.md`

Print a concise status report:

```
Bootstrap Status
────────────────
Step:    {step}
Status:  {status}
Type:    {type from project.json}
ADLC:    {true/false}

Answers collected:
  {list each key in answers.json with ✅ or ❌ if missing}

Generated files:
  {list each file with ✅ exists or ❌ missing}

ADLC files (if active):
  {list each ADLC file with ✅ exists or ❌ missing}

Next action:
  {what should happen next based on the current step}
```

---
name: adlc-status
description: Show the full ADLC workflow status — standard bootstrap outputs plus all ADLC-specific documents and their completion state.
agent: agent
tools: ['read']
---

Read `.project/state/workflow.json`, `.project/state/answers.json`, and `project.json`.

Then check which output files exist from the standard bootstrap list AND the ADLC-specific list:

**Standard bootstrap files:**
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

**ADLC-specific files:**
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
ADLC Status
───────────
Step:    {step}
Status:  {status}
Type:    {type from project.json}
ADLC:    {true/false}

Standard bootstrap:
  {list each standard file with ✅ exists or ❌ missing}

ADLC Phase 1 (Scope & KPIs):
  answers.json → constraints         {✅ or ❌}
  answers.json → kpis                {✅ or ❌}
  docs/analysis/kpis.md              {✅ or ❌}
  docs/analysis/human-agent-map.md   {✅ or ❌}

ADLC Phase 2 (Architecture):
  docs/domain/agent-pattern.md       {✅ or ❌}
  docs/domain/cost-model.md          {✅ or ❌}

ADLC Phase 3 (PoV):
  docs/spec/eval.md                  {✅ or ❌}
  docs/spec/pov-plan.md              {✅ or ❌}

ADLC Phase 6–7 (Ops):
  docs/ops/monitoring.md             {✅ or ❌}
  docs/ops/governance.md             {✅ or ❌}

Next action:
  {what should happen next based on the current step}
```

If `project.json → adlc` is `false`, print only the standard bootstrap status and note that ADLC is not active for this project type.

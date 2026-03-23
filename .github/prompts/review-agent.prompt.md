---
name: review-agent
description: Cross-check all ADLC documents for consistency — verifies KPIs, capabilities, thresholds, tools, and costs are aligned across all generated documents.
agent: agent
tools: ['read', 'search/codebase']
---

Read all ADLC-related documents:
- `docs/analysis/kpis.md`
- `docs/analysis/human-agent-map.md`
- `docs/analysis/capabilities.md`
- `docs/domain/agent-pattern.md`
- `docs/domain/cost-model.md`
- `docs/domain/integrations.md` (if present)
- `docs/spec/eval.md`
- `docs/spec/pov-plan.md`
- `docs/ops/monitoring.md`
- `docs/ops/governance.md`
- `.project/state/answers.json`

Check for these consistency issues:

1. **KPI → Eval coverage** — every KPI in `kpis.md` must have a corresponding metric in `eval.md`
2. **Human-agent map → Capabilities** — every task in `human-agent-map.md` must map to a capability in `capabilities.md`
3. **PoV thresholds → KPI thresholds** — go/no-go thresholds in `pov-plan.md` must match KPI thresholds in `kpis.md`
4. **Agent pattern tools → Integrations** — every tool in `agent-pattern.md` must have a corresponding entry in `integrations.md` (if present)
5. **Cost model → Model selection** — cost model must reference the model selected in `answers.json → tech` and `agent-pattern.md`
6. **Monitoring alerts → KPI thresholds** — alert thresholds in `monitoring.md` must reference KPI thresholds from `kpis.md`
7. **Governance compliance → Constraints** — every compliance requirement from `answers.json → constraints` must be addressed in `governance.md`

Report findings as:

```
Agent Review
────────────
✅ KPI → Eval coverage: all KPIs have eval metrics
❌ Human-agent map → Capabilities: "ticket routing" task has no matching capability
✅ PoV thresholds → KPI thresholds: consistent
⚠️  Agent pattern tools → Integrations: integrations.md not found, cannot verify
✅ Cost model → Model selection: consistent
❌ Monitoring alerts → KPI thresholds: accuracy alert threshold (85%) differs from KPI minimum (90%)
✅ Governance compliance → Constraints: all requirements addressed

Issues found: 2
Warnings: 1
```

List each issue with the specific document and value that is mismatched.

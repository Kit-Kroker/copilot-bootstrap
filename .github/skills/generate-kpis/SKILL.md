---
name: generate-kpis
description: Generate a KPI document with business and technical metrics, thresholds, and go/no-go criteria for agentic systems. Use this when the workflow step is "kpis" (ADLC). Reads answers.json kpis and produces docs/analysis/kpis.md.
---

# Skill Instructions

Read:
- `.project/state/answers.json` (specifically `kpis`, `constraints`, `idea`, `features`)
- `docs/analysis/prd.md`

Generate `docs/analysis/kpis.md` using this structure:

```markdown
# KPIs & Success Metrics

## Business KPIs

| Metric | Baseline (Current) | Target | Measurement Method |
|--------|-------------------|--------|-------------------|
| Cycle time reduction | {current manual time} | {target with agent} | {how to measure} |
| Task accuracy rate | N/A | {from answers.kpis} | {method} |
| Cost per outcome | {current cost} | {target cost} | {method} |
| Escalation rate | 100% (all human) | {target %} | {method} |

## Technical KPIs

| Metric | Threshold | Target | Measurement Method |
|--------|-----------|--------|-------------------|
| Hallucination rate | {max acceptable %} | {target %} | LLM-as-a-judge or human review |
| Latency p50 / p95 | {from constraints} | {target ms} | APM / tracing |
| Token cost per request | — | {estimate $} | Token counter middleware |
| Tool call success rate | {min %} | {target %} | Tool call logging |

## Quality Thresholds

| Criteria | Value | Source |
|----------|-------|--------|
| Minimum accuracy to go live | {from answers.kpis} | KPI definition |
| Maximum acceptable hallucination rate | {%} | Constraint |
| SLA for response time | {from constraints} | Constraint |

## 30-Day Success Definition

{From answers.kpis — what does success look like after 30 days in production.}

## Kill-Switch Criteria

{From answers.kpis — what would cause the agent to be rolled back or disabled.}

## Go/No-Go Gate

These thresholds are used in the PoV gate (Phase 3) and testing sign-off (Phase 5):
- If accuracy >= {threshold} AND cost per request <= {threshold} → proceed to full build
- If accuracy < {threshold} → investigate prompt / model / data quality before scaling
- If cost > {threshold} → revisit model selection or architecture before scaling
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `human_agent_map`, `status` to `in_progress`
- Tell the user what was generated and what comes next

---
name: generate-pov-plan
description: Generate a Proof of Value plan with the highest-risk assumption, PoV scope, golden dataset requirements, baseline metrics, and go/no-go gate criteria. Use this when the workflow step is "pov" (ADLC).
---

# Skill Instructions

Read:
- `docs/analysis/kpis.md`
- `docs/spec/eval.md`
- `docs/domain/agent-pattern.md`
- `.project/state/answers.json` (specifically `idea`, `features`, `constraints`)

Generate `docs/spec/pov-plan.md` using this structure:

```markdown
# Proof of Value Plan

## PoV Objective

The single highest-risk assumption to validate:

> We believe {assumption}.
> We will test this by {experiment}.
> We will consider it validated if {measurable result}.

## Scope of PoV Prototype

### Included Capabilities
{Minimum viable set to test the core assumption:}
- {capability 1 — why it must be in the PoV}
- {capability 2}

### Excluded Capabilities
{Explicitly not built for PoV:}
- {capability — why it can wait}

### Maximum Effort
- Timeboxed to: {recommended duration, e.g. 1–2 weeks}
- Team size: {recommended}

## Golden Dataset for PoV

| Attribute | Value |
|-----------|-------|
| Minimum dataset size | {50 minimum} |
| Data sources | {where inputs come from} |
| Ground truth validator | {who validates expected outputs} |
| Format | {input/output pair format} |

### Example Input/Output Pairs
| # | Input | Expected Output | Category |
|---|-------|----------------|----------|
| 1 | {sample input} | {expected output} | happy path |
| 2 | {sample input} | {expected output} | edge case |
| 3 | {sample input} | {expected output} | adversarial |

## Baseline Metrics

### Current State (Without Agent)
| Metric | Current Value | Source |
|--------|--------------|--------|
| {metric from kpis.md} | {measured baseline} | {how measured} |

### Target State (With Agent)
| Metric | Target Value | Source |
|--------|-------------|--------|
| {metric from kpis.md} | {target from kpis} | KPI definition |

### How to Measure the Difference
- {Method for A/B comparison or before/after measurement}

## Go/No-Go Gate Criteria

### Proceed to Full Build
- Accuracy >= {threshold from kpis.md}
- Cost per request <= {threshold from cost-model.md}
- Latency p95 <= {threshold from constraints}
- Hallucination rate <= {threshold from kpis.md}

### Investigate Before Scaling
- If accuracy < {threshold} → investigate prompt engineering, model selection, or data quality
- If cost > {threshold} → revisit model tiering or token reduction from cost-model.md
- If latency > {threshold} → investigate caching, model size, or architecture changes

### Stop / Pivot
- If accuracy < {hard floor, e.g. 50%} → fundamental assumption is invalid, pivot
- If {kill-switch criteria from kpis.md} → stop and reassess

## PoV Execution Checklist

- [ ] Golden dataset created and validated by domain expert
- [ ] PoV prototype built with included capabilities only
- [ ] Baseline metrics captured for current manual process
- [ ] Eval suite from eval.md configured and running
- [ ] All metrics recorded and compared against thresholds
- [ ] Go/no-go decision documented with evidence
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `monitoring`, `status` to `in_progress`
- Tell the user what was generated and what comes next

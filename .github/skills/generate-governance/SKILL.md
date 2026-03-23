---
name: generate-governance
description: Define model versioning policy, feedback loops, concept drift monitoring, knowledge base refresh, and audit log requirements. Use this when the workflow step is "governance" (ADLC).
---

# Skill Instructions

Read:
- `docs/analysis/kpis.md`
- `docs/analysis/human-agent-map.md`
- `docs/domain/agent-pattern.md`
- `.project/state/answers.json` (specifically `constraints`)

Generate `docs/ops/governance.md` using this structure:

```markdown
# Governance & Continuous Learning

## Model Versioning Policy

### When to Test a New Model Version
- Provider releases a new version of the model in use
- Performance degradation detected on current model
- Cost optimisation opportunity with a newer/cheaper model

### How to Test
1. Run full eval suite from `docs/spec/eval.md` against the new model
2. Compare metrics against current model baseline
3. Record results in eval log

### Decision Criteria
| Metric | Current Model | New Model | Decision |
|--------|--------------|-----------|----------|
| Accuracy | {baseline} | {measured} | Proceed if >= baseline |
| Latency p95 | {baseline} | {measured} | Proceed if <= baseline × 1.2 |
| Cost per request | {baseline} | {measured} | Proceed if <= baseline |
| Hallucination rate | {baseline} | {measured} | Proceed if <= baseline |

### Rollout Strategy
- Shadow mode first: run both models, compare outputs, no user impact
- Canary rollout: route {x}% of traffic to new model
- Full rollout only after {duration} of stable canary metrics

## Feedback Loop Setup

### User Feedback Collection
- **Mechanism:** {thumbs up/down, star rating, free-text feedback}
- **When collected:** {after every response / on request / periodic survey}
- **Storage:** {database / analytics platform}

### Feedback Processing
| Feedback Type | Action | Frequency |
|---------------|--------|-----------|
| Negative rating with comment | Review and categorise | Daily |
| Repeated failure pattern | Create eval case, add to golden dataset | Weekly |
| Feature request | Route to product backlog | Weekly |
| Safety concern | Immediate investigation | On occurrence |

### Feedback → Improvement Pipeline
1. Collect feedback in {storage}
2. Weekly review: categorise into {accuracy / completeness / safety / UX}
3. For accuracy issues: add input/output pair to golden dataset
4. For prompt issues: update prompt, run eval suite, deploy if improved
5. For capability gaps: route to product backlog

## Concept Drift Monitoring

### What to Watch
| Signal | Indicator | Threshold |
|--------|-----------|-----------|
| Input distribution shift | New topic categories appearing | > {x}% of inputs outside training distribution |
| Accuracy trend | Rolling 7-day accuracy | Decline > {x}% from baseline |
| Token usage trend | Average tokens per request | Increase > {x}% from baseline |
| Tool usage pattern | Tool call distribution | Significant shift from baseline |

### Response to Drift
1. Flag in monitoring dashboard
2. Investigate root cause (new user behaviour, data change, model change)
3. Update golden dataset with new examples
4. Re-run eval suite
5. Update prompts or model if needed

## Knowledge Base Refresh (for RAG-based systems)

| Attribute | Policy |
|-----------|--------|
| Refresh frequency | {daily / weekly / on-change} |
| Source of truth | {list data sources} |
| Reindexing trigger | {new documents added, schema change, scheduled} |
| Validation after refresh | {run retrieval eval, check for stale/missing docs} |
| Rollback | {keep previous index version for {duration}} |

## Audit Log Requirements

### What Must Be Logged
| Event | Fields | Retention |
|-------|--------|-----------|
| Prompt change | Who, when, diff, approval | Permanent |
| Model change | Who, when, old version, new version, eval results | Permanent |
| Tool configuration change | Who, when, tool name, change type | Permanent |
| Access control change | Who, when, role, permission | Permanent |
| Agent decision (for regulated actions) | Input, output, reasoning trace, timestamp | {from constraints — regulatory retention period} |

### Access Control for Audit Logs
- Read access: {roles from human-agent-map.md}
- Write access: system only (immutable append)
- Export: {compliance / legal team on request}

### Compliance Mapping
| Requirement (from constraints) | How Addressed |
|-------------------------------|---------------|
| {e.g. GDPR data retention} | {audit log retention + deletion policy} |
| {e.g. SOC2 change tracking} | {all config changes logged with approvals} |
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `adlc_done`, `status` to `completed`
- Update `project.json`: set `stage` to `ready`
- Tell the user: "ADLC lifecycle is complete. All documents have been generated."

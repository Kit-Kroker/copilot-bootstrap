---
name: generate-monitoring-spec
description: Define observability dashboards, alert thresholds, escalation paths, and rollback trigger criteria for agentic systems. Use this when the workflow step is "monitoring" (ADLC).
---

# Skill Instructions

Read:
- `docs/analysis/kpis.md`
- `docs/domain/agent-pattern.md`
- `.project/state/answers.json` (specifically `constraints`)

Generate `docs/ops/monitoring.md` using this structure:

```markdown
# Monitoring & Observability

## Dashboard Specification

### Primary Dashboard: Agent Health
| Panel | Metric | Source | Refresh |
|-------|--------|--------|---------|
| Request volume | requests/min | APM | 1m |
| Success rate | % of requests completing without error | APM | 1m |
| Latency p50/p95 | response time in ms | APM | 1m |
| Token usage | tokens/request (input + output) | Token counter | 5m |
| Cost tracker | $/hour, $/day running total | Token counter × pricing | 5m |
| Tool call success rate | % of tool calls succeeding | Tool call logging | 5m |
| Escalation rate | % of requests escalated to human | Agent logs | 5m |

### Quality Dashboard: Agent Accuracy
| Panel | Metric | Source | Refresh |
|-------|--------|--------|---------|
| Accuracy (sampled) | % of outputs rated correct | LLM-as-a-judge / human review | 1h |
| Hallucination rate | % of outputs with factual errors | LLM-as-a-judge | 1h |
| User satisfaction | thumbs up/down ratio | Feedback collection | 1h |
| Drift indicator | accuracy trend over 7 days | Eval pipeline | daily |

## Alert Thresholds

| Alert | Condition | Severity | Action |
|-------|-----------|----------|--------|
| High error rate | Error rate > {threshold}% for 5 min | Critical | Page oncall, investigate immediately |
| Latency spike | p95 > {threshold from constraints} for 5 min | Warning | Investigate, check model provider status |
| Cost overrun | Daily cost > {threshold}× budget | Warning | Review traffic, check for loops |
| Accuracy drop | Sampled accuracy < {threshold from kpis} | Critical | Pause agent, escalate to team lead |
| Hallucination spike | Hallucination rate > {threshold from kpis}% | Critical | Pause agent, investigate prompts |
| Tool failure | Tool call success rate < 95% for 10 min | Warning | Check external service health |
| Escalation surge | Escalation rate > {threshold}% for 1h | Warning | Review agent capabilities, check for drift |

## Escalation Paths

| Severity | Who Is Notified | Channel | Response Time |
|----------|----------------|---------|---------------|
| Critical | {oncall engineer + team lead} | {PagerDuty / Slack} | < 15 min |
| Warning | {oncall engineer} | {Slack channel} | < 1 hour |
| Info | {logged only} | {dashboard} | Next business day |

## Rollback Trigger Criteria

The agent should be automatically disabled or rolled back if:
- {kill-switch criteria from kpis.md}
- Error rate exceeds {threshold}% for more than {duration}
- Accuracy drops below {hard floor from kpis} on two consecutive eval runs
- Cost exceeds {threshold}× daily budget
- Any critical alert fires and is not resolved within {duration}

### Rollback Procedure
1. {Disable agent endpoint / switch to human fallback}
2. {Preserve logs and state for investigation}
3. {Notify stakeholders}
4. {Run full eval suite before re-enabling}

## Logging Requirements

| Log Type | What to Capture | Retention |
|----------|----------------|-----------|
| Request log | Input, output, latency, token count, model version | 90 days |
| Tool call log | Tool name, parameters, result, duration | 90 days |
| Eval log | Input, expected output, actual output, score | Permanent |
| Error log | Error type, stack trace, context | 90 days |
| Audit log | Who changed what (prompts, config, model) | Permanent |
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `governance`, `status` to `in_progress`
- Tell the user what was generated and what comes next

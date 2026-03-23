---
name: generate-eval-framework
description: Define the evaluation framework, success metrics, golden dataset spec, regression testing strategy, and tooling for agentic systems. Use this when the workflow step is "eval_framework" (ADLC).
---

# Skill Instructions

Read:
- `docs/analysis/kpis.md`
- `docs/analysis/human-agent-map.md`
- `docs/spec/api.md` (if present)
- `docs/domain/agent-pattern.md`

Generate `docs/spec/eval.md` using this structure:

```markdown
# Evaluation Framework

## Success Metrics & Thresholds

| Metric | Minimum Threshold | Target | Measurement Method |
|--------|------------------|--------|-------------------|
| {from kpis.md} | {minimum} | {target} | {method} |

## Evaluation Methods by Output Type

### Deterministic Outputs (classifications, structured data)
- **Method:** Exact match or schema validation
- **Applies to:** {list capabilities that produce structured outputs}
- **Pass criteria:** {threshold}

### Natural Language Outputs (summaries, responses, explanations)
- **Method:** LLM-as-a-judge with defined rubric
- **Rubric dimensions:**
  - Accuracy: {is the information correct?}
  - Completeness: {does it address all parts of the query?}
  - Tone: {is the tone appropriate for the context?}
  - Safety: {does it avoid harmful or inappropriate content?}
- **Applies to:** {list capabilities}
- **Pass criteria:** {score threshold on each dimension}

### Actions (tool calls)
- **Method:** Correctness of tool selection and parameter values
- **Applies to:** {list tools from agent-pattern.md}
- **Pass criteria:** Correct tool selected AND correct parameters in {threshold}% of cases

### Multi-Step Reasoning (complex workflows)
- **Method:** Trace validation — were the right tools called in the right order?
- **Applies to:** {list multi-step workflows}
- **Pass criteria:** Full trace match in {threshold}% of cases

## Golden Dataset Specification

### Size Requirements
| Phase | Minimum Examples | Purpose |
|-------|-----------------|---------|
| PoV (Phase 3) | 50 | Validate core assumption |
| Production testing (Phase 5) | 200+ | Full coverage |

### Required Input/Output Pairs
| Capability | Examples Needed | Input Type | Expected Output |
|------------|----------------|------------|-----------------|
| {capability} | {count} | {description} | {description} |

### Edge Cases & Adversarial Inputs
- {List categories of edge cases to include}
- {Adversarial input types: prompt injection, out-of-scope requests, ambiguous inputs}
- Minimum adversarial examples: {count}

### Dataset Governance
- **Created by:** {domain expert role}
- **Validated by:** {who reviews ground truth}
- **Storage:** {where the dataset lives}
- **Update frequency:** {when to refresh}

## Regression Testing Strategy

### Per Commit (Developer Speed)
- Run: {fast evals — subset of golden dataset, <2 min}
- Trigger: every prompt change, tool addition, or code change
- Blocking: {yes/no for merge}

### Pre-Release (Full Suite)
- Run: {full golden dataset + adversarial inputs}
- Trigger: before any deployment or model update
- Review: {stakeholder sign-off required?}
- Duration: {estimated time}

### On Model Update
- Run: {full eval suite + comparison against previous model}
- Compare: {metric delta thresholds for regression}
- Decision: {proceed / investigate / rollback}

## Tooling

**Recommended framework:** {RAGAS / DeepEval / Promptfoo / custom}

**Justification:** {why this tool fits the project}

**Results storage:** {where evaluation results are stored — CI artifacts, dashboard, database}

**Reporting:** {how results are surfaced — PR comments, dashboard, alerts}
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `pov`, `status` to `in_progress`
- Tell the user what was generated and what comes next

## Rules

- Every KPI from kpis.md must appear in the success metrics table
- Every capability from human-agent-map.md must have an evaluation method
- Golden dataset sizes are minimums — recommend more for critical capabilities
- Regression strategy must cover prompt changes, model updates, and tool additions

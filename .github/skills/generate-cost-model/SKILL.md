---
name: generate-cost-model
description: Estimate token economics, monthly costs at three usage tiers, cost optimisation options, and infrastructure costs. Use this when the workflow step is "cost_model" (ADLC). Reads agent-pattern.md and answers.json.
---

# Skill Instructions

Read:
- `docs/domain/agent-pattern.md`
- `.project/state/answers.json` (specifically `tech`, `features`, `constraints`)

Generate `docs/domain/cost-model.md` using this structure:

```markdown
# Cost Model

## Token Usage Per Request

| Component | Estimated Tokens | Notes |
|-----------|-----------------|-------|
| System prompt (static context) | {count} | {from agent-pattern.md} |
| User input (average) | {count} | {estimated from typical inputs} |
| Tool calls (per tool × avg calls) | {count} | {from tool inventory} |
| Output (response) | {count} | {estimated response size} |
| **Total per request** | **{total}** | |

## Monthly Cost Estimate

Using {model name} at {input price}/MTok input, {output price}/MTok output.

| Usage Level | Requests/Day | Requests/Month | Input Tokens/Mo | Output Tokens/Mo | Monthly Cost |
|-------------|-------------|----------------|-----------------|------------------|-------------|
| Low | 100 | 3,000 | {calc} | {calc} | ${calc} |
| Medium | 1,000 | 30,000 | {calc} | {calc} | ${calc} |
| High | 10,000 | 300,000 | {calc} | {calc} | ${calc} |

⚠️ {Flag if model pricing is estimated or unconfirmed.}

## Cost Optimisation Options

### Prompt Caching
- {Opportunities to cache static system prompts}
- Estimated saving: {%}

### Model Tiering
- {Use cheaper model for classification / routing steps}
- {Use primary model only for complex reasoning}
- Estimated saving: {%}

### Batching
- {Opportunities to batch requests}
- Applicable scenarios: {list}

### Token Reduction
- {Shorter prompts, summarisation of long contexts}
- {Output length limits}
- Estimated saving: {%}

## Infrastructure Costs (OPEX)

| Component | Service | Estimated Monthly Cost |
|-----------|---------|----------------------|
| Hosting / compute | {cloud provider, instance type} | ${estimate} |
| Vector database | {if RAG is used} | ${estimate} |
| External API costs | {tools from agent-pattern.md} | ${estimate} |
| Monitoring / observability | {service} | ${estimate} |
| **Total infrastructure** | | **${total}** |

## Total Monthly Cost Summary

| Usage Level | LLM Cost | Infrastructure | Total |
|-------------|----------|---------------|-------|
| Low | ${x} | ${y} | ${x+y} |
| Medium | ${x} | ${y} | ${x+y} |
| High | ${x} | ${y} | ${x+y} |
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `eval_framework`, `status` to `in_progress`
- Tell the user what was generated and what comes next

## Rules

- Use public pricing for known models; flag unknown pricing
- Be conservative — round up estimates, not down
- If agent-pattern.md recommends multiple models, cost each separately

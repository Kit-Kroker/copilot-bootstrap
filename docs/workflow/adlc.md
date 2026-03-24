# ADLC Extended Workflow

This workflow activates after the standard bootstrap completes, when `project.json → type` is `agent` or `ai-system` (i.e. `adlc = true`).

It adds the ADLC-specific phases that are missing from the standard bootstrap, covering Phases 1–7 of the Agentic Development Lifecycle.

**Approach-independent:** ADLC steps are appended after `done` regardless of whether the project uses greenfield or brownfield approach. A brownfield agent project gets both the discovery pipeline AND the ADLC extension.

## Activation Condition

```
project.json → adlc = true
project.json → type = "agent" | "ai-system"
```

## Steps

```
Standard bootstrap steps:
  1–13: idea → ... → done

ADLC extended steps (activate when adlc = true):
  14. constraints
  15. kpis
  16. human_agent_map
  17. agent_pattern
  18. cost_model
  19. eval_framework
  20. pov
  21. monitoring
  22. governance
  23. adlc_done
```

## Routing Table

| Step | Agent | Skill | Output |
|------|-------|-------|--------|
| `constraints` | bootstrap | `bootstrap-ask` | answers.json: constraints |
| `kpis` | bootstrap | `bootstrap-ask` | answers.json: kpis |
| `human_agent_map` | analyst | `generate-human-agent-map` | docs/analysis/human-agent-map.md |
| `agent_pattern` | architect | `generate-agent-pattern` | docs/domain/agent-pattern.md |
| `cost_model` | architect | `generate-cost-model` | docs/domain/cost-model.md |
| `eval_framework` | evaluator | `generate-eval-framework` | docs/spec/eval.md |
| `pov` | evaluator | `generate-pov-plan` | docs/spec/pov-plan.md |
| `monitoring` | ops | `generate-monitoring-spec` | docs/ops/monitoring.md |
| `governance` | ops | `generate-governance` | docs/ops/governance.md |
| `adlc_done` | — | — | Full lifecycle complete |

## Phase Mapping

| ADLC Phase | Steps Covered |
|------------|---------------|
| Phase 0 – Preparation & Hypotheses | `idea` (pain points), `project_info` (type routing) |
| Phase 1 – Scope Framing & Problem Definition | `constraints`, `kpis`, `prd` (agentic sections) |
| Phase 2 – Agent Definition & Architecture | `human_agent_map`, `agent_pattern`, `cost_model` |
| Phase 3 – Simulation & Proof of Value | `eval_framework`, `pov` |
| Phase 4 – Implementation & Evals | `eval_framework` (regression strategy) |
| Phase 5 – Testing | `eval_framework` (golden dataset, tooling) |
| Phase 6 – Agent Activation & Deployment | `monitoring` |
| Phase 7 – Continuous Learning & Governance | `governance` |

## Decision Loop

Same as the standard bootstrap decision loop (see `docs/workflow/agents.md`), extended for ADLC steps:

1. Read workflow.json → current step + status
2. Look up step in ADLC routing table → agent + skill
3. Check answers.json → if data missing for step, run bootstrap-ask first
4. Run the skill for the current step
5. Save outputs to the correct file
6. Run workflow-update → advance to next step
7. Report what was done and what comes next

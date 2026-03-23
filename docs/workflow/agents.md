# Agent Routing Table

## Agents

| Agent | Responsibility | Skills |
|-------|---------------|--------|
| **bootstrap** | Collect project answers, drive step transitions | `bootstrap-ask`, `bootstrap-next`, `workflow-read`, `workflow-update` |
| **analyst** | Generate analysis documents from answers | `generate-prd`, `generate-capabilities`, `generate-kpis`, `generate-human-agent-map` |
| **architect** | Generate domain model, RBAC, and workflows | `generate-domain`, `generate-rbac`, `generate-workflows`, `generate-agent-pattern`, `generate-cost-model` |
| **designer** | Generate design workflow, IA, and user flows | `generate-design-workflow`, `generate-ia`, `generate-flows` |
| **spec** | Generate implementation specification | `generate-spec` |
| **evaluator** | Generate eval framework and PoV plan (ADLC) | `generate-eval-framework`, `generate-pov-plan` |
| **script** | Generate automation scripts | `generate-scripts` |
| **ops** | Generate monitoring and governance docs (ADLC) | `generate-monitoring-spec`, `generate-governance` |
| **dev** | Code generation (post-bootstrap) | *(defined per project)* |

---

## Bootstrap Workflow Routing

| Step | Agent | Skill | Output |
|------|-------|-------|--------|
| `idea` | bootstrap | `bootstrap-ask` | answers.json: idea, pain_points |
| `project_info` | bootstrap | `bootstrap-ask` | answers.json: project_info |
| `users` | bootstrap | `bootstrap-ask` | answers.json: users |
| `features` | bootstrap | `bootstrap-ask` | answers.json: features |
| `tech` | bootstrap | `bootstrap-ask` | answers.json: tech |
| `complexity` | bootstrap | `bootstrap-ask` | answers.json: complexity, autonomy_level |
| `prd` | analyst | `generate-prd` | docs/analysis/prd.md |
| `capabilities` | analyst | `generate-capabilities` | docs/analysis/capabilities.md |
| `domain` | architect | `generate-domain` | docs/domain/model.md |
| `design_workflow` | designer | `generate-design-workflow` | docs/workflow/design.md, docs/design/overview.md |
| `skills` | script | `generate-skills` | .github/skills/ (dev skills) |
| `scripts` | script | `generate-scripts` | scripts/*.sh |
| `done` | — | — | Bootstrap complete |

---

## Design Workflow Routing

Entered from bootstrap step `design_workflow`. Runs as a sub-workflow.

| Step | Agent | Skill | Output |
|------|-------|-------|--------|
| `capabilities` | analyst | `generate-capabilities` | docs/analysis/capabilities.md |
| `domain` | architect | `generate-domain` | docs/domain/model.md |
| `rbac` | architect | `generate-rbac` | docs/domain/rbac.md |
| `workflow` | architect | `generate-workflows` | docs/domain/workflows.md |
| `integration` | architect | *(define integrations)* | docs/domain/integrations.md |
| `metrics` | analyst | *(define metrics)* | docs/analysis/metrics.md |
| `ia` | designer | `generate-ia` | docs/design/ia.md |
| `flows` | designer | `generate-flows` | docs/design/flows.md |
| `stitch` | designer | `generate-stitch-screens` | docs/design/screens/*.html |
| `ux` | designer | *(generate ux)* | docs/design/ux.md |
| `design-system` | designer | *(generate design-system)* | docs/design/design-system.md |
| `spec` | spec | `generate-spec` | docs/spec/*.md |

---

## ADLC Extended Workflow Routing (active when adlc = true)

When `project.json → type` is `agent` or `ai-system`, these steps activate after the standard bootstrap completes.

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

---

## Decision Loop

```
1. Read workflow.json → current step + status
2. Look up step in routing table → agent + skill
3. Check answers.json → if data missing for step, run bootstrap-ask first
4. Run the skill for the current step
5. Save outputs to the correct file
6. Run workflow-update → advance to next step
7. Report what was done and what comes next
```

## Rules

- Never skip a step
- Never run two steps in one turn without explicit user confirmation
- Always update workflow.json after a step completes
- If a required input file is missing, report which step must run first
- If a step produces no output (data insufficient), run bootstrap-ask and stay on step
- When `adlc = true`, ADLC steps are mandatory — do not skip them

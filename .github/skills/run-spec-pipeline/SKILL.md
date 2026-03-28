---
name: run-spec-pipeline
description: Run the full greenfield spec pipeline automatically without manual next commands. Executes all spec generation steps in sequence (PRD → capabilities → domain → RBAC → workflows → design → IA → flows → spec → skills → scripts), skipping steps whose output already exists. Use this after build-context when approach is greenfield.
user-invocable: false
---

# Skill Instructions

Run the full greenfield spec generation pipeline automatically.
Do NOT wait for user confirmation between steps unless a step requires interactive input.

## Pre-flight

1. Verify `project.json → approach = "greenfield"`.
2. Read `.greenfield/context.json` and `.greenfield/scope.json`. If either is missing, stop and tell the user to run `/build-context` (or `copilot-bootstrap build-context`) first.
3. Check if `.greenfield/pipeline.lock.json` already exists.
   - If it exists, read it and resume from the first non-completed step.
   - If it does not exist, tell the user to run `/spec` (or `copilot-bootstrap spec`) first to initialize the pipeline, then stop.
4. Read `.greenfield/pipeline.lock.json` to identify which steps are pending.
5. Read `project.json → adlc` to determine if ADLC steps should run.

Say: "Running greenfield spec pipeline..."

## Pipeline Execution

Execute each step listed in the table below, in order, from top to bottom.

For each step:
1. Read `.greenfield/pipeline.lock.json`. If the step status is `"completed"` or `"skipped"`, print `"  ✔ {display label} already exists — skipping"` and move to the next step immediately.
2. Mark the step as `"in_progress"` in `.greenfield/pipeline.lock.json`.
3. Run the corresponding skill listed in the table.
4. On success:
   - Mark the step as `"completed"` in `.greenfield/pipeline.lock.json` with `completed_at` set to the current UTC timestamp.
   - Print `"  ✔ {display label}"` with counts extracted from the generated output where possible.
   - Continue immediately to the next step — do NOT call `bootstrap-next` or wait for user input.
5. On failure:
   - Mark the step as `"failed"` in `.greenfield/pipeline.lock.json` with an `error` field describing what went wrong.
   - Print `"  ✗ {display label} — {error summary}"`.
   - STOP. Do not continue to the next step.
   - Tell the user what failed and how to fix it, then re-run this skill to resume.

### Standard Steps

| Step | Skill | Output | Display Label |
|------|-------|--------|---------------|
| `generate_prd` | `generate-prd` | `docs/analysis/prd.md` | PRD generated |
| `generate_capabilities` | `generate-capabilities` | `docs/analysis/capabilities.md` | Capability map generated |
| `generate_domain` | `generate-domain` | `docs/domain/model.md` | Domain model generated |
| `generate_rbac` | `generate-rbac` | `docs/domain/rbac.md` | RBAC policy generated |
| `generate_workflows` | `generate-workflows` | `docs/domain/workflows.md` | Workflows generated |
| `generate_design_workflow` | `generate-design-workflow` | `docs/design/overview.md` | Design overview generated |
| `generate_ia` | `generate-ia` | `docs/design/ia.md` | Information architecture generated |
| `generate_flows` | `generate-flows` | `docs/design/flows.md` | User flows generated |
| `generate_spec` | `generate-spec` | `docs/spec/api.md` | API spec generated |
| `generate_skills` | `generate-skills` | `.github/skills/` | Dev skills generated |
| `generate_scripts` | `generate-scripts` | `scripts/` | Operational scripts generated |

### ADLC Steps (only when `project.json → adlc = true`)

Run these steps after all standard steps complete.

| Step | Skill | Output | Display Label |
|------|-------|--------|---------------|
| `generate_kpis` | `generate-kpis` | `docs/adlc/kpis.md` | KPIs generated |
| `generate_human_agent_map` | `generate-human-agent-map` | `docs/adlc/human-agent-map.md` | Human-agent map generated |
| `generate_agent_pattern` | `generate-agent-pattern` | `docs/adlc/agent-pattern.md` | Agent pattern generated |
| `generate_cost_model` | `generate-cost-model` | `docs/adlc/cost-model.md` | Cost model generated |
| `generate_eval_framework` | `generate-eval-framework` | `docs/adlc/eval-framework.md` | Evaluation framework generated |
| `generate_pov` | `generate-pov-plan` | `docs/adlc/pov-plan.md` | PoV plan generated |
| `generate_monitoring` | `generate-monitoring-spec` | `docs/adlc/monitoring.md` | Monitoring spec generated |
| `generate_governance` | `generate-governance` | `docs/adlc/governance.md` | Governance spec generated |

## Updating the Lock File

After each state change, edit `.greenfield/pipeline.lock.json` directly.

Mark in_progress:
```json
{ "status": "in_progress", "output": "docs/analysis/prd.md" }
```

Mark completed:
```json
{ "status": "completed", "output": "docs/analysis/prd.md", "completed_at": "{ISO timestamp}" }
```

Mark failed:
```json
{ "status": "failed", "output": "docs/analysis/prd.md", "error": "{error description}" }
```

## Progress Display

Use this format when printing step results:

```
Running greenfield spec pipeline...
  ✔ PRD generated (12 requirements, 3 constraints)
  ✔ Capability map generated (15 capabilities, 8 dependencies)
  ✔ Domain model generated (8 entities, 4 aggregates)
  ✔ RBAC policy generated (3 roles, 24 permissions)
  ✔ Workflows generated (6 workflows)
  ✔ Design overview generated
  ✔ Information architecture generated (14 screens)
  ✔ User flows generated (9 flows)
  ✔ API spec generated (32 endpoints)
  ✔ Dev skills generated (8 skills)
  ✔ Operational scripts generated (6 scripts)
```

Extract counts from the generated output where easily available (entity count from domain model, endpoint count from API spec, etc.). If counts are not available, omit them — the label alone is sufficient.

## Interactive Fallback

If any step reveals ambiguous information that requires user clarification:
- Ask the question directly in the chat
- Wait for the user's response
- Incorporate the answer and continue with the pipeline
- Do NOT abandon the pipeline on interactive prompts

Examples of when to ask:
- A feature's scope is ambiguous and affects domain boundaries
- RBAC roles conflict or overlap in a way that needs a design decision
- API resource naming is unclear due to domain terminology

## After All Steps Complete

1. Update `.project/state/workflow.json`:
   ```json
   { "step": "done", "status": "completed" }
   ```
2. Update `project.json → step` to `"done"`.
3. Record the elapsed time and print the completion summary:

```
Spec pipeline finished in {elapsed}.

  ✔ PRD generated
  ✔ Capability map generated
  ✔ Domain model generated
  ✔ RBAC policy generated
  ✔ Workflows generated
  ✔ Design overview generated
  ✔ Information architecture generated
  ✔ User flows generated
  ✔ API spec generated
  ✔ Dev skills generated
  ✔ Operational scripts generated

{N} artifacts generated in docs/. Ready for runtime generator.
```

4. Tell the user: "Run `copilot-bootstrap generate` to produce project-specific Copilot configuration."

## Rules

- Read pipeline.lock.json before starting to resume from the first non-completed step
- Never re-run a step that is `"completed"` or `"skipped"`
- Stop immediately on failure — log the error, update the lock, do not continue
- Update pipeline.lock.json after every state change (in_progress → completed or failed)
- Do not call `bootstrap-next` between steps — this skill manages workflow state directly
- Do not modify `.greenfield/context.json` or `.greenfield/scope.json` — they are read-only inputs
- ADLC steps run only when `project.json → adlc = true`

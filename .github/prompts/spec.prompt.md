---
name: spec
description: Initialize the greenfield spec pipeline and run it automatically. Creates pipeline.lock.json (skipping steps whose outputs already exist), then runs all spec generation steps in sequence. Run after build-context.
tools: ['read', 'edit']
---

Initialize and run the greenfield spec pipeline.

## Pre-flight

1. Read `project.json`. If it doesn't exist: "project.json not found. Run `/init` first."
2. If `approach` is not `"greenfield"`: "Spec pipeline requires greenfield approach. Current: {approach}. For brownfield, use `/discover`."
3. Check `.greenfield/context.json` exists. If not: "context.json not found. Run `/build-context` first."
4. Read `project.json → adlc`.

## Initialize or resume lock file

Check if `.greenfield/pipeline.lock.json` exists.

**If it does not exist**, create it now with all steps set to `"pending"`.

Standard steps (always include):
```json
{
  "version": "1",
  "started_at": "<current UTC timestamp as YYYY-MM-DDTHH:MM:SSZ>",
  "steps": {
    "generate_prd":             {"status": "pending", "output": "docs/analysis/prd.md"},
    "generate_capabilities":    {"status": "pending", "output": "docs/analysis/capabilities.md"},
    "generate_domain":          {"status": "pending", "output": "docs/domain/model.md"},
    "generate_rbac":            {"status": "pending", "output": "docs/domain/rbac.md"},
    "generate_workflows":       {"status": "pending", "output": "docs/domain/workflows.md"},
    "generate_design_workflow": {"status": "pending", "output": "docs/design/overview.md"},
    "generate_ia":              {"status": "pending", "output": "docs/design/ia.md"},
    "generate_flows":           {"status": "pending", "output": "docs/design/flows.md"},
    "generate_spec":            {"status": "pending", "output": "docs/spec/api.md"},
    "generate_skills":          {"status": "pending", "output": ".github/skills/"},
    "generate_scripts":         {"status": "pending", "output": "scripts/"}
  }
}
```

If `adlc = true`, also add these steps inside `"steps"`:
```json
"generate_kpis":            {"status": "pending", "output": "docs/adlc/kpis.md"},
"generate_human_agent_map": {"status": "pending", "output": "docs/adlc/human-agent-map.md"},
"generate_agent_pattern":   {"status": "pending", "output": "docs/adlc/agent-pattern.md"},
"generate_cost_model":      {"status": "pending", "output": "docs/adlc/cost-model.md"},
"generate_eval_framework":  {"status": "pending", "output": "docs/adlc/eval-framework.md"},
"generate_pov":             {"status": "pending", "output": "docs/adlc/pov-plan.md"},
"generate_monitoring":      {"status": "pending", "output": "docs/adlc/monitoring.md"},
"generate_governance":      {"status": "pending", "output": "docs/adlc/governance.md"}
```

**If the lock file already exists**, read it and say "Resuming spec pipeline (started {started_at})..."

## Apply skip-if-exists

For each step whose output file already exists and is non-empty, update its status to `"skipped"` in the lock file before running the pipeline.

## Run the pipeline

Immediately use the `run-spec-pipeline` skill to execute all pending steps in sequence.
Do NOT wait for user confirmation before starting.

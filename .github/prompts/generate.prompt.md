---
name: generate
description: Generate project-specific Copilot configuration for the brownfield project — tailored copilot-instructions.md, dev skills, prompts, and hooks based on the detected stack and discovered domain. Run after /discover completes.
tools: ['read', 'edit']
---

Initialize and run the brownfield Copilot configuration generation pipeline.

## Pre-flight

1. Read `project.json`. If it doesn't exist: "project.json not found. Run `/init` first."
2. If `approach` is not `"brownfield"`: "Generate requires brownfield approach. Current: {approach}. For greenfield, use `/spec`."
3. Check `.discovery/context.json` exists. If not: "context.json not found. Run `/scan` first."
4. Check that `docs/discovery/l1-capabilities.md` exists. If not: "Discovery outputs not found. Run `/discover` first."

## Initialize or resume lock file

Check if `.discovery/generate.lock.json` exists.

**If it does not exist**, create it now:

```json
{
  "version": "1",
  "started_at": "<current UTC timestamp as YYYY-MM-DDTHH:MM:SSZ>",
  "steps": {
    "generate_instructions":   {"status": "pending", "output": ".github/copilot-instructions.md"},
    "generate_dev_skills":     {"status": "pending", "output": ".github/skills/"},
    "generate_dev_prompts":    {"status": "pending", "output": ".github/prompts/"},
    "generate_hooks":          {"status": "pending", "output": ".vscode/settings.json"},
    "generate_project_agent":  {"status": "pending", "output": ".github/agents/project.agent.md"}
  }
}
```

**If the lock file already exists**, read it and say "Resuming generate pipeline (started {started_at})..."

## Run the pipeline

Immediately use the `run-generate-pipeline` skill to execute all pending steps in sequence.
Do NOT wait for user confirmation before starting.

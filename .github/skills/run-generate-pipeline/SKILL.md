---
name: run-generate-pipeline
description: Run the brownfield Copilot configuration generation pipeline automatically. Generates copilot-instructions.md, project-specific dev skills, prompts, and hooks tailored to the detected stack and discovered domain. Use after /discover completes.
user-invocable: true
---

# Skill Instructions

Run the brownfield Copilot configuration generation pipeline automatically.
Do NOT wait for user confirmation between steps.

## Inputs (read before starting)

- `.discovery/context.json` — stack, tools, architecture detected by `/scan`
- `docs/discovery/l1-capabilities.md` — L1 capabilities from `/discover`
- `docs/discovery/l2-capabilities.md` — L2 sub-capabilities
- `docs/discovery/domain-model.md` — domain model with entity ownership and code locations
- `docs/discovery/blueprint-comparison.md` — industry alignment (if present)
- `project.json` — project name, type, domain

## Pre-flight

1. Verify `project.json → approach = "brownfield"`.
2. Read `.discovery/context.json`. If missing, stop: "Run `/scan` first."
3. Read `docs/discovery/l1-capabilities.md`. If missing, stop: "Run `/discover` first."
4. Check if `.discovery/generate.lock.json` already exists.
   - If it exists, read it and resume from the first non-completed step.
   - If it does not exist, stop: "Run `/generate` first to initialize the pipeline."
5. Read `.discovery/generate.lock.json` to identify which steps are pending.

Say: "Generating Copilot configuration for brownfield project..."

## Pipeline Execution

Execute each step in order. For each step:
1. Read `.discovery/generate.lock.json`. If status is `"completed"` or `"skipped"`, print `"  ✔ {label} — skipping"` and move on.
2. Mark the step `"in_progress"` in the lock file.
3. Run the corresponding skill.
4. On success: mark `"completed"` with `completed_at`, print `"  ✔ {label}"`, continue immediately.
5. On failure: mark `"failed"` with `error`, print `"  ✗ {label} — {error}"`, STOP.

| Step | Skill | Output | Display Label |
|------|-------|--------|---------------|
| `generate_instructions` | `generate-copilot-instructions` | `.github/copilot-instructions.md` | Copilot instructions generated |
| `generate_dev_skills` | `generate-brownfield-skills` | `.github/skills/` | Dev skills generated |
| `generate_dev_prompts` | `generate-brownfield-prompts` | `.github/prompts/` | Project prompts generated |
| `generate_hooks` | `generate-brownfield-hooks` | `.vscode/settings.json` | VS Code workspace settings configured |
| `generate_project_agent` | `generate-project-agent` | `.github/agents/project.agent.md` | Project agent generated |

## Updating the Lock File

After each state change, edit `.discovery/generate.lock.json` directly.

```json
{ "status": "in_progress" }
{ "status": "completed", "output": "<path>", "completed_at": "<ISO timestamp>" }
{ "status": "failed", "output": "<path>", "error": "<description>" }
```

## After All Steps Complete

1. Update `.project/state/workflow.json → step` to `"done"`, `status` to `"completed"`.
2. Update `project.json → step` to `"done"`.
3. Print:

```
Copilot configuration generated.

  ✔ .github/copilot-instructions.md
  ✔ .github/skills/   ({N} skills)
  ✔ .github/prompts/  ({N} prompts)
  ✔ .vscode/settings.json (workspace settings: format-on-save, linter)
  ✔ .github/agents/project.agent.md

Your Copilot setup is ready. Select the {project name} agent in chat to start developing.
Run /finish to remove bootstrap scaffolding and leave only project-specific files.
```

## Rules

- Never re-run a step that is `"completed"` or `"skipped"`
- Stop immediately on failure — log the error, update the lock, do not continue
- Do not modify discovery outputs — they are read-only inputs
- All generated artifacts must reflect the actual detected stack and discovered domain, not generic templates

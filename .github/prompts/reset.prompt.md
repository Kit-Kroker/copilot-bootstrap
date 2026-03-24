---
name: reset
description: Reset the bootstrap workflow to a specific step. Useful for re-running a step after editing answers.
agent: agent
tools: ['read', 'edit']
argument-hint: "<step-name> — e.g. prd, domain, spec"
---

The user wants to reset the workflow to step: `${input:step:step name e.g. prd, domain, spec}`.

1. Read `project.json` to check the `approach` field.
   - If `approach = "brownfield"`, read `docs/workflow/brownfield.md` to get valid step names.
   - Otherwise, read `docs/workflow/bootstrap.md` to get valid step names.
   Confirm `${input:step}` is a valid step name. If not valid, list the valid steps and stop.

2. Update `.project/state/workflow.json`:
```json
{
  "workflow": "bootstrap",
  "step": "${input:step}",
  "status": "in_progress"
}
```

3. Update `project.json` field `step` to `${input:step}`.

4. Report:
```
Reset complete.
Current step: ${input:step} (in_progress)

Note: existing output files for this step and later steps are NOT deleted.
To regenerate, open the relevant agent and run the step again.
```

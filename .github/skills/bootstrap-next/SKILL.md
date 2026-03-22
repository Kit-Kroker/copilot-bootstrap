---
name: bootstrap-next
description: Advance the bootstrap workflow to the next step. Use this after all required answers for the current step are collected and saved. Updates workflow.json and project.json.
user-invocable: false
---

# Skill Instructions

Read `docs/workflow/bootstrap.md` to get the ordered list of steps.
Read `.project/state/workflow.json` to find the current step.

Find the next step in the sequence.

Update `.project/state/workflow.json`:
- Set `step` to the next step name
- Set `status` to `in_progress`

Also update `project.json` `step` field to match.

If the current step is `done`, do nothing and report that the workflow is complete.

---
name: workflow-update
description: Update the bootstrap workflow state after completing a step. Writes the new step name and status to workflow.json and project.json. Use this after every step transition.
user-invocable: false
---

# Skill Instructions

Update `.project/state/workflow.json` with the new step and status.

Fields to update:
- `step`: the new current step name
- `status`: one of `in_progress`, `completed`, `blocked`

Also update `project.json` `step` field to match.

Example result:

```json
{
  "workflow": "bootstrap",
  "step": "project_info",
  "status": "in_progress"
}
```

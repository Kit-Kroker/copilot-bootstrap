---
name: workflow-read
description: Read and return the current bootstrap workflow step and status. Use this at the start of every interaction to determine what the agent should do next. Never modifies any files.
user-invocable: false
---

# Skill Instructions

Read `.project/state/workflow.json`.

Return:
- current `step`
- current `status`

Do not modify any files.

---
name: bootstrap
description: Start or resume the bootstrap workflow. Reads current state and routes to the correct agent for the active step.
agent: Bootstrap
argument-hint: "idea: <your project idea> — or leave blank to resume"
---

Read `.project/state/workflow.json` to get the current step.

If the user provided an idea (e.g. "idea: helpdesk system"), save it to `.project/state/answers.json` under the key `idea` and set the step to `project_info`.

Then continue with the Bootstrap agent workflow from the current step.

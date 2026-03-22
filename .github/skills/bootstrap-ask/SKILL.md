---
name: bootstrap-ask
description: Ask the user only the missing questions for the current bootstrap workflow step and save their answers to answers.json. Use this when data for the current step is incomplete.
argument-hint: "[step name to ask about, or leave blank to use current step]"
---

# Skill Instructions

Read `.project/state/workflow.json` to find the current step.
Read `.project/state/answers.json` to see what is already answered.

Ask the user only the questions that are missing for the current step.

## Questions by Step

### idea
- What is your project idea? Describe it in a few sentences.

### project_info
- What is the project name?
- What type of project is it? (web app / mobile app / API / CLI / other)
- What domain does it belong to? (for example: healthcare, finance, education, logistics)

### users
- Who are the users of this system?
- What roles do they have? (for example: admin, manager, end-user, guest)

### features
- What are the core features of the system?
- List 3 to 10 key features.

### tech
- What backend technology will you use? (for example: Node.js, Python, Go, Java)
- What frontend technology will you use? (for example: React, Vue, Angular, none)
- Any specific databases or infrastructure preferences?

### complexity
- How complex is this project?
  - simple: single team, no integrations
  - saas: multi-tenant, subscriptions, external integrations
  - enterprise: large org, RBAC, compliance, many integrations

After collecting answers, save them to `.project/state/answers.json` under the step name key.

Example:

```json
{
  "idea": "A helpdesk system for managing customer support tickets",
  "project_info": {
    "name": "HelpDesk Pro",
    "type": "web app",
    "domain": "customer support"
  }
}
```

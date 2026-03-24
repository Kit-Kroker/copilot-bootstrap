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
- What specific work, decision, or process is currently manual, slow, or error-prone?
- Why is a human doing this today — what would need to be true for a machine to do it reliably?

Save the last two answers under `pain_points` in answers.json alongside `idea`.

### project_info
- What is the project name?
- What type of project is it? Valid types:
  - `web-app` — traditional UI-driven application
  - `mobile` — native or hybrid mobile application
  - `api` — headless API service or backend
  - `cli` — command-line tool
  - `agent` — single LLM-driven agent with tool use
  - `ai-system` — multi-agent or LLM-core product
- What domain does it belong to? (for example: healthcare, finance, education, logistics)
- Is this a new project or modernization of an existing system?
  - `greenfield` — building from scratch, no existing codebase
  - `brownfield` — analyzing and modernizing an existing codebase

Save approach to `answers.json → project_info.approach`. Also update `project.json → approach` and `.project/state/workflow.json → approach`.

When `approach` is `brownfield`, the workflow switches to `docs/workflow/brownfield.md` after `project_info`. The next step becomes `codebase_setup` instead of `users`.

### codebase_setup
*(Only active when `approach = brownfield`)*

Before asking questions, check if `.discovery/context.json` and `.discovery/confidence.json` exist.

**If `.discovery/context.json` exists** (scan was already run):

Read both files. For each question below, apply the confidence threshold:
- Score ≥ 0.75: use the detected value as the answer — **skip the question entirely**
- Score 0.50–0.74: show the detected value and ask the user to confirm or correct
- Score < 0.50 or field missing: ask the question normally

**If `.discovery/context.json` does not exist** (no scan run yet):

Suggest running the scan first: "I can auto-detect the stack before asking questions. Run `copilot-bootstrap scan` first, or I can ask you directly. Which do you prefer?"

If the user prefers to continue without scanning, ask all questions as normal.

---

**Questions (ask only what wasn't auto-detected with high confidence):**

1. What is the path to the existing codebase? (absolute path or relative to workspace root)
   - Detected from: `project.json → codebase_path` (set during project_info)

2. What is the primary programming language? (e.g. Java, C#, Python, TypeScript, Go)
   - Detected from: `.discovery/context.json → stack.languages`
   - Confidence: `.discovery/confidence.json → language`

3. What is the architecture style?
   - `monolith` — single deployable unit
   - `modular-monolith` — single deployment but internally modular
   - `microservices` — multiple independently deployable services
   - Detected from: `.discovery/context.json → arch.style`
   - Confidence: `.discovery/confidence.json → architecture`

4. Are database schemas or migrations available? If yes, provide the path or describe how to access them.
   - Detected DB engine from: `.discovery/context.json → stack.db`
   - Confidence: `.discovery/confidence.json → db`
   - This question is always asked for schema/migration paths (not auto-detected)

5. Are there any pre-generated analysis reports to include? (e.g. nDepend exports, JetBrains dependency analysis, SonarQube reports, architecture diagrams). If yes, provide paths.
   - Always ask — cannot be auto-detected

6. Is there a frontend layer? (yes/no — if no, frontend entry point analysis will be skipped)
   - Detected from: `.discovery/context.json → stack.frontend` (non-null means yes)
   - Confidence: `.discovery/confidence.json → frontend`

---

**After collecting answers:**

Save to `answers.json → codebase_setup`. Also update `project.json → codebase_path` with the codebase path.

If the user corrected any auto-detected values, update `.discovery/context.json` with the corrections and set the corresponding confidence scores to `1.0` in `.discovery/confidence.json`.

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

If `type` is `agent` or `ai-system`, also ask:
- What is the autonomy level of this agent?
  - `reactive` — responds to requests, no background action
  - `assistive` — takes actions on user request within a defined scope
  - `autonomous` — initiates tasks, makes decisions, acts without per-request approval

Save autonomy level to `answers.json → autonomy_level`. Also update `project.json → autonomy_level`.

When `type` is `agent` or `ai-system`, set `project.json → adlc` to `true`. This activates the ADLC extended workflow after the standard bootstrap completes.

### constraints
*(Only active when `adlc = true` in project.json)*

1. Are there regulatory or compliance requirements this agent must satisfy?
   (e.g. GDPR, HIPAA, SOC2, PCI-DSS, internal audit policies)

2. What is the maximum acceptable error rate for this agent's decisions?
   (e.g. "less than 2% of ticket classifications wrong")

3. List the actions this agent must NEVER take without explicit human approval.
   (e.g. "never send an email to a customer", "never delete records", "never escalate to a manager")

4. What is the acceptable latency for a response? (e.g. under 3 seconds for UI-facing, under 30 seconds for async)

5. Is there an existing data source this agent will read from? What is its quality and governance status?

Save to `answers.json → constraints`.

### kpis
*(Only active when `adlc = true` in project.json)*

1. What is the primary business metric this agent will improve?
   (e.g. "reduce average handle time from 8 minutes to 3 minutes")

2. What does success look like after 30 days in production?
   (quantified, measurable)

3. What is the minimum accuracy threshold below which the agent should not be used?
   (e.g. "must classify requests correctly at least 90% of the time")

4. What would cause the agent to be rolled back or disabled?
   (your kill-switch criteria)

Save to `answers.json → kpis`.

## Saving Answers

After collecting answers, save them to `.project/state/answers.json` under the step name key.

Example:

```json
{
  "idea": "A helpdesk system for managing customer support tickets",
  "pain_points": {
    "manual_process": "Triaging tickets is manual — agents spend 3 minutes per ticket reading and classifying",
    "why_human": "Classification requires reading free-text descriptions; a human does it because there was no ML model in place"
  },
  "project_info": {
    "name": "HelpDesk Pro",
    "type": "agent",
    "domain": "customer support"
  }
}
```

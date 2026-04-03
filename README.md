# copilot-bootstrap

A structured workflow that takes a project idea — or an existing codebase — and produces a complete, implementation-ready specification through a chain of GitHub Copilot agents in VS Code.

---

## What is this

copilot-bootstrap is a **specification generator driven by Copilot agents**. You describe a project, answer a short series of targeted questions, and a pipeline of specialized agents produces every document you need before writing a line of code: PRD, domain model, RBAC policy, API spec, design flows, and dev scaffolding.

For **existing codebases**, a 7-step discovery pipeline reads your source tree and extracts the business capability map before generating any documents — so the output reflects what the code actually does, not what you think it does.

For **agent and AI system projects**, the workflow extends with the Agentic Development Lifecycle (ADLC): KPI thresholds, human-agent responsibility mapping, agent architecture patterns, evaluation frameworks, Proof of Value plans, monitoring specs, and governance policies.

---

## Why it exists

Starting a project with Copilot usually means free-form conversation: you describe something, get code back, and figure out the architecture as you go. That works for small things. For anything with multiple users, domain complexity, or a team, the lack of upfront structure creates waste — inconsistent naming, missing permissions, no evaluation plan for the AI parts.

copilot-bootstrap front-loads the thinking. It produces a consistent set of documents that developers, designers, and stakeholders can review before implementation starts. When you hand these to Copilot for actual coding, it has context: the domain model, the RBAC rules, the API contracts. The generated code is more coherent from the start.

For brownfield projects the problem is different: you have a codebase but no clear map of what it does. The discovery pipeline produces that map as a structured artifact, not a vague summary.

---

## When to use

| Situation | Good fit? |
|-----------|-----------|
| New app with 3+ user roles or any RBAC | Yes |
| New agent or AI-powered system | Yes — ADLC workflow activates |
| Existing codebase you need to understand, document, or modernize | Yes — brownfield mode |
| Quick prototype, solo, no team coordination | Probably overkill |
| Adding a feature to an existing well-documented project | Overkill |

---

## Install

```sh
uv tool install copilot-bootstrap --from git+https://github.com/Kit-Kroker/copilot-bootstrap.git
```

**Requirements:** `uv`, `jq`, VS Code with GitHub Copilot

---

## Quick start

### Greenfield — new project from scratch

```sh
mkdir my-project && cd my-project
copilot-bootstrap init   # copies framework files (.github/, docs/workflow/) to your project
code .
```

Everything after this is in Copilot Chat:

```
/bootstrap idea: freelancer invoicing tool
```

Answer 6 questions conversationally (idea, project info, users, features, tech, complexity), then:

```
/build-context   — derives context.json, decisions.json, scope.json from your answers
/spec            — creates the pipeline lock and runs all spec generation steps automatically
```

When the pipeline finishes, run the generator once:

```sh
copilot-bootstrap generate
```

### Brownfield — existing codebase

```sh
cd /path/to/existing-project
copilot-bootstrap init
code .
```

In Copilot Chat:

```
/init            — initialize project state as brownfield
/scan            — detect language, framework, database, tools, architecture
/discover        — run all 7 capability extraction steps automatically
/generate        — generate Copilot configuration tailored to this stack and domain
/finish          — remove bootstrap scaffolding, keeping only the project agent and generated config
```

---

## Example workflow

Here is an abbreviated session for a SaaS freelancer invoicing tool.

**Step 1 — Interview**

In Copilot Chat:

```
/bootstrap idea: freelancer invoicing tool
```

The Bootstrap agent collects answers across 6 steps: idea, project info, user roles, features, tech stack, complexity. Smart defaults are applied automatically — pick React and get Vite + ESLint + Prettier + Vitest without being asked.

**Step 2 — Build context**

```
/build-context
```

Produces three files from your answers:
- `.greenfield/context.json` — unified stack and toolchain
- `.greenfield/decisions.json` — why each choice was made (user/default/derived)
- `.greenfield/scope.json` — features, users, complexity

**Step 3 — Run spec pipeline**

```
/spec
```

Creates `.greenfield/pipeline.lock.json` and immediately runs the full pipeline:

```
Analyst     → docs/analysis/prd.md, docs/analysis/capabilities.md
Architect   → docs/domain/model.md, docs/domain/rbac.md, docs/domain/workflows.md
Designer    → docs/design/overview.md, docs/design/ia.md, docs/design/flows.md
Spec        → docs/spec/api.md
Script      → .github/skills/ (dev scaffolding skills)
```

**Step 4 — Run generator**

When `/spec` finishes, run:

```sh
copilot-bootstrap generate
```

This produces project-specific Copilot config tailored to your chosen stack:

```
.github/copilot-instructions.md         project-wide context
.github/instructions/                   language + framework + architecture + decisions
.github/agents/                         backend, frontend, test, refactor, devops, scaffold
.github/skills/                         build, test, lint, format, deploy
.github/prompts/                        /new-feature, /fix-bug, /write-tests, /review-pr,
                                        /scaffold-project, /implement-feature
.vscode/mcp.json                        MCP server config
.github/docs/getting-started.md         onboarding guide for this project
```

**Step 5 — Start building**

```
/scaffold-project      # set up the initial project structure
/implement-feature     # implement a feature from the capability map
```

Or use the scaffold agent: `@scaffold Set up the craft-market project from specs`

---

## Example project

**Project:** `invoiceflow` — SaaS invoicing for freelancers
**Type:** `web-app`, **Domain:** `finance`, **Complexity:** `saas`
**Stack:** FastAPI + React + PostgreSQL

After the pipeline, `docs/domain/model.md` contains:

```markdown
## Entities

### Invoice
Aggregate root. Owned by Freelancer.
States: draft → sent → paid | void

Fields: id, freelancer_id, client_id, line_items[], issued_date, due_date,
        total_amount, currency, status

Domain events: InvoiceCreated, InvoiceSent, InvoicePaid, InvoiceVoided

### Client
Aggregate root. Managed by Freelancer.
Fields: id, freelancer_id, name, email, address, default_currency

### TimeEntry
Owned by Freelancer. References Project.
Fields: id, freelancer_id, project_id, date, hours, description, billable, invoice_id?
```

And `docs/spec/api.md` has entries like:

```markdown
### POST /invoices
Auth: Bearer (freelancer scope)
Body: { client_id, line_items[], due_date, currency }
Response 201: Invoice object
Response 422: Validation error

### GET /invoices/{id}
Auth: Bearer (invoice:read scope)
Response 200: Invoice with line_items
Response 403: Not invoice owner
Response 404: Invoice not found
```

These feed directly into Copilot for implementation — the model, field names, status transitions, and permission rules are already defined.

---

## Brownfield example

If you have an existing codebase, use brownfield mode. After `copilot-bootstrap init && code .`, run in Copilot Chat:

```
/init brownfield
/scan
```

Detects and writes `.discovery/context.json`:

```json
{
  "stack": { "languages": ["typescript"], "backend": "express", "db": "postgres" },
  "tools": { "test_runner": "jest", "linter": "eslint", "bundler": "vite" },
  "arch": { "style": "layered", "monorepo": false }
}
```

Then:

```
/discover
```

`/discover` runs the 7-step capability extraction pipeline, producing `docs/discovery/l1-capabilities.md` with entries like:

```markdown
## BC-001 — Order Management
Confidence: HIGH (appears in 4 signal sources)
Evidence: OrderController, orders/ package, ORDERS table, /orders routes

## BC-002 — Customer Management
Confidence: HIGH
Evidence: CustomerService, customers/ package, CUSTOMERS table
```

Then:

```
/generate
```

Produces Copilot configuration tailored to the detected stack and discovered domain — not generic templates:

```
.github/copilot-instructions.md    project context: stack, entities, capabilities, conventions
.github/skills/                    dev skills for the actual stack (e.g. add-endpoint, add-migration)
.github/prompts/                   slash commands: /explain-capability, /trace-flow, /review-code
.github/agents/project.agent.md   project-specific development agent with capability map and entity ownership
.claude/settings.json              hooks: linter + formatter run automatically after file edits
```

Then run `/finish` to remove the bootstrap scaffolding — all pipeline machinery, bootstrap agents, and state files are deleted, leaving only the project agent and generated config.

---

## Commands

```sh
# Greenfield pipeline
copilot-bootstrap init              # initialise a new project
copilot-bootstrap interview         # start greenfield interview (6 steps)
copilot-bootstrap build-context     # build context.json, decisions.json, scope.json
copilot-bootstrap spec              # initialise spec pipeline; auto-runs generators when complete
copilot-bootstrap spec-status       # show spec pipeline progress

# Brownfield pipeline
copilot-bootstrap scan              # detect stack and write .discovery/context.json
copilot-bootstrap discover          # initialise the brownfield discovery pipeline
copilot-bootstrap discovery-status  # show discovery pipeline progress

# Greenfield generator (CLI — run after /spec)
copilot-bootstrap generate          # generate Copilot config from .greenfield/context.json
copilot-bootstrap generate status   # show generator progress
copilot-bootstrap generate --force  # re-run all generators
# Note: brownfield generation runs in Copilot Chat via /generate

# Navigation (manual / legacy)
copilot-bootstrap sync              # update framework files to latest version
copilot-bootstrap step              # show current workflow step
copilot-bootstrap next              # advance to next step
copilot-bootstrap ask               # print questions for the current step
copilot-bootstrap validate          # validate state file integrity
```

---

## Copilot Chat

After `copilot-bootstrap init` copies the framework files to your project, the entire **brownfield** workflow runs from Copilot Chat — no terminal needed after init. For **greenfield**, `copilot-bootstrap generate` (CLI) runs after `/spec` finishes.

### Slash commands

**Setup**

| Command | Description |
|---------|-------------|
| `/init` | Initialize project state files. Run once after opening a new project in VS Code. |
| `/scan` | Detect language, framework, database, and tools from the codebase. Brownfield only. |

**Greenfield workflow**

| Command | Description |
|---------|-------------|
| `/bootstrap idea: <text>` | Start the interview. Collects answers for idea, project info, users, features, tech, complexity. |
| `/build-context` | Derive `context.json`, `decisions.json`, `scope.json` from interview answers. |
| `/spec` | Initialize the spec pipeline and run all generation steps automatically. |

**Brownfield workflow**

| Command | Description |
|---------|-------------|
| `/discover` | Initialize the discovery pipeline and run all 7 capability extraction steps automatically. Requires `/scan` first. |
| `/generate` | Generate Copilot configuration from discovery outputs: instructions, dev skills, prompts, project agent, and hooks. |
| `/finish` | Remove bootstrap scaffolding after `/generate` completes. Keeps only the project agent, generated skills/prompts, and docs. |

**Status and review**

| Command | Description |
|---------|-------------|
| `/status` | Show current step, collected answers, and generated files. |
| `/discovery-status` | Show brownfield discovery pipeline progress (A1–A7 with stats). |
| `/review-spec` | Review generated spec for consistency across api, events, permissions, and state machines. |
| `/adlc-status` | Show ADLC extended workflow progress. |
| `/stitch` | Generate Google Stitch screen prompts from IA and flows. |
| `/pov` | Generate Proof of Value plan. |
| `/reset` | Reset workflow state. |

### Agents

| Agent | How to invoke | Purpose |
|-------|---------------|---------|
| Bootstrap | `@Bootstrap idea: ...` | Drives the interview phase; routes to downstream agents |
| Analyst | `@Analyst` | Generates PRD and capability map |
| Architect | `@Architect` | Generates domain model, RBAC, workflows |
| Designer | `@Designer` | Generates design overview, IA, flows |
| Spec | `@Spec` | Generates API spec |
| Discovery | `@Discovery` | Runs the brownfield capability extraction pipeline |
| Script | `@Script` | Generates dev skills and operational scripts |
| Evaluator | `@Evaluator` | Runs ADLC evaluation framework steps |
| Ops | `@Ops` | Generates monitoring spec and governance policy |
| **Project** | `@{project name}` | **Generated by `/generate`.** Primary development agent for day-to-day work — knows capabilities, entities, and stack |

---

## Project types

| Type | ADLC |
|------|------|
| `web-app` | No |
| `mobile` | No |
| `api` | No |
| `cli` | No |
| `agent` | Yes |
| `ai-system` | Yes |

When type is `agent` or `ai-system`, the pipeline extends with KPIs, human-agent responsibility mapping, evaluation framework, Proof of Value plan, monitoring spec, and governance policy.

---

## Approaches

| Approach | When to use |
|----------|-------------|
| `greenfield` | Building from scratch |
| `brownfield` | Existing codebase to understand, document, or modernize |

Brownfield skips the interview entirely. `/scan` auto-detects the stack, `/discover` extracts capabilities from the code, and `/generate` produces Copilot configuration tailored to what was found.

---

## Updating

```sh
uv tool install copilot-bootstrap --from git+https://github.com/Kit-Kroker/copilot-bootstrap.git --force
copilot-bootstrap sync
```

`sync` overwrites `.github/` and `docs/workflow/` from the updated package. It never touches `.project/state/`, `project.json`, or any generated documents.

---

## Manual

See [MANUAL.md](MANUAL.md) for full documentation: all agents, slash commands, skills, the brownfield discovery pipeline, the ADLC extended workflow, and troubleshooting.

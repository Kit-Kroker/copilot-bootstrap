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

```sh
mkdir my-project && cd my-project
copilot-bootstrap init
code .
```

In VS Code, open Copilot Chat, select the **Bootstrap** agent, and type:

```
idea: a helpdesk system for managing customer support tickets
```

The agent asks one step at a time. When it finishes collecting answers, click the **Generate PRD & Capabilities** handoff button. Continue clicking handoff buttons as each agent completes its phase. When Script finishes, all documents are in `docs/`.

---

## Example workflow

Here is an abbreviated session for a SaaS freelancer invoicing tool.

**Step 1 — Describe the idea**

```
idea: a SaaS platform where freelancers track time and generate invoices for clients
```

Bootstrap asks 5-6 targeted questions across these steps: project info, user roles, core features, tech stack, and scale. The questions adapt — if you pick `web-app`, it asks about frontend; if you pick `agent`, it asks about autonomy level.

**Step 2 — Collection complete**

After answering, Bootstrap presents a handoff:

```
✓ All answers collected.

[Generate PRD & Capabilities →]
```

Click it. The Analyst agent activates.

**Step 3 — Generation pipeline**

Each agent completes its phase and hands off to the next:

```
Analyst     → docs/analysis/prd.md, docs/analysis/capabilities.md
Architect   → docs/domain/model.md, docs/domain/rbac.md, docs/domain/workflows.md
Designer    → docs/design/overview.md, docs/design/ia.md, docs/design/flows.md
Spec        → docs/spec/api.md, docs/spec/events.md, docs/spec/permissions.md, docs/spec/state-machines.md
Script      → .github/skills/ (dev scaffolding)
```

Total: 5 handoff clicks, ~12 generated documents.

**Step 4 — Start building**

```
/status        # confirm all files exist
/review-spec   # check spec consistency before coding
```

Open Copilot Chat, use the generated skills (`/scaffold-project`, `/generate-models`, etc.) to start implementation with full context loaded.

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

If you have an existing codebase, use brownfield mode. The `scan` command detects the stack automatically:

```sh
cd /path/to/existing-project
copilot-bootstrap init
copilot-bootstrap scan    # detects language, framework, DB, tools
copilot-bootstrap discover
```

`scan` writes `.discovery/context.json`:

```json
{
  "stack": { "languages": ["typescript"], "backend": "express", "db": "postgres" },
  "tools": { "test_runner": "jest", "linter": "eslint", "bundler": "vite" },
  "arch": { "style": "layered", "monorepo": false }
}
```

The Discovery agent then runs the 7-step capability extraction pipeline against your codebase, producing `docs/discovery/l1-capabilities.md` with entries like:

```markdown
## BC-001 — Order Management
Confidence: HIGH (appears in 4 signal sources)
Evidence: OrderController, orders/ package, ORDERS table, /orders routes

## BC-002 — Customer Management
Confidence: HIGH
Evidence: CustomerService, customers/ package, CUSTOMERS table
```

After discovery, `copilot-bootstrap generate` produces project-specific Copilot config:

```
.github/copilot-instructions.md    project-wide context (stack, conventions)
.github/instructions/              language + framework + architecture rules
.github/agents/                    backend, frontend, test, refactor agents
.github/skills/                    build, test, lint, deploy skills
.github/prompts/                   /new-feature, /fix-bug, /write-tests, /review-pr
.vscode/mcp.json                   MCP server config (postgres, filesystem)
```

---

## Commands

```sh
copilot-bootstrap init              # initialise a new project
copilot-bootstrap scan              # detect stack and write .discovery/context.json
copilot-bootstrap discover          # initialise the brownfield discovery pipeline
copilot-bootstrap discovery-status  # show discovery pipeline progress
copilot-bootstrap generate          # generate Copilot config from discovery outputs
copilot-bootstrap generate-status   # show generator progress
copilot-bootstrap sync              # update framework files to latest version
copilot-bootstrap step              # show current workflow step
copilot-bootstrap next              # advance to next step
copilot-bootstrap ask               # print questions for the current step
copilot-bootstrap validate          # validate state file integrity
```

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

Brownfield replaces the users/features/tech/complexity steps with a 7-step codebase analysis. Both approaches support ADLC.

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

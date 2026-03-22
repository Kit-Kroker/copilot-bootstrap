---
name: generate-skills
description: Generate dev agent skill stubs tailored to the project's tech stack and features. Use this when the bootstrap workflow step is "skills". Reads tech and spec docs to produce SKILL.md stubs under .github/skills/.
argument-hint: "[skill name to generate, or leave blank for all]"
---

# Skill Instructions

Read:
- `.project/state/answers.json`
- `docs/analysis/prd.md`
- `docs/analysis/capabilities.md`
- `docs/spec/api.md` (if present)
- `docs/domain/workflows.md` (if present)

Based on the tech stack and capabilities, generate SKILL.md stubs for the dev agent under `.github/skills/`.

## Skills to Generate

Derive the list from the project's features and tech stack. Common patterns:

### For every project
- `scaffold-project` — Initialise the project with the chosen tech stack
- `generate-models` — Generate data models from the domain model
- `generate-api` — Generate API endpoint stubs from docs/spec/api.md
- `generate-tests` — Generate test stubs for core workflows

### For web app projects
- `generate-components` — Generate UI component stubs
- `generate-pages` — Generate page/route stubs from the IA

### For SaaS projects
- `generate-auth` — Generate authentication and session management
- `generate-tenant` — Generate multi-tenancy scaffolding

### For enterprise projects
- `generate-rbac-impl` — Generate RBAC implementation from docs/domain/rbac.md
- `generate-audit-log` — Generate audit logging stubs

## Output Format per Skill

Each skill must follow this format:

```markdown
---
name: {skill-name}
description: {what this skill generates, when to use it, what it reads}
argument-hint: "[specific resource or leave blank for all]"
---

# Skill Instructions

Read:
- {input files this skill needs}

Generate:
- {output files or folders}

Requirements:
- {tech stack constraint from answers.json}
- {naming conventions from domain model}
```

## Example Output

`.github/skills/generate-models/SKILL.md`

```markdown
---
name: generate-models
description: Generate data model files from the domain model. Reads docs/domain/model.md and produces model files in the project src directory using the project's chosen backend language.
argument-hint: "[entity name to generate, or leave blank for all entities]"
---

# Skill Instructions

Read:
- `docs/domain/model.md`
- `.project/state/answers.json` (for tech stack)

For each entity in the domain model, generate a model file in the appropriate location for the tech stack.

Follow naming conventions from docs/domain/model.md.
```

---

After generating all skill stubs:
- Update `.project/state/workflow.json`: set `step` to `scripts`, `status` to `in_progress`

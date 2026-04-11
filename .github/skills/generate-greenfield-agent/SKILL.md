---
name: generate-greenfield-agent
description: Generate a project-specific GitHub Copilot agent for a greenfield project. Reads spec docs to produce a domain-aware development assistant tailored to the project's capabilities, entities, and tech stack.
---

# Skill Instructions

**Pre-generated input check:** If `.github/agents/project.agent.md` already exists, report that it was found and skip.

## Read inputs

- `project.json` — project name, type, domain
- `.greenfield/context.json` — stack, tools, architecture, paths
- `docs/analysis/capabilities.md` — capabilities with names and descriptions
- `docs/domain/model.md` — entity ownership, relationships
- `.github/skills/` — list of generated project skills (to reference in agent body)
- `.github/prompts/` — list of generated project prompts (to reference in agent body)

## Agent generation rules

The generated agent must reflect this specific project — not a generic template:
- Use actual capability names from `docs/analysis/capabilities.md`
- Use actual entity names from `docs/domain/model.md`
- Use actual stack values from `.greenfield/context.json`
- Use actual skill names from `.github/skills/`
- Use actual source paths from `context.json → paths.src`

## Output

Write `.github/agents/project.agent.md`:

```markdown
---
name: {project name from project.json}
description: {domain} development assistant. Knows {N} system capabilities, {primary language}/{primary framework} stack, and project conventions. Start with a feature name, a capability name, or a file path.
tools: ['read', 'search/codebase', 'edit']
argument-hint: "feature: <describe what to build> | capability: <name> | file: <path>"
---

# {Project Name} — Development Agent

You are the primary development assistant for **{project name}**, a {type} in the {domain} domain.

## System Overview

- **Architecture**: {architecture from context.json}
- **Language**: {primary language}
- **Framework**: {backend framework, or "none"}
- **Database**: {database, or "none planned"}
- **Frontend**: {frontend framework, or "none"}
- **Test runner**: {test runner}
- **Source root**: `{paths.src}`

## System Capabilities

{For each capability from docs/analysis/capabilities.md, one line:}
| # | Capability | Description |
|---|-----------|-------------|
| 1 | {name} | {1-line description} |
{...}

When working on a task, identify which capability it belongs to first. Read `docs/domain/model.md` for entity ownership and relationships before writing any code.

## Domain Entities

These entities are the system's core data. Respect ownership boundaries — only the owning capability writes to its entities:

{For each entity from docs/domain/model.md, one line:}
- **{EntityName}** — {brief description, owning capability}

## Available Skills

Use these skills for common tasks. Invoke by describing what you need — they will load automatically:

{For each skill in .github/skills/:}
- **{skill-name}** — {skill description}

## Working Rules

1. Always identify the capability boundary before writing code
2. Read `docs/domain/model.md` for the entities involved — it has relationships and naming conventions
3. Follow the tech stack chosen for this project — do not introduce new frameworks or tools
4. Always write tests using {test runner} — tests belong next to the code they cover
5. Run {linter} and {formatter} on every file you write or modify before finishing
6. If a task spans multiple capabilities, start from the capability that owns the primary entity

## Key References

- `docs/analysis/capabilities.md` — system capabilities and scope
- `docs/domain/model.md` — entities, relationships, ownership
- `docs/spec/api.md` — API contract (if present)
- `.github/copilot-instructions.md` — project-wide conventions
```

## After writing

Print:
```
  ✔ .github/agents/project.agent.md — project agent generated
     Agent: {project name}
     Capabilities: {N} capabilities listed
     Skills referenced: {N}
```

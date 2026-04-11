---
name: generate-greenfield-copilot-instructions
description: Generate .github/copilot-instructions.md for a greenfield project. Reads context.json and spec docs to produce stack-specific, domain-aware AI instructions for the project being built.
---

# Skill Instructions

Generate `.github/copilot-instructions.md` tailored to this specific greenfield project.

## Read inputs

- `.greenfield/context.json` — stack, tools, architecture
- `project.json` — name, type, domain
- `docs/analysis/capabilities.md` — system capabilities
- `docs/domain/model.md` — entities, ownership, relationships
- `docs/analysis/prd.md` — product requirements (for project purpose)

## What to generate

Produce a `.github/copilot-instructions.md` with these sections:

### 1. Project identity
One paragraph: what this project is, its domain, its primary purpose. Derived from `project.json → domain` and the PRD summary.

### 2. Tech stack
Concrete, factual list from `.greenfield/context.json` — no guesses:
- Language(s) and runtime
- Backend framework
- Frontend framework (if present)
- Database (if present)
- Package manager, linter, formatter, test runner

### 3. Architecture
From `context.json → arch`: style (monolith/layered/microservices), monorepo yes/no. Include the planned source layout from `context.json → paths`.

### 4. Domain model
Key entities from `docs/domain/model.md` and their owning capabilities. List the top 5–10 entities with a one-line description. This anchors naming conventions.

### 5. Capability map
List of capabilities from `docs/analysis/capabilities.md`. One line each: name + one-sentence description. This tells the AI what the system does.

### 6. Coding conventions
Derive from the detected stack:
- File naming: follow language conventions (snake_case for Python, camelCase/PascalCase for TS/Java, etc.)
- Test file placement: follow detected test runner conventions
- Import style: infer from language
- API naming: infer from framework (REST resource names from domain entities, etc.)

### 7. What NOT to do
Three to five hard constraints for this specific stack:
- e.g., "Do not add a second ORM — the project uses {chosen ORM}"
- e.g., "Do not introduce a new package manager — use {detected PM} exclusively"
- e.g., "Do not bypass {detected linter} — all code must pass lint before commit"

## Output format

Write valid Markdown. Be specific — use the actual project name, actual entity names, actual tool names throughout. Do not write generic placeholder text.

## After writing

Print:
```
  ✔ .github/copilot-instructions.md written ({N} sections)
```

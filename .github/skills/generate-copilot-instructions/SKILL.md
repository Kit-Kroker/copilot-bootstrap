---
name: generate-copilot-instructions
description: Generate .github/copilot-instructions.md for a brownfield project. Reads discovery outputs and context to produce stack-specific, domain-aware AI instructions. Replaces any generic copilot-instructions.md.
---

# Skill Instructions

Generate `.github/copilot-instructions.md` tailored to this specific brownfield project.

## Read inputs

- `.discovery/context.json` — stack, tools, architecture
- `project.json` — name, type, domain
- `docs/discovery/l1-capabilities.md` — L1 capabilities
- `docs/discovery/domain-model.md` — entities, ownership, relationships
- `docs/discovery/blueprint-comparison.md` — industry alignment (if present)

## What to generate

Produce a `.github/copilot-instructions.md` with these sections:

### 1. Project identity
One paragraph: what this codebase is, its domain, its primary purpose. Derived from `project.json → domain` and L1 capabilities.

### 2. Tech stack
Concrete, factual list of the detected stack — no guesses, only what's in `.discovery/context.json`:
- Language(s) and runtime
- Backend framework
- Frontend framework (if present)
- Database(s)
- Package manager, linter, formatter, test runner

### 3. Architecture
From `context.json → arch`: style (monolith/layered/microservices), monorepo yes/no, service count. Include the main entrypoints if detected.

### 4. Domain model
Key entities from `docs/discovery/domain-model.md` and their owning capabilities. List the top 5–10 entities with a one-line description. This anchors naming conventions.

### 5. Capability map
List of L1 capabilities from `docs/discovery/l1-capabilities.md`. One line each: name + one-sentence description. This tells the AI what the codebase does.

### 6. Coding conventions
Derive from the detected stack:
- File naming: follow language conventions (snake_case for Python, camelCase/PascalCase for TS/Java, etc.)
- Test file placement: follow detected test runner conventions
- Import style: infer from language
- API naming: infer from framework (REST resource names from domain entities, etc.)

### 7. What NOT to do
Three to five hard constraints for this specific stack:
- e.g., "Do not add a second ORM — the project uses {detected ORM}"
- e.g., "Do not introduce a new package manager — use {detected PM} exclusively"
- e.g., "Do not bypass {detected linter} — all code must pass lint before commit"

## Output format

Write valid Markdown. Be specific — use the actual project name, actual entity names, actual tool names throughout. Do not write generic placeholder text.

## After writing

Print:
```
  ✔ .github/copilot-instructions.md written ({N} sections)
```

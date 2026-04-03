---
name: generate-brownfield-skills
description: Generate dev skill stubs tailored to a brownfield project's actual stack and discovered capabilities. Reads .discovery/context.json and discovery docs to produce SKILL.md files under .github/skills/. Skills map to real operations on the existing codebase, not generic templates.
argument-hint: "[capability name to generate skills for, or leave blank for all]"
---

# Skill Instructions

Generate `.github/skills/` stubs for the brownfield project. Every skill must reflect the actual detected stack and discovered domain — no generic placeholders.

## Read inputs

- `.discovery/context.json` — stack and tools (language, framework, db, linter, test runner, etc.)
- `docs/discovery/l1-capabilities.md` — what the codebase does at capability level
- `docs/discovery/l2-capabilities.md` — sub-capabilities with code locations
- `docs/discovery/domain-model.md` — entity names, ownership, relationships

## Derive skills from stack

Generate skills based on the detected stack. Use only what is present in `context.json`.

### Core skills (every brownfield project)

| Skill name | When to generate | Purpose |
|---|---|---|
| `add-feature` | always | Add a new end-to-end feature across the existing layers (controller → service → repo → test) |
| `add-test` | always | Add unit and/or integration tests for an existing module or capability |
| `fix-bug` | always | Diagnose and fix a bug: read failing test or error, locate code, apply fix, verify |

### Stack-specific skills

**If backend = express / fastify / koa / hapi (Node.js REST):**
- `add-endpoint` — Add a new REST endpoint (route → handler → service → test)
- `add-middleware` — Add middleware to an existing route group

**If backend = nestjs:**
- `add-module` — Scaffold a new NestJS module (module → controller → service → dto → test)
- `add-endpoint` — Add a REST endpoint within an existing NestJS module

**If backend = fastapi / flask / django:**
- `add-endpoint` — Add a new API route (router → handler → schema → test)
- `add-schema` — Add or modify a Pydantic/Marshmallow schema

**If backend = spring-boot / quarkus / micronaut:**
- `add-endpoint` — Add a new REST controller method with service layer and test
- `add-service` — Add a new service class with interface, implementation, and unit test

**If backend = gin / echo / fiber / chi (Go):**
- `add-handler` — Add a new HTTP handler with route registration and test
- `add-service` — Add a new service function with test

**If db = postgres / mysql / sqlite:**
- `add-migration` — Write a database migration for schema changes (use detected migration tool: flyway, liquibase, alembic, golang-migrate, knex, prisma migrate, etc.)
- `add-repository` — Add a repository/DAO class or function for a domain entity

**If db = mongodb / mongoose:**
- `add-model` — Add a Mongoose/Motor model with schema, indexes, and validation
- `add-repository` — Add a repository layer for a MongoDB collection

**If frontend is present (react / vue / angular / svelte):**
- `add-component` — Add a new UI component with props, state, and test
- `add-page` — Add a new page/route with layout and data fetching

**If test_runner is detected:**
- `add-test` — Always include this; reference the actual runner (jest/vitest/pytest/go test/junit/rspec)

### Capability-derived skills

For each L1 capability in `docs/discovery/l1-capabilities.md`, generate one skill if it represents a standalone operation area (e.g., "Order Management" → `manage-orders`, "User Auth" → `add-auth-flow`).

Limit to capabilities with HIGH or MEDIUM confidence. Skip LOW-confidence or flagged capabilities.

## Output format per skill

```markdown
---
name: {skill-name}
description: {one sentence: what this skill does, what it reads, what it produces}
argument-hint: "{specific resource name or 'leave blank for interactive'}"
---

# Skill Instructions

Read:
- {exact files this skill should read — use actual paths from context.json → paths}

Task:
{2–4 sentences describing what to generate, which layer to touch, naming conventions to follow}

Requirements:
- Language: {from context.json → stack.languages[0]}
- Framework: {from context.json → stack.backend or frontend}
- Test runner: {from context.json → tools.test_runner} — always write tests
- Follow naming conventions from docs/discovery/domain-model.md
```

## Rules

- Use actual entity names from the domain model (not "MyEntity")
- Use actual detected tool names (not "your linter")
- Reference actual source paths from `context.json → paths.src`
- Every skill must include a requirement to write tests using the detected test runner
- Do not generate skills for tools not detected in `context.json`
- Maximum 12 skills — prioritize by frequency of use

## After writing

Print:
```
  ✔ .github/skills/ — {N} skills generated
     {list each skill name on its own line, prefixed with "     - "}
```

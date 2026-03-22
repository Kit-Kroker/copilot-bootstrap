---
name: generate-prd
description: Generate a Product Requirements Document from collected bootstrap answers. Use this when the workflow step is "prd". Reads answers.json and produces docs/analysis/prd.md covering goal, users, features, scope, non-goals, and constraints.
argument-hint: "[project name or leave blank to use answers.json]"
---

# Skill Instructions

Read `.project/state/answers.json`.

Generate `docs/analysis/prd.md` using this exact structure:

```markdown
# Product Requirements Document

## Overview

**Project:** {name}
**Type:** {type}
**Domain:** {domain}
**Complexity:** {complexity}

## Goal

{One paragraph: what this product does and why it exists, derived from the idea.}

## Users

| Role | Description |
|------|-------------|
| {role} | {what they do in the system} |

## Core Features

{Numbered list of features from answers.}

## Scope

### In Scope
- {Features and capabilities included in V1.}

### Out of Scope
- {Explicitly excluded items.}

## Non-Goals

- {Things intentionally not addressed.}

## Constraints

### Technical
- Backend: {backend}
- Frontend: {frontend}
- Database: {database if specified}

### Business
- {Any business constraints implied by domain or complexity.}

## Open Questions

- {Any gaps in the answers that need resolution before implementation.}
```

If required data is missing, ask focused follow-up questions before generating.

After writing the file:
- Update `.project/state/workflow.json`: set `step` to `capabilities`, `status` to `in_progress`
- Update `project.json` fields `name`, `type`, `domain` from answers

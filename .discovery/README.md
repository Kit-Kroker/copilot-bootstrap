# `.discovery/` — Structured Data Layer

This directory is the **machine-readable** counterpart to `docs/discovery/`.

## Purpose

`.discovery/` stores auto-detection results, confidence scores, and pipeline state
for the brownfield bootstrap process. Generators and pipeline steps read from here;
humans review `docs/discovery/` markdown outputs.

## Files

| File | Format | Purpose | Committed |
|------|--------|---------|-----------|
| `fs.json` | JSON | Filesystem scan results | Yes |
| `stack.json` | JSON | Detected languages, frameworks, DB | Yes |
| `tools.json` | JSON | Detected toolchain (npm, eslint, jest, docker, etc.) | Yes |
| `arch.json` | JSON | Detected architecture style, monorepo, services | Yes |
| `context.json` | JSON | Unified context (merged from above + user overrides) | Yes |
| `confidence.json` | JSON | Detection confidence scores per field | Yes |
| `pipeline.lock.json` | JSON | Discovery pipeline progress (session state) | **No** |
| `generators.lock.json` | JSON | Generator orchestrator progress (session state) | **No** |

## Relationship to `docs/discovery/`

| Directory | Format | Purpose | Consumers |
|-----------|--------|---------|-----------|
| `.discovery/` | JSON | Machine-readable metadata & state | Pipeline runner, generators, CLI, `codebase_setup` |
| `docs/discovery/` | Markdown | Human-readable capability specs | Analyst, Architect, Designer, Spec agents; user review |

These are complementary:

- `.discovery/context.json` answers **"what is the tech stack?"**
- `docs/discovery/l1-capabilities.md` answers **"what does the system do?"**

Discovery pipeline steps (A1–A7) write to `docs/discovery/`.
Pre-discovery scan writes to `.discovery/`.

## Consumer Mapping

| Consumer | Reads from `.discovery/` | Reads from `docs/discovery/` |
|----------|-------------------------|------------------------------|
| `codebase_setup` | context.json, confidence.json | — |
| Discovery pipeline (A1–A7) | context.json (for stack info) | Previous step's .md output |
| `generate-prd` | context.json | l1-capabilities.md, domain-model.md |
| `generate-capabilities` | context.json | l1-capabilities.md, l2-capabilities.md |
| `generate-domain` | context.json | domain-model.md |
| Rules generator | context.json | — |
| Agents generator | context.json | capabilities.md |
| Skills generator | context.json | — |
| Hooks generator | context.json | — |
| Workflow generator | context.json | capabilities.md, domain-model.md |

## Confidence Threshold

If any field in `confidence.json` is below **0.75**, `codebase_setup` prompts the user
to confirm or correct the detected value before proceeding.

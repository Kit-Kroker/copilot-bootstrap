---
name: build-context
description: Build .greenfield/context.json, decisions.json, and scope.json from interview answers. Applies smart defaults for toolchain based on language and frontend choice. Run after the bootstrap interview completes.
tools: ['read', 'edit']
---

Build greenfield context files from interview answers.

## Pre-flight

1. Check `.greenfield/answers.json` exists. If not: "Answers not found. Run `/bootstrap` to complete the interview first."
2. Read `.greenfield/answers.json`.
3. Check that `steps_completed` includes `idea`, `project_info`, `users`, `features`, `tech`, `complexity`. If any are missing, stop: "Interview incomplete. Missing steps: {list}. Run `/bootstrap` to finish."

## Read values from answers

Extract (all lowercased where strings):
- `language` = `tech.languages[0]` or `tech.language`, default `"unknown"`
- `frontend` = `tech.frontend`, default `""`
- `backend` = `tech.backend`, default `""`
- `db` = `tech.db`, default `""`
- `project_type` = `project_info.type`, default `"web"`
- `project_name` = `project_info.name`, default `"my-app"`
- `project_domain` = `project_info.domain`, default `null`
- `complexity` = `complexity.level`, default `"startup"`
- `autonomy` = `complexity.autonomy`, default `"semi"`
- `adlc` = `complexity.adlc`, default `false`
- User tool overrides (null if absent): `tech.package_manager`, `tech.linter`, `tech.formatter`, `tech.test_runner`, `tech.bundler`, `tech.container`, `tech.orchestrator`

## Derivation rules (applied silently, source = "derived")

**Runtime:**

| Language | Runtime |
|----------|---------|
| typescript, javascript, ts, js | node |
| python | python |
| go | go |
| java, kotlin | jvm |
| rust | rust |
| other | use language value |

**Architecture style:**

| Project type | Style | Reason |
|---|---|---|
| cli | monolith | CLI project defaults to monolith |
| api | layered | API service defaults to layered architecture |
| all others | layered | Defaults to layered for single service |

**Monorepo**: always `false` — "Single service project — defaults to false"

## Smart defaults (user answer overrides default; track which are defaulted)

For each tool: if user provided a non-null value → source = "user". Otherwise apply the default → source = "default". Add to `defaults_applied` list.

**TypeScript/JavaScript:**
- package_manager: `npm`
- linter: `eslint`
- formatter: `prettier`
- test_runner: if frontend ∈ {react, vue, svelte, solid, preact} → `vitest`; else → `jest`
- bundler: if frontend ∈ {react, vue, svelte, solid, preact} → `vite`; else → `null`

**Python:**
- package_manager: `pip`
- linter: `ruff`
- formatter: `black`
- test_runner: `pytest`
- bundler: `null`

**Go:**
- package_manager: `null` (Go modules, no separate PM)
- linter: `golangci-lint`
- formatter: `gofmt`
- test_runner: `go test`
- bundler: `null`

**Java/Kotlin:**
- package_manager: `gradle`
- linter: `checkstyle`
- formatter: `null`
- test_runner: `junit`
- bundler: `null`

**Rust:**
- package_manager: `cargo`
- linter: `clippy`
- formatter: `rustfmt`
- test_runner: `cargo test`
- bundler: `null`

**Other languages:** all tools remain null.

Container and orchestrator: never set defaults — use user value only (source = "user").

Set any resolved empty string to `null` before writing.

## Write `.greenfield/context.json`

```json
{
  "stack": {
    "languages": ["<language>"],
    "frontend": "<frontend or null>",
    "backend": "<backend or null>",
    "db": "<db or null>",
    "runtime": "<derived runtime>"
  },
  "tools": {
    "package_manager": "<value or null>",
    "linter": "<value or null>",
    "formatter": "<value or null>",
    "test_runner": "<value or null>",
    "bundler": "<value or null>",
    "container": "<value or null>",
    "orchestrator": "<value or null>"
  },
  "arch": {
    "style": "<derived style>",
    "monorepo": false,
    "services": 1,
    "patterns": []
  },
  "paths": {
    "src": "src/",
    "tests": "tests/",
    "docs": "docs/",
    "config": "."
  },
  "project": {
    "name": "<name>",
    "type": "<type>",
    "domain": "<domain or null>",
    "complexity": "<complexity>"
  }
}
```

## Write `.greenfield/decisions.json`

```json
{
  "stack_rationale": {
    "language":  {"choice": "<>", "source": "user",    "reason": "User selected"},
    "frontend":  {"choice": "<>", "source": "user",    "reason": "User selected"},
    "backend":   {"choice": "<>", "source": "user",    "reason": "User selected"},
    "db":        {"choice": "<>", "source": "user",    "reason": "User selected"},
    "runtime":   {"choice": "<>", "source": "derived", "reason": "Derived from language: <language>"}
  },
  "tools_rationale": {
    "package_manager": {"choice": "<>", "source": "<user|default>", "reason": "<>"},
    "linter":          {"choice": "<>", "source": "<user|default>", "reason": "<>"},
    "formatter":       {"choice": "<>", "source": "<user|default>", "reason": "<>"},
    "test_runner":     {"choice": "<>", "source": "<user|default>", "reason": "<>"},
    "bundler":         {"choice": "<>", "source": "<user|default>", "reason": "<>"},
    "container":       {"choice": "<>", "source": "user",           "reason": "User selected"},
    "orchestrator":    {"choice": "<>", "source": "user",           "reason": "User selected"}
  },
  "arch_rationale": {
    "style":    {"choice": "<>", "source": "derived", "reason": "<arch reason>"},
    "monorepo": {"choice": false, "source": "derived", "reason": "Single service project — defaults to false"}
  },
  "defaults_applied": ["<tool names that used smart defaults>"]
}
```

## Write `.greenfield/scope.json`

```json
{
  "features": [<features array from answers>],
  "users": [<users array from answers>],
  "complexity": "<complexity>",
  "autonomy_level": "<autonomy>",
  "adlc": <adlc>,
  "estimated_capabilities": <feature_count × 3>
}
```

## Update `project.json`

Merge these fields (preserve all existing fields):
- `name`, `type`, `domain`, `approach` = `"greenfield"`, `autonomy_level`, `adlc`

## Update `.project/state/workflow.json`

Set `approach` = `"greenfield"`.

## Confirm

```
Context built from .greenfield/answers.json

  ✔ .greenfield/context.json
  ✔ .greenfield/decisions.json
  ✔ .greenfield/scope.json

Runtime:      <runtime> (derived)
Architecture: <style> (derived)
Smart defaults applied (<N> fields): <comma-separated list>

Next: run `/spec` to generate specification documents.
```

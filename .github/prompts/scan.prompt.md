---
name: scan
description: Scan the current codebase to detect language, framework, database, tools, and architecture. Writes .discovery/context.json and .discovery/confidence.json. Use before starting the brownfield bootstrap interview.
tools: ['read', 'edit', 'search/codebase']
argument-hint: "[path] — codebase path, defaults to current directory"
---

Scan the current codebase and detect its stack, tools, and architecture.

## Set codebase path

If the user provided a path argument, use it. Otherwise use the current workspace root.
Update `project.json → codebase_path` with this path (create `project.json` with default structure if it doesn't exist yet).

## Detect stack

Look for these config files and use them as high-confidence signals (confidence ≥ 0.90):

| File | Signals |
|------|---------|
| `package.json` | JavaScript/TypeScript; read `dependencies` and `devDependencies` for framework, test runner, linter, bundler |
| `tsconfig.json` | TypeScript confirmed |
| `go.mod` | Go; read module name |
| `Cargo.toml` | Rust |
| `pyproject.toml` | Python; read `[tool.poetry]`, `[build-system]`, or `[project]` for framework and tools |
| `requirements.txt` | Python (lower confidence — 0.70) |
| `setup.py` / `setup.cfg` | Python |
| `pom.xml` | Java/Maven |
| `build.gradle` / `build.gradle.kts` | Java or Kotlin/Gradle |
| `*.csproj` / `*.sln` | C# |
| `Gemfile` | Ruby |
| `composer.json` | PHP |

Read the files that exist and extract:

**Languages**: primary language(s) from config files.

**Frontend framework** (from `package.json` dependencies):
- react → React
- vue → Vue
- @angular/core → Angular
- svelte → Svelte
- next → Next.js
- nuxt → Nuxt

**Backend framework**:
- JS/TS: express, fastify, koa, nestjs, hapi
- Python: fastapi, django, flask, starlette
- Java: spring-boot, quarkus, micronaut
- Go: gin, echo, fiber, chi
- Ruby: rails, sinatra

**Database** (from config files, env examples, or import patterns):
- postgres / postgresql → postgres
- mysql / mariadb → mysql
- mongodb / mongoose → mongodb
- sqlite → sqlite
- redis → redis (note as cache, not primary DB)

**Tools** (from package.json devDependencies or config files):
- Linter: eslint, ruff, pylint, golangci-lint, checkstyle, clippy
- Formatter: prettier, black, isort, gofmt, rustfmt
- Test runner: jest, vitest, pytest, go test, junit, rspec, cargo test
- Bundler: vite, webpack, esbuild, rollup, parcel, turbopack
- Package manager: detect from `package-lock.json` (npm), `yarn.lock` (yarn), `pnpm-lock.yaml` (pnpm), `uv.lock` (uv), `Pipfile.lock` (pipenv), `poetry.lock` (poetry)

**Architecture style** (from directory structure):
- Multiple `*/Dockerfile` or `docker-compose.yml` with multiple services → microservices (0.75)
- `src/`, `frontend/`, `backend/` as separate top-level dirs → layered (0.80)
- Single flat `src/` → monolith (0.70)
- Monorepo: `packages/`, `apps/`, `libs/` as top-level dirs → monorepo = true (0.85)

**Confidence scoring**:
- Config file detection → 0.92
- Dependency/import detection → 0.70
- Directory structure inference → 0.65
- Not detected → 0.0

## Write `.discovery/context.json`

```json
{
  "stack": {
    "languages": ["<detected languages>"],
    "frontend": "<framework or null>",
    "backend": "<framework or null>",
    "db": "<database or null>",
    "runtime": "<derived from language>"
  },
  "tools": {
    "package_manager": "<detected or null>",
    "linter": "<detected or null>",
    "formatter": "<detected or null>",
    "test_runner": "<detected or null>",
    "bundler": "<detected or null>",
    "container": "<docker|podman|null>",
    "orchestrator": "<detected or null>"
  },
  "arch": {
    "style": "<monolith|layered|microservices>",
    "monorepo": <true|false>,
    "services": <count>,
    "entrypoints": ["<main entry files>"]
  },
  "paths": {
    "src": "<detected or src/>",
    "tests": "<detected or tests/>",
    "docs": "docs/",
    "config": "."
  }
}
```

## Write `.discovery/confidence.json`

```json
{
  "language": <0.0–1.0>,
  "frontend": <0.0–1.0>,
  "backend": <0.0–1.0>,
  "db": <0.0–1.0>,
  "package_manager": <0.0–1.0>,
  "linter": <0.0–1.0>,
  "formatter": <0.0–1.0>,
  "test_runner": <0.0–1.0>,
  "bundler": <0.0–1.0>,
  "architecture": <0.0–1.0>,
  "monorepo": <0.0–1.0>
}
```

## Update `project.json`

Set `approach` = `"brownfield"` and `codebase_path` = the scanned path.

## Confirm

Print a summary of detected values. For each field, show the value and confidence:
- ≥ 0.85: show as detected (no qualifier)
- 0.50–0.84: show with "(low confidence — verify)"
- < 0.50 or missing: show as "not detected"

```
Stack detected in <path>

  Language:     <value> (<confidence>)
  Frontend:     <value or not detected>
  Backend:      <value>
  Database:     <value>
  Architecture: <style>
  Monorepo:     <yes/no>

Tools:
  Package manager: <value>
  Linter:          <value>
  Formatter:       <value>
  Test runner:     <value>

Next: run `/bootstrap` to start the codebase setup interview.
The interview will use these detected values — confirm or correct them as you go.
```

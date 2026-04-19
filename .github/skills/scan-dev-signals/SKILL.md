---
name: scan-dev-signals
description: Extract developer-perspective signals from the codebase — dependency inventory, architecture & build analysis, environment configuration catalog, and code health indicators. Emits "not-collected" when signals are absent rather than defaulting. Runs in the dev lane of /assess after /discover completes.
---

# Skill Instructions

**Pre-generated input check:** If `docs/dev/dev-signals.json` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated analysis from external tooling.

Read:
- `.project/state/answers.json` (specifically `codebase_setup`: path, language, architecture, has_frontend)
- `.discovery/context.json` (for confirmed stack, tools, architecture, paths)
- `docs/discovery/l1-capabilities.md` ← optional (for per-capability cross-referencing)
- `docs/discovery/candidates.md` ← optional (for owned-file cross-referencing)
- The codebase at the configured path

## Dev Signal Context

Before scanning, read `dev_scope` from `.project/state/answers.json`. If not present, apply defaults:
- `dependency_analysis`: `"auto"` (auto-detect all manifests)
- `env_var_sources`: `[]` (auto-detect from .env.example, config files)
- `architecture_depth`: `"standard"` (detect patterns, flag violations)

**Not-collected is first-class.** Whenever a signal cannot be determined from static evidence, record it as `"not-collected"` rather than substituting `0`, `false`, or `"unknown"`. This propagates honestly through the dev readiness report and blocker detection.

## Signal Extraction (4 sub-steps)

### DS1 — Dependency Inventory

Detect and analyze all package manifests in the codebase.

**Manifest detection:**
- JavaScript/TypeScript: `package.json` — read `dependencies`, `devDependencies`, `peerDependencies`
- Java/Kotlin: `pom.xml` — read `<dependencies>`; `build.gradle` / `build.gradle.kts` — read `dependencies {}` block
- Python: `requirements.txt`, `pyproject.toml` (`[tool.poetry.dependencies]`, `[project.dependencies]`), `setup.py`, `setup.cfg`, `Pipfile`
- Go: `go.mod` — read `require` block
- Ruby: `Gemfile` — read `gem` declarations
- Rust: `Cargo.toml` — read `[dependencies]`, `[dev-dependencies]`
- .NET: `*.csproj` — read `<PackageReference>` elements; `packages.config`
- PHP: `composer.json` — read `require`, `require-dev`

For each manifest found, extract:

**Dependency classification:**
- Separate runtime deps (`dependencies`, `<scope>compile</scope>`, `[dependencies]`) from dev deps (`devDependencies`, `<scope>test</scope>`, `[dev-dependencies]`)

**Version analysis:**
- Record declared version constraint per dep: `exact` (e.g., `1.2.3`), `range` (e.g., `^1.2.3`, `>=1.0`), `wildcard` (`*`, `latest`), `not-specified` (no version)
- `pinning_strategy`: `strict` (all exact) | `loose` (mix of range/exact) | `none` (wildcards present)

**Health flags (static detection — no network calls):**
- `has_lockfile`: `true | false` — detect `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, `poetry.lock`, `go.sum`, `Cargo.lock`, `Gemfile.lock`, `composer.lock`
- `wildcard_versions`: array of dep names with `*` or `latest` version — these introduce uncontrolled upgrade risk
- `deprecated_markers`: array of dep names where an adjacent comment explicitly notes deprecation (look for `// deprecated`, `# deprecated`, `// TODO: replace`, `// REMOVE` inline near the dep declaration)
- `potential_conflicts`: `"not-collected"` — cannot determine without running the resolver

**License classification (best-effort from known dep names):**
- Classify as `permissive` if dep name matches well-known permissive packages: react, lodash, express, fastify, django, flask, rails, spring-boot, gin, numpy, pandas, axios, jest, pytest, junit, etc.
- Classify as `copyleft_risk` if dep name contains `gpl` or is a known GPL package
- Classify as `not-collected` for all others
- Record per-manifest: `{ "permissive_count": N, "copyleft_risk_count": N, "not_collected_count": N }`

For each manifest, emit:
- `manifest_file`, `manifest_type` (npm | maven | gradle | pip | poetry | go_mod | gemfile | cargo | dotnet | composer)
- `runtime_dep_count`, `dev_dep_count`, `has_lockfile`, `pinning_strategy`
- `wildcard_versions` (array), `deprecated_markers` (array)
- `license_summary` (counts), `runtime_deps` (array), `dev_deps` (array)

### DS2 — Architecture & Build Signals

Detect architectural patterns and build pipeline configuration, going deeper than the `/scan` stack detection.

**Architecture pattern detection:**

Detect the best-matching pattern from directory structure (record top match + confidence):

| Pattern | Signals | Confidence |
|---------|---------|-----------|
| `layered_mvc` | `controllers/`, `models/`, `views/`, `services/`, `repositories/` at same level | 0.80 |
| `hexagonal` | `domain/`, `application/`, `infrastructure/`, `adapters/` or `ports/` directories | 0.85 |
| `clean_architecture` | `entities/`, `usecases/`, `interfaces/` or `core/`, `application/`, `infrastructure/` | 0.80 |
| `cqrs` | `commands/`, `queries/`, `handlers/` at same level within a module | 0.85 |
| `event_driven` | `events/`, `handlers/`, `consumers/`, `producers/` or `subscribers/` directories | 0.75 |
| `modular_monolith` | `modules/` directory with self-contained feature sub-directories each having their own internal layers | 0.80 |
| `microservices` | Multiple top-level directories each with their own package manifest — already detected in context.json | 0.85 |
| `flat_monolith` | Everything under `src/` with no clear layer separation | 0.65 |

If multiple patterns match, select the one with highest confidence. Record `detected_pattern` and `confidence`.

**Layer violation indicators (static heuristics — read file content):**

For each source file in the codebase, check for cross-layer imports that violate the detected pattern:

- *Presentation imports infrastructure*: controller/route files (names under `controllers/`, `routes/`, `views/`, `api/`) that import database drivers (`pg`, `mysql2`, `mongoose`, `sqlalchemy`, `typeorm`, `jdbc`, `sequelize`) directly
- *Domain imports framework*: entity/domain files (names under `domain/`, `entities/`, `models/`) that import framework-specific types (`express.Request`, `@RestController`, `@Controller` annotations, Flask `request`)
- *Service has raw SQL*: service files (names under `services/`) that contain raw SQL strings (`SELECT`, `INSERT`, `UPDATE`, `DELETE` as string literals)
- *Infrastructure leaks to core*: files under `core/` or `usecases/` that import from `infrastructure/` or `adapters/`

For each violation found:
- `id`: `DS2-VIO-{NNN}` (sequential)
- `pattern`: `presentation_imports_infra | domain_imports_framework | service_has_raw_sql | infra_leaks_to_core`
- `location`: `{ "file": "{path}", "line": N }`
- `severity`: HIGH (core domain/infra boundary violated) | MEDIUM (service boundary violated) | LOW (minor coupling)
- `details`: brief description of what was found
- `suggested_fix`: one-line refactor hint

**Build pipeline analysis (read CI configs):**

Detect CI config files (same files as in QS4 of scan-qa-signals) and extract build-specific stages:
- `build_stages`: stage/job names that compile, bundle, or package artifacts
- `lint_stages`: stage/job names that run linters or formatters
- `type_check_stages`: stage/job names that run type checking (tsc, mypy, pyright)
- `deploy_stages`: stage/job names that deploy to any environment
- `artifact_registry`: `"not-collected"` unless an explicit registry push is detectable (`docker push`, `npm publish`, `mvn deploy`)

**Module/package structure health:**
- `total_top_level_dirs`: count of directories directly under `src/` or codebase root (excluding hidden dirs)
- `max_nesting_depth`: deepest directory nesting level (heuristic for structural complexity)
- `circular_dependency_indicators`: scan for patterns suggesting circular imports — two files in different modules each importing the other → `"possible"`. If none found → `"not-detected"`. If unable to determine → `"not-collected"`
- `shared_kernel_present`: `true | false` — does a `shared/`, `common/`, `core/`, `lib/`, `kernel/` directory exist alongside feature/domain modules?

### DS3 — Environment & Configuration

Catalog all environment variables, external service dependencies, secrets management, and local setup requirements.

**Environment variable detection:**

Look for variables in these sources (read in this order; later sources can augment earlier ones):
1. `.env.example`, `.env.template`, `.env.sample`, `.env.test` — KEY=value or KEY= (no value)
2. `.env.schema`, `env.yaml`, `env.json` — structured schemas
3. Docker Compose `environment:` sections — variable names with or without values
4. Config file templates: `config.template.yaml`, `application.properties.example`, `appsettings.Development.json`
5. README sections under headings matching: "Environment Variables", "Configuration", "Setup", "Prerequisites"

For each env var found, record:
- `name`: variable name
- `purpose`: description from inline comment or adjacent README text (`"not-collected"` if absent)
- `required`: `true` (no default value set) | `false` (default value present) | `"not-collected"` (cannot determine)
- `has_default`: `true | false`
- `default_value`: the value from .env.example/template, or `"not-collected"` if blank/absent
- `category`: `database | cache | auth | external_api | feature_flag | app_config | secret | not-collected` (infer from name patterns: `DB_`, `REDIS_`, `AUTH_`, `JWT_`, `API_KEY_`, etc.)
- `source_file`: path of the file where this variable was found

**External service dependencies:**

Detect from multiple sources:
- Docker Compose `services:` block — services beyond the app itself (postgres, redis, rabbitmq, kafka, elasticsearch, minio, keycloak, etc.)
- Database drivers in DS1 dependency manifests (cross-reference manifest dep names: `pg`, `mysql2`, `mongoose`, `redis`, etc.)
- API endpoint env vars in .env.example (look for `_URL=`, `_HOST=`, `_ENDPOINT=`, `_BASE_URL=` patterns)
- Auth service references (`AUTH_URL`, `OAUTH_URL`, `KEYCLOAK_`, `AUTH0_`, `COGNITO_`)
- Message broker references (`KAFKA_`, `RABBITMQ_`, `AMQP_`, `REDIS_STREAM_`, `SQS_`, `PUBSUB_`)
- Storage service references (`S3_`, `MINIO_`, `AZURE_STORAGE_`, `GCS_`)

For each external service:
- `name`: service name (postgres, redis, kafka, auth0, stripe-api, etc.)
- `type`: `database | cache | message_broker | auth_service | external_api | storage | monitoring | not-collected`
- `required_for`: `all_environments | dev_only | test_only | prod_only | not-collected` (infer from docker-compose profiles or README context)
- `mock_available`: `true | false | "not-collected"` — look for mock/stub/fake service in docker-compose.test.yml, `__mocks__/`, `mocks/`, `fakes/` directories, or WireMock / MockServer configs
- `local_setup_hint`: how to start locally (from docker-compose service name, README instruction) or `"not-collected"`

**Secrets management approach:**

Detect from imports and config:
- Hashicorp Vault: client library imports, `VAULT_ADDR` env var, `vault://` scheme in config → `vault`
- AWS Secrets Manager: `aws-sdk` + `secretsmanager` or `@aws-sdk/client-secrets-manager`, `SSM_PARAMETER_` env vars → `aws_secrets_manager`
- Azure Key Vault: `@azure/keyvault-secrets`, `AZURE_KEY_VAULT_URL` → `azure_key_vault`
- GCP Secret Manager: `@google-cloud/secret-manager`, `GCP_SECRET_` → `gcp_secret_manager`
- Kubernetes Secrets: `kind: Secret` in k8s manifests, `secretKeyRef` in env specs → `k8s_secrets`
- If none detected: `env_vars` (default)
- If multiple: `mixed`

**Hardcoded secret warnings** (scan non-test, non-example source files):
- Look for lines matching patterns: `password\s*[:=]\s*["'][^$\{][^"']{4,}["']`, `api_key\s*[:=]\s*["'][^$\{][^"']{8,}["']`, `secret\s*[:=]\s*["'][^$\{][^"']{8,}["']`, `token\s*[:=]\s*["'][^$\{][^"']{10,}["']`
- Exclude files matching: `*.test.*`, `*.spec.*`, `*.example`, `*.template`, `*.sample`, `*_test.go`, `test_*.py`, `*Test.java`
- For each warning: `{ "file": "...", "line": N, "pattern": "password_literal | api_key_literal | secret_literal | token_literal" }`

**Local setup complexity:**
- Look for numbered setup steps in README under setup-related headings
- Count distinct required manual steps (commands to run, files to edit, services to start)
- `setup_step_count`: N or `"not-collected"`
- `setup_complexity`: `simple` (1–3 steps) | `moderate` (4–7 steps) | `complex` (8+ steps) | `not-collected`
- `setup_documented`: `true` (any README setup section found) | `false`
- `docker_compose_available`: `true | false` (docker-compose.yml present in repo)

### DS4 — Code Health & Complexity

Analyze code health indicators using static heuristics. These are proxies — not a substitute for profiling or cyclomatic complexity tooling.

**Complexity hotspots:**

Identify files that are likely complex based on size:
- HIGH: files >500 LOC
- MEDIUM: files 300–500 LOC

Read source files (or estimate from byte size at ~50 bytes/line) to identify hotspots. Limit to the top 20 files by estimated LOC. For each:
- `file`, `loc_estimate` (or `"not-collected"` if byte-size proxy isn't usable)
- `complexity_indicator`: `HIGH | MEDIUM`
- `capability_area`: capability it belongs to (from l1-capabilities.md entry_points cross-reference) or `"not-collected"`

**Coupling hotspots (import fan-out):**

Scan source files for import statements and count unique imports per file:
- HIGH coupling: >15 import statements
- MEDIUM coupling: 10–15 import statements

Record the top 10 most-coupled files: `{ "file": "...", "import_count": N, "coupling": "HIGH | MEDIUM" }`

**Technical debt markers:**

Scan all source files (excluding generated files, vendored directories, `node_modules/`, `vendor/`, `.git/`) for comment tokens:
- `TODO`, `FIXME`, `HACK`, `XXX`, `DEBT`, `TEMP`, `KLUDGE`

For each top-level module/package directory, aggregate:
- `area`: directory path
- `todo_count`, `fixme_count`, `hack_count`: per-token counts
- `debt_density`: (todo_count + fixme_count + hack_count) / (loc_estimate / 1000) or `"not-collected"` if LOC is unavailable

**Documentation coverage proxy:**

Estimate the presence of documentation comments across source files:
- JavaScript/TypeScript: `/** */` JSDoc blocks
- Python: `"""` docstring at start of function/class body
- Java: `/** */` Javadoc
- Go: `// FunctionName ...` doc comments preceding exported symbols
- Ruby: `# @param`, `# @return`, yard comments

Estimate: count files that have at least one documentation comment block, divide by total source files.
- `doc_coverage_estimate`: percentage (0–100) or `"not-collected"`
- `doc_coverage_confidence`: HIGH (read source files directly) | LOW (estimated from file count only)

**Dead code indicators:**

Look for two signals:
1. Commented-out code blocks: 3+ consecutive lines that are all comments in source files (not docstrings/JSDoc headers) — record file count
2. Files with no inbound imports: source files under feature/module directories that have no import references found in the codebase (heuristic — flag as `possible_dead` with LOW confidence)

- `dead_code_file_count`: count of files with substantial commented-out blocks, or `"not-collected"`
- `confidence`: `LOW` (always — this is a heuristic)

## Output

Create directory structure if it doesn't exist:
```
docs/dev/
  dependency-analysis/
  architecture/
  environment/
  code-health/
```

Generate `docs/dev/dev-signals.json`:

```json
{
  "scan_metadata": {
    "timestamp": "{ISO 8601 timestamp}",
    "codebase_path": "{path from answers.json}",
    "signal_sources": ["DS1", "DS2", "DS3", "DS4"],
    "limitations": [
      "Dependency outdatedness requires network registry access — not assessed (pinning strategy used as proxy)",
      "Cyclomatic complexity requires language-specific tooling — LOC-based heuristics used instead",
      "License determination is best-effort from common dep names only — legal review required for compliance"
    ]
  },
  "dependency_inventory": {
    "manifests": [
      {
        "manifest_file": "{path}",
        "manifest_type": "npm | maven | gradle | pip | poetry | go_mod | gemfile | cargo | dotnet | composer",
        "runtime_dep_count": 0,
        "dev_dep_count": 0,
        "has_lockfile": true,
        "pinning_strategy": "strict | loose | none",
        "wildcard_versions": [],
        "deprecated_markers": [],
        "license_summary": { "permissive_count": 0, "copyleft_risk_count": 0, "not_collected_count": 0 },
        "runtime_deps": [{ "name": "{name}", "version": "{version}", "type": "runtime" }],
        "dev_deps": [{ "name": "{name}", "version": "{version}", "type": "dev" }]
      }
    ],
    "totals": {
      "runtime_deps": 0,
      "dev_deps": 0,
      "total_deps": 0,
      "wildcard_count": 0,
      "deprecated_count": 0,
      "lockfiles_present": true
    }
  },
  "architecture_signals": {
    "detected_pattern": "{pattern or 'not-detected'}",
    "confidence": "HIGH | MEDIUM | LOW | not-detected",
    "layer_violations": [
      {
        "id": "DS2-VIO-{NNN}",
        "pattern": "presentation_imports_infra | domain_imports_framework | service_has_raw_sql | infra_leaks_to_core",
        "location": { "file": "{path}", "line": 0 },
        "severity": "HIGH | MEDIUM | LOW",
        "details": "{description}",
        "suggested_fix": "{one-line hint}"
      }
    ],
    "build_pipeline": {
      "ci_systems": ["{name}"],
      "build_stages": ["{stage name}"],
      "lint_stages": ["{stage name}"],
      "type_check_stages": ["{stage name}"],
      "deploy_stages": ["{stage name}"],
      "artifact_registry": "not-collected"
    },
    "module_structure": {
      "total_top_level_dirs": 0,
      "max_nesting_depth": 0,
      "circular_dependency_indicators": "possible | not-detected | not-collected",
      "shared_kernel_present": true
    }
  },
  "environment_config": {
    "env_vars": [
      {
        "name": "{VAR_NAME}",
        "purpose": "{description or 'not-collected'}",
        "required": true,
        "has_default": false,
        "default_value": "not-collected",
        "category": "database | cache | auth | external_api | feature_flag | app_config | secret | not-collected",
        "source_file": "{path}"
      }
    ],
    "external_services": [
      {
        "name": "{service}",
        "type": "database | cache | message_broker | auth_service | external_api | storage | monitoring | not-collected",
        "required_for": "all_environments | dev_only | test_only | prod_only | not-collected",
        "mock_available": "not-collected",
        "local_setup_hint": "not-collected"
      }
    ],
    "secrets_management": {
      "approach": "vault | aws_secrets_manager | azure_key_vault | gcp_secret_manager | k8s_secrets | env_vars | mixed | not-collected",
      "hardcoded_secret_warnings": [
        { "file": "{path}", "line": 0, "pattern": "password_literal | api_key_literal | secret_literal | token_literal" }
      ]
    },
    "local_setup": {
      "setup_step_count": 0,
      "setup_complexity": "simple | moderate | complex | not-collected",
      "setup_documented": true,
      "docker_compose_available": true
    },
    "env_var_gap_summary": {
      "total_vars": 0,
      "required_without_default": 0,
      "not_documented": 0
    }
  },
  "code_health": {
    "complexity_hotspots": [
      {
        "file": "{path}",
        "loc_estimate": 0,
        "complexity_indicator": "HIGH | MEDIUM",
        "capability_area": "{capability or 'not-collected'}"
      }
    ],
    "coupling_hotspots": [
      {
        "file": "{path}",
        "import_count": 0,
        "coupling": "HIGH | MEDIUM"
      }
    ],
    "tech_debt_by_area": [
      {
        "area": "{directory}",
        "todo_count": 0,
        "fixme_count": 0,
        "hack_count": 0,
        "debt_density": "0.0 | not-collected"
      }
    ],
    "documentation": {
      "doc_coverage_estimate": 0,
      "doc_coverage_confidence": "HIGH | LOW | not-collected"
    },
    "dead_code": {
      "dead_code_file_count": "0 | not-collected",
      "confidence": "LOW"
    }
  },
  "summary": {
    "manifests_found": 0,
    "total_deps": 0,
    "wildcard_dep_count": 0,
    "deprecated_dep_count": 0,
    "lockfiles_present": true,
    "architecture_pattern": "{detected or 'not-detected'}",
    "layer_violations_count": 0,
    "high_severity_violations": 0,
    "env_vars_total": 0,
    "required_vars_without_default": 0,
    "external_services_count": 0,
    "services_without_mocks": 0,
    "hardcoded_secret_warnings": 0,
    "complexity_hotspots_count": 0,
    "high_complexity_files": 0,
    "tech_debt_markers_total": 0,
    "setup_complexity": "{level or 'not-collected'}",
    "not_collected_fields": ["{paths where not-collected was emitted}"]
  }
}
```

The `not_collected_fields` array must list every field path where `"not-collected"` was emitted (e.g., `["environment_config.env_vars[*].purpose", "code_health.dead_code.dead_code_file_count"]`). This drives the "Not-Collected Summary" in the dev readiness report.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `attach_dev_context`, `status` to `in_progress`
- Tell the user: "{manifests} manifest(s) scanned ({total_deps} total deps, {wildcards} wildcard versions, {violations} architecture violations, {env_vars} env vars catalogued, {hotspots} complexity hotspots, {secret_warnings} hardcoded secret warnings). {not_collected} fields recorded as not-collected. Next: attach dev context to capabilities."

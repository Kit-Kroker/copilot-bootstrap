---
name: scan-qa-signals
description: Extract QA signals from the codebase — test inventory, coverage signals, testability findings, and environment/CI quality gates. Emits "not-collected" when signals are absent rather than defaulting. Runs after discover-candidates. Use this when workflow step is "scan_qa" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/qa/qa-signals.json` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated QA analysis from external tools.

Read:
- `.project/state/answers.json` (specifically `codebase_setup`: path, language, architecture, has_frontend, and `qa_scope` if present: test_frameworks, coverage_targets, environment_parity_targets)
- The codebase at the configured path
- `docs/discovery/candidates.md` ← optional (for cross-referencing tests with capabilities)

## QA Context

Before scanning, read `qa_scope` from `.project/state/answers.json`. If not present, apply defaults:
- `test_frameworks`: `[]` (auto-detect)
- `coverage_targets`: `{ "unit": null, "integration": null, "e2e": null }` (null = not-collected, not zero)
- `environment_parity_targets`: `[]`
- `defect_sources`: `[]` (e.g., `["github_issues"]`, `["jira"]`)

**Not-collected is first-class.** Whenever a signal cannot be determined from static evidence, record it as `"not-collected"` rather than substituting `0`, `false`, or `"unknown"`. Downstream skills propagate this honestly through the SDET report and unified risk scoring.

## Signal Extraction (4 sub-steps)

### QS1 — Test Inventory

Detect test files and frameworks. For each framework found, count and classify tests by level.

**Framework detection (file patterns + config files):**
- JavaScript/TypeScript: `jest.config.*`, `vitest.config.*`, `playwright.config.*`, `cypress.config.*`, `.mocharc*`, `karma.conf.*`, test files `*.test.{ts,tsx,js,jsx}`, `*.spec.{ts,tsx,js,jsx}`, `__tests__/`
- Java: `pom.xml` / `build.gradle` with `junit`, `testng`, `mockito`, `rest-assured`, `selenium`, test files under `src/test/java/**`
- Python: `pytest.ini`, `pyproject.toml [tool.pytest]`, `tox.ini`, `tests/`, `test_*.py`, `*_test.py`
- Ruby: `Gemfile` with `rspec`, `minitest`, `spec/`, `test/`
- .NET: `*.Tests.csproj`, xunit/nunit/mstest refs, `*Tests.cs`
- Go: `*_test.go`, `testify` imports
- Rust: `#[test]` attributes, `tests/` integration dirs

**Level classification (heuristics — record confidence):**
- `unit`: files under `unit/`, `__tests__/` without external I/O imports, no DB/HTTP mocks beyond framework fakes
- `integration`: imports real DB drivers, spins up containers (`testcontainers`), hits `http://localhost`, reads `test-data/`
- `e2e`: playwright/cypress/selenium imports, browser drivers, `e2e/` directory
- `contract`: pact, spring-cloud-contract, openapi-contract-validator imports
- `performance`: k6, gatling, jmeter, locust imports
- `unknown`: matched file patterns but cannot classify — record as `unknown` (distinct from `not-collected`)

For each framework detected:
- `framework`: name (e.g., `jest`, `junit5`, `pytest`)
- `version`: declared version (from lockfile/manifest) or `"not-collected"`
- `config_files`: array of paths
- `test_counts`: `{ "unit": N, "integration": N, "e2e": N, "contract": N, "performance": N, "unknown": N }`
- `test_files_total`: N
- `confidence`: HIGH (explicit config + files) | MEDIUM (files without config) | LOW (guessed from manifest refs only)

If no test frameworks are detected at all, emit a single inventory entry with `framework: "none-detected"` and `test_counts` all zero. Do not coerce to `"not-collected"` for counts you can confirm are zero — zero means "we looked and found nothing", not-collected means "we couldn't look".

### QS2 — Coverage Signals

Look for coverage configuration and reports:

**Coverage tools:**
- JS/TS: `nyc`, `c8`, jest `collectCoverage`, `coverage/` directory, `lcov.info`, `coverage-final.json`
- Java: `jacoco` plugin, `target/site/jacoco/`, `jacoco.xml`
- Python: `coverage.py`, `pytest --cov`, `.coverage`, `coverage.xml`, `htmlcov/`
- .NET: `coverlet`, `*.cobertura.xml`
- Go: `go test -cover`, `coverage.out`
- Ruby: `simplecov`, `coverage/`

For each coverage signal:
- `tool`: detected tool name
- `config_location`: where configured (file path)
- `thresholds_declared`: `{ "lines": N | "not-collected", "branches": N | "not-collected", "statements": N | "not-collected", "functions": N | "not-collected" }` — only fill values that are explicitly declared
- `last_measured`: `{ "lines": N, "branches": N, ... }` from committed report if present; else all `"not-collected"`
- `report_paths`: array of report artifact paths found
- `confidence`: HIGH (report present) | MEDIUM (config present, no report) | LOW (manifest dep only)

**Proxy coverage per capability** (when direct coverage per file/module isn't available): for each L1 capability, compute:
- `test_files_touching_capability`: count of test files whose paths overlap capability owned-code paths (from `candidates.md` or domain-model.md entry_points)
- `tests_per_kloc`: test files / 1000 lines-of-code in capability (rough proxy — flag confidence=LOW)

Record proxy coverage as `"not-collected"` if capability owned-code paths can't be determined.

### QS3 — Testability Findings

Identify code-level testability issues that inflate test difficulty or flakiness risk:

**Hard-to-test patterns:**
- **Static singletons accessed directly**: `GlobalConfig.instance`, `DateTime.Now` / `new Date()` used inline in business logic (not wrapped in a clock abstraction)
- **Hidden dependencies**: classes that `new` their collaborators instead of receiving them via DI
- **Non-injectable I/O**: `File.read()`, `fs.readFileSync()`, direct HTTP calls in domain code
- **Sleep/timing coupling**: `Thread.sleep`, `setTimeout` in logic (not test helpers)
- **God objects**: classes over 500 lines with multiple responsibilities — hard to isolate
- **Unseeded randomness**: `Math.random()`, `UUID.randomUUID()` without injection seams
- **Environment-dependent logic**: `process.env.NODE_ENV === 'production'` branches in domain code
- **No public seams for mocking**: final/sealed classes, private constructors, missing interfaces in layered code that clearly wants them

For each finding:
- `id`: `QS3-{category}-{NNN}`
- `category`: `singleton | hidden_deps | io_in_domain | timing | god_object | randomness | env_coupling | missing_seams`
- `location`: `{ "file": "...", "line": N }`
- `severity`: HIGH (blocks isolation, forces integration tests) | MEDIUM (workarounds available) | LOW (minor friction)
- `details`: specific finding description
- `suggested_fix`: one-line refactor hint

### QS4 — Environment & CI Quality Gates

Detect CI pipelines and quality gate configuration:

**CI detection:**
- `.github/workflows/*.yml` (GitHub Actions)
- `.gitlab-ci.yml`, `gitlab-ci/*.yml`
- `azure-pipelines.yml`, `.azure/`
- `Jenkinsfile`, `jenkins/`
- `.circleci/config.yml`
- `bitbucket-pipelines.yml`
- `buildkite/`, `.buildkite/pipeline.yml`

For each CI config found, extract:
- `ci_system`: name
- `file`: path
- `test_stages_present`: array of stage names that run tests (e.g., `["unit-test", "integration-test", "e2e"]`)
- `quality_gates`: array of `{ "type": "coverage_threshold | lint | type_check | security_scan | test_pass", "configured": true | false | "not-collected", "blocking": true | false | "not-collected" }`
- `branch_protection_hint`: `true | false | "not-collected"` (look for required-status-checks references if detectable from repo config)

**Environment parity:**
- Docker Compose files: `docker-compose*.yml`, `compose*.yml`
- Infrastructure-as-code: `terraform/`, `pulumi/`, `cdk/`, `kubernetes/`
- Test environment scripts: `scripts/test-env-*`, `ops/env-*`

For each environment artifact:
- `type`: `docker_compose | terraform | k8s | script | other`
- `file`: path
- `environments_defined`: array (e.g., `["dev", "staging", "test"]`) if inferable, else `"not-collected"`
- `parity_indicators`: array of signals suggesting prod-parity (e.g., `"uses same DB engine as prod"`, `"shares helm chart with prod"`) — can be empty if parity cannot be determined

**Defect profile (static only):**
- Check for issue-template config: `.github/ISSUE_TEMPLATE/`, `.gitlab/issue_templates/`
- Check for CHANGELOG.md entries matching bug/fix patterns
- Record `defect_density`: `"not-collected"` unless `qa_scope.defect_sources` was set and signals are available. Do NOT fabricate.

**Change velocity (static only):**
- For each capability's owned paths: count commits in last 90 days (via git log if runnable), else `"not-collected"`
- `hotspots`: files with commits > 20 in last 90 days (if measurable)

## Output

Create directory structure if it doesn't exist:
```
docs/qa/
  coverage/
  testability/
  defects/
  environments/
  generate/
    capability-contexts/
```

Generate `docs/qa/qa-signals.json`:

```json
{
  "scan_metadata": {
    "timestamp": "{ISO 8601 timestamp}",
    "codebase_path": "{path from answers.json}",
    "qa_scope": {
      "test_frameworks_declared": ["..."],
      "coverage_targets": { "unit": null, "integration": null, "e2e": null },
      "environment_parity_targets": ["..."],
      "defect_sources": ["..."]
    },
    "signal_sources": ["QS1", "QS2", "QS3", "QS4"],
    "limitations": [
      "Defect density, change velocity, and real coverage percentages require external/runtime data — emitted as 'not-collected' when unavailable"
    ]
  },
  "test_inventory": [
    {
      "framework": "{name}",
      "version": "{version or 'not-collected'}",
      "config_files": ["{path}"],
      "test_counts": { "unit": 0, "integration": 0, "e2e": 0, "contract": 0, "performance": 0, "unknown": 0 },
      "test_files_total": 0,
      "confidence": "HIGH | MEDIUM | LOW"
    }
  ],
  "coverage_signals": [
    {
      "tool": "{name}",
      "config_location": "{path}",
      "thresholds_declared": { "lines": 0, "branches": "not-collected", "statements": "not-collected", "functions": "not-collected" },
      "last_measured": { "lines": "not-collected", "branches": "not-collected", "statements": "not-collected", "functions": "not-collected" },
      "report_paths": ["{path}"],
      "confidence": "HIGH | MEDIUM | LOW"
    }
  ],
  "proxy_coverage": [
    {
      "capability_id": "BC-{NNN}",
      "test_files_touching_capability": 0,
      "tests_per_kloc": 0.0,
      "confidence": "LOW | MEDIUM | not-collected"
    }
  ],
  "testability_findings": [
    {
      "id": "QS3-{category}-{NNN}",
      "category": "singleton | hidden_deps | io_in_domain | timing | god_object | randomness | env_coupling | missing_seams",
      "location": { "file": "{path}", "line": 0 },
      "severity": "HIGH | MEDIUM | LOW",
      "details": "{description}",
      "suggested_fix": "{one-line hint}"
    }
  ],
  "ci_and_environment": {
    "ci_configs": [
      {
        "ci_system": "{name}",
        "file": "{path}",
        "test_stages_present": ["..."],
        "quality_gates": [
          { "type": "coverage_threshold", "configured": true, "blocking": "not-collected" }
        ],
        "branch_protection_hint": "not-collected"
      }
    ],
    "environment_artifacts": [
      {
        "type": "docker_compose | terraform | k8s | script | other",
        "file": "{path}",
        "environments_defined": ["..."],
        "parity_indicators": ["..."]
      }
    ],
    "defect_profile": {
      "source": "not-collected",
      "density_per_capability": "not-collected",
      "notes": ["..."]
    },
    "change_velocity": {
      "measured": false,
      "hotspots": [],
      "notes": ["..."]
    }
  },
  "summary": {
    "frameworks_detected": 0,
    "test_files_total": 0,
    "unit_tests_total": 0,
    "integration_tests_total": 0,
    "e2e_tests_total": 0,
    "coverage_tools_detected": 0,
    "coverage_measured": false,
    "testability_findings_count": 0,
    "high_severity_testability_count": 0,
    "ci_systems_detected": 0,
    "not_collected_fields": ["..."]
  }
}
```

The `not_collected_fields` summary array must list every top-level field or nested path where `"not-collected"` was emitted (e.g., `["coverage_signals[*].last_measured", "ci_and_environment.defect_profile.density_per_capability"]`). This drives the "Not-Collected Summary" in the SDET report.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `attach_qa_context`, `status` to `in_progress`
- Tell the user: "{N} QA signals extracted ({frameworks} frameworks, {tests} test files total, {testability} testability findings, {ci} CI configs). {not_collected} fields recorded as not-collected. Next: attach QA context to capabilities."

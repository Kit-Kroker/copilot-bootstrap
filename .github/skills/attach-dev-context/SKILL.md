---
name: attach-dev-context
description: Map developer-perspective signals (dependency health, architecture fitness, environment complexity, code health) to each L1/L2 capability. Computes a per-capability dev posture rollup for downstream readiness analysis. Runs after scan-dev-signals in the dev lane of /assess.
---

# Skill Instructions

**Pre-generated input check:** If `docs/dev/capability-dev-contexts.json` already exists, report that it was found and skip to the next step.

Read:
- `docs/dev/dev-signals.json` ← required
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required (if present)
- `docs/discovery/domain-model.md` ← required (for capability owned file paths)
- `docs/discovery/coverage.md` ← optional (for additional file-to-capability mapping)

## Context Attachment

For each L1 capability, determine its **owned file paths** by reading `domain-model.md → entry_points` and `owned_modules`. Use `coverage.md` as a supplementary source if domain-model.md paths are insufficient.

Then attach four context sections per capability by cross-referencing the owned paths against `dev-signals.json` findings.

**Not-collected propagation rule:** If the owned paths for a capability cannot be determined (e.g., domain-model.md doesn't list them), emit `"not-collected"` for every sub-field in that section rather than guessing. Do NOT default to `0` or `false`.

### Section 1 — Dependency Context

Cross-reference owned paths against `dev-signals.json → dependency_inventory`:

- `deps_owned`: list of dependency names imported by files within the capability's owned paths (heuristic: if the dep name appears in import statements in those files, include it). If cross-referencing is not feasible, record `"not-collected"`.
- `runtime_dep_count`: count of runtime deps in `deps_owned`
- `dev_dep_count`: count of dev deps in `deps_owned`
- `wildcard_deps_in_capability`: subset of `dev-signals.json → dependency_inventory.manifests[*].wildcard_versions` that are included in `deps_owned`
- `deprecated_markers_in_capability`: subset of `deprecated_markers` included in `deps_owned`
- `dependency_health`:
  - `healthy`: `deps_owned` not empty AND no wildcard versions AND no deprecated markers
  - `at_risk`: any wildcard versions OR deprecated markers present in `deps_owned`
  - `not-collected`: `deps_owned` is `"not-collected"` or cannot be determined

### Section 2 — Architecture Context

Cross-reference owned paths against `dev-signals.json → architecture_signals.layer_violations`:

- `layer_violations_in_capability`: count of DS2-VIO violations whose `location.file` is within the capability's owned paths
- `high_severity_violations_in_capability`: count of those violations with `severity = "HIGH"`
- `violation_ids`: array of `DS2-VIO-{NNN}` IDs found in owned paths
- `architecture_health`:
  - `healthy`: `layer_violations_in_capability = 0`
  - `at_risk`: any violation with `severity = "HIGH"` in owned paths
  - `needs_attention`: only LOW or MEDIUM violations in owned paths
  - `not-collected`: owned paths could not be determined

### Section 3 — Environment Context

Cross-reference owned paths against `dev-signals.json → environment_config`:

- `required_env_vars`: env var names from `environment_config.env_vars` whose `category` or `name` is functionally related to this capability. Use heuristic matching: if a capability name token (e.g., "payments", "auth", "orders") appears as a prefix in the env var name, or if the var category maps to a service this capability owns, include it.
- `required_env_vars_without_default`: count of `required_env_vars` where `required = true` AND `has_default = false`
- `external_services_used`: external service names from `environment_config.external_services` relevant to this capability (same heuristic — capability name token in service name, or service type matches capability function)
- `services_without_mocks`: count of `external_services_used` where `mock_available = false`
- `hardcoded_secrets_in_capability`: count of `secrets_management.hardcoded_secret_warnings` whose `file` is in owned paths
- `environment_complexity`:
  - `low`: `required_env_vars_without_default = 0` AND `services_without_mocks = 0` AND `hardcoded_secrets_in_capability = 0`
  - `medium`: `required_env_vars_without_default > 0` OR `services_without_mocks = 1`
  - `high`: `required_env_vars_without_default > 1` OR `services_without_mocks > 1` OR `hardcoded_secrets_in_capability > 0`
  - `not-collected`: env vars or external services could not be cross-referenced

### Section 4 — Code Health Context

Cross-reference owned paths against `dev-signals.json → code_health`:

- `complexity_hotspots_in_capability`: count of files in `code_health.complexity_hotspots` whose `file` is in owned paths
- `high_complexity_files`: array of file paths with `complexity_indicator = "HIGH"` in owned paths
- `tech_debt_density`: average `debt_density` across `code_health.tech_debt_by_area` entries whose `area` path overlaps owned paths; or `"not-collected"` if none match
- `coupling_hotspots_in_capability`: count of files in `code_health.coupling_hotspots` with `coupling = "HIGH"` in owned paths
- `doc_coverage_estimate`: from global `code_health.documentation.doc_coverage_estimate` (apply globally unless per-capability is available) or `"not-collected"`
- `code_health`:
  - `healthy`: `complexity_hotspots_in_capability = 0` AND `tech_debt_density < 1.0` (or not-collected) AND `coupling_hotspots_in_capability = 0`
  - `needs_attention`: 1–2 high-complexity files OR `tech_debt_density` between 1.0–3.0 OR 1 high-coupling file
  - `at_risk`: 3+ high-complexity files OR `tech_debt_density > 3.0` OR 2+ high-coupling files
  - `not-collected`: owned paths could not be determined

### Dev Posture Rollup

Based on the four health signals, compute `dev_posture` for the capability:

| Condition | dev_posture |
|-----------|-------------|
| All 4 health signals are `healthy` | `ready` |
| Any `hardcoded_secrets_in_capability > 0` | `blocked` (override — regardless of other signals) |
| Any 2+ sections are `at_risk` | `blocked` |
| Any 1 section is `at_risk` OR any 1 section is `needs_attention` | `needs_attention` |
| 3+ sections are `not-collected` | `unknown` |

## Output

Generate `docs/dev/capability-dev-contexts.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "capabilities": [
    {
      "capability_id": "BC-{NNN}",
      "capability_name": "{name}",
      "owned_paths": ["{path}", "..."],
      "dependency_context": {
        "deps_owned": ["{dep-name}", "..."],
        "runtime_dep_count": 0,
        "dev_dep_count": 0,
        "wildcard_deps_in_capability": [],
        "deprecated_markers_in_capability": [],
        "dependency_health": "healthy | at_risk | not-collected"
      },
      "architecture_context": {
        "layer_violations_in_capability": 0,
        "high_severity_violations_in_capability": 0,
        "violation_ids": [],
        "architecture_health": "healthy | needs_attention | at_risk | not-collected"
      },
      "environment_context": {
        "required_env_vars": ["{VAR_NAME}", "..."],
        "required_env_vars_without_default": 0,
        "external_services_used": ["{service}", "..."],
        "services_without_mocks": 0,
        "hardcoded_secrets_in_capability": 0,
        "environment_complexity": "low | medium | high | not-collected"
      },
      "code_health_context": {
        "complexity_hotspots_in_capability": 0,
        "high_complexity_files": [],
        "tech_debt_density": "0.0 | not-collected",
        "coupling_hotspots_in_capability": 0,
        "doc_coverage_estimate": "0 | not-collected",
        "code_health": "healthy | needs_attention | at_risk | not-collected"
      },
      "dev_posture": "ready | needs_attention | blocked | unknown"
    }
  ],
  "posture_summary": {
    "ready_count": 0,
    "needs_attention_count": 0,
    "blocked_count": 0,
    "unknown_count": 0,
    "total_capabilities": 0
  }
}
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `analyze_dev_readiness`, `status` to `in_progress`
- Tell the user: "{N} capabilities enriched with dev context. Posture: {ready} ready, {needs_attention} needs attention, {blocked} blocked, {unknown} unknown. Next: analyze dev readiness and identify blockers."

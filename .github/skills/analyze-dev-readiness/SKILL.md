---
name: analyze-dev-readiness
description: Compute per-capability developer readiness scores across four weighted dimensions (dependency health, environment complexity, code health, integration risk) and identify explicit implementation blockers. Renormalizes weights when dimensions are not-collected rather than defaulting. Runs after attach-dev-context in the dev lane of /assess.
---

# Skill Instructions

**Pre-generated input check:** If `docs/dev/dev-readiness-scores.json` already exists, report that it was found and skip to the next step.

Read:
- `docs/dev/capability-dev-contexts.json` ← required
- `docs/dev/dev-signals.json` ← required
- `docs/qa/qa-risk-scores.json` ← optional (to detect capabilities with compounded QA + dev risk)
- `docs/security/risk-scores.json` ← optional (for cross-dimension context in blocker descriptions)

## Readiness Dimensions

Score each capability across 4 dimensions. Each dimension produces a risk value from `0.0` (no risk) to `1.0` (maximum risk). Emit `"not-collected"` only when the underlying signals are entirely absent — never default to a neutral value like `0.5` when data is unavailable.

**Dimension weights** (sum to 1.0):
- Dependency Health: **0.25**
- Environment Complexity: **0.25**
- Code Health: **0.30**
- Integration Risk: **0.20**

---

### Dimension 1 — Dependency Health (weight: 0.25)

Source: `capability-dev-contexts.json → dependency_context`

| Signal | Risk Value |
|--------|-----------|
| `dependency_health = "healthy"` | 0.0 |
| `wildcard_deps_in_capability` has 1–2 entries | 0.3 |
| `wildcard_deps_in_capability` has 3+ entries | 0.5 |
| `deprecated_markers_in_capability` has 1 entry | 0.5 |
| `deprecated_markers_in_capability` has 2+ entries | 0.8 |
| Both wildcards AND deprecated markers present | max of individual scores + 0.1, capped at 1.0 |
| `dependency_health = "not-collected"` | `"not-collected"` |

---

### Dimension 2 — Environment Complexity (weight: 0.25)

Source: `capability-dev-contexts.json → environment_context`

| Signal | Risk Value |
|--------|-----------|
| `environment_complexity = "low"` | 0.0 |
| `environment_complexity = "medium"` | 0.4 |
| `environment_complexity = "high"` | 0.8 |
| `hardcoded_secrets_in_capability > 0` (add-on) | +0.2, capped at 1.0 |
| `required_env_vars_without_default > 2` (add-on) | +0.15, capped at 1.0 |
| `environment_complexity = "not-collected"` | `"not-collected"` |

---

### Dimension 3 — Code Health (weight: 0.30)

Source: `capability-dev-contexts.json → code_health_context`

| Signal | Risk Value |
|--------|-----------|
| `code_health = "healthy"` | 0.0 |
| `code_health = "needs_attention"` | 0.4 |
| `code_health = "at_risk"` | 0.75 |
| `complexity_hotspots_in_capability >= 3` (add-on) | +0.15, capped at 1.0 |
| `tech_debt_density > 3.0` per KLOC (add-on) | +0.1, capped at 1.0 |
| `coupling_hotspots_in_capability > 2` (add-on) | +0.1, capped at 1.0 |
| `code_health = "not-collected"` | `"not-collected"` |

---

### Dimension 4 — Integration Risk (weight: 0.20)

Source: `capability-dev-contexts.json → environment_context` + `dev-signals.json → environment_config.external_services`

| Signal | Risk Value |
|--------|-----------|
| No external services used by this capability | 0.0 |
| All external services used have `mock_available = true` | 0.1 |
| 1 service with `mock_available = false` | 0.4 |
| 2+ services with `mock_available = false` | 0.7 |
| `hardcoded_secrets_in_capability > 0` (override) | 0.9 (replaces computed value) |
| `mock_available = "not-collected"` for all services | `"not-collected"` |

---

## Composite Score Computation

```
dev_composite = Σ (dimension_risk × weight) for all available dimensions
```

**Weight renormalization when dimensions are not-collected:**

If any dimension returns `"not-collected"`, redistribute its weight proportionally among the remaining available dimensions. Example: if Dimension 4 (0.20) is not-collected, remaining weights are renormalized: 0.25/0.80→0.3125, 0.25/0.80→0.3125, 0.30/0.80→0.375.

**Composite status:**
- `complete`: all 4 dimensions available
- `partial`: 1–3 dimensions available (record which)
- `unknown`: 0 dimensions available (all not-collected)

---

## Readiness Status

| dev_composite | Readiness Status |
|--------------|-----------------|
| 0.0 – 0.39 | `READY` |
| 0.40 – 0.69 | `NEEDS_ATTENTION` |
| 0.70 – 1.00 | `BLOCKED` |
| (any `CRITICAL` or `HIGH` blocker present for this capability) | `BLOCKED` (regardless of composite score) |

---

## Blocker Detection

A **blocker** is an issue that must be resolved before implementation can safely start. Blockers are explicit, not derived from the composite score — they are independently emitted alongside it.

Evaluate each condition below across all capabilities and globally. Record each triggered blocker.

**Blocker categories and triggers:**

| Category | Trigger | Severity |
|---------|---------|---------|
| `hardcoded_secrets` | `dev-signals.json → environment_config.secrets_management.hardcoded_secret_warnings` is non-empty AND the warning file is NOT in a test/example path | CRITICAL |
| `missing_required_env_vars` | `required_env_vars_without_default > 0` AND `setup_documented = false` (no README guidance) | HIGH |
| `no_local_setup_guide` | `dev-signals.json → environment_config.local_setup.setup_documented = false` AND `external_services_count > 1` | HIGH |
| `deprecated_critical_deps` | `deprecated_markers_in_capability` non-empty for a capability with `code_health != "not-collected"` | HIGH |
| `missing_service_mocks` | `services_without_mocks > 0` AND `external_services_used` includes a service of type `database` or `message_broker` | HIGH |
| `architecture_violations` | `high_severity_violations_in_capability > 0` for a capability | MEDIUM |
| `loose_pinning` | `pinning_strategy = "none"` in any manifest (wildcards present) | MEDIUM |
| `circular_deps` | `architecture_signals.module_structure.circular_dependency_indicators = "possible"` | MEDIUM |

For each triggered blocker, emit:
- `id`: `DEV-BLK-{NNN}` (sequential, 001-based)
- `category`: one of the above
- `capability_id`: `"BC-{NNN}"` if capability-specific; `"global"` if project-wide
- `severity`: CRITICAL | HIGH | MEDIUM
- `description`: what the blocker is (specific, concrete — name the file, dep, service, or env var)
- `resolution`: how to resolve it (specific action — not "fix it")

---

## Output

Generate `docs/dev/dev-readiness-scores.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "capabilities": [
    {
      "capability_id": "BC-{NNN}",
      "capability_name": "{name}",
      "dimensions": {
        "dependency_health": {
          "risk": 0.0,
          "weight": 0.25,
          "status": "complete | not-collected",
          "signals": ["{e.g., 'no wildcard versions', '1 deprecated marker: dep-name'}"]
        },
        "environment_complexity": {
          "risk": 0.4,
          "weight": 0.25,
          "status": "complete | not-collected",
          "signals": ["{e.g., '2 required env vars without defaults', '1 service without mock'}"]
        },
        "code_health": {
          "risk": 0.75,
          "weight": 0.30,
          "status": "complete | not-collected",
          "signals": ["{e.g., '3 high-complexity files', 'debt density 4.2/KLOC'}"]
        },
        "integration_risk": {
          "risk": 0.4,
          "weight": 0.20,
          "status": "complete | not-collected",
          "signals": ["{e.g., '1 database service without mock available'}"]
        }
      },
      "dev_composite": 0.0,
      "dev_composite_status": "complete | partial | unknown",
      "readiness_status": "READY | NEEDS_ATTENTION | BLOCKED",
      "blocker_ids": ["DEV-BLK-{NNN}"],
      "primary_risk_drivers": ["{top 1–2 dimension names driving the composite score}"]
    }
  ],
  "risk_ranking": [
    {
      "rank": 1,
      "capability_id": "BC-{NNN}",
      "capability_name": "{name}",
      "dev_composite": 0.0,
      "readiness_status": "READY | NEEDS_ATTENTION | BLOCKED",
      "primary_driver": "{dimension name}"
    }
  ],
  "summary": {
    "ready_count": 0,
    "needs_attention_count": 0,
    "blocked_count": 0,
    "total_capabilities": 0,
    "composite_status_breakdown": {
      "complete": 0,
      "partial": 0,
      "unknown": 0
    }
  }
}
```

Generate `docs/dev/dev-blockers.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "blockers": [
    {
      "id": "DEV-BLK-{NNN}",
      "category": "hardcoded_secrets | missing_required_env_vars | no_local_setup_guide | deprecated_critical_deps | missing_service_mocks | architecture_violations | loose_pinning | circular_deps",
      "capability_id": "BC-{NNN} | global",
      "severity": "CRITICAL | HIGH | MEDIUM",
      "description": "{specific, concrete description — name the file, dep, var, or service}",
      "resolution": "{specific action to resolve — not generic advice}"
    }
  ],
  "summary": {
    "critical_count": 0,
    "high_count": 0,
    "medium_count": 0,
    "total_count": 0,
    "capabilities_blocked": 0,
    "global_blockers": 0
  }
}
```

After generating both files:
- Update `.project/state/workflow.json`: set `step` to `generate_dev_readiness_report`, `status` to `in_progress`
- Tell the user: "{N} capabilities scored. {blocked} BLOCKED, {needs_attention} NEEDS_ATTENTION, {ready} READY. {total_blockers} blockers identified ({critical} CRITICAL, {high} HIGH, {medium} MEDIUM). Next: generate dev readiness report."

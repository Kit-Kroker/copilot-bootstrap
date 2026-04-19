---
name: attach-qa-context
description: Attach QA context (coverage, testability, automation, defect profile) to each L1/L2 capability using QA signals. Propagates "not-collected" values honestly. Use this when workflow step is "attach_qa_context" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/qa/capability-qa-contexts.json` already exists, report that it was found and skip to the next step.

Read:
- `docs/qa/qa-signals.json` ← required
- `docs/discovery/domain-model.md` ← required
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required
- `.project/state/answers.json` (qa_scope)

## Process

### QC1 — Map QA Signals to Capabilities

For each L1 and L2 capability, pull relevant signals from `qa-signals.json`:

**Test inventory mapping:** For each capability, aggregate test files whose paths overlap capability owned-code paths (from domain-model.md entry_points and candidates.md ownership). Count by level (unit, integration, e2e, contract, performance, unknown).

**Coverage mapping:** From `proxy_coverage` entries matching the capability id, surface `test_files_touching_capability` and `tests_per_kloc`. Also pull the nearest coverage tool's `last_measured` and `thresholds_declared` — they apply globally unless tool config scopes to a sub-path.

**Testability mapping:** From `testability_findings`, include findings whose `location.file` falls under the capability's owned paths.

**CI & environment mapping:** CI configs and environment artifacts generally apply globally. Surface the project-level summary for each capability unless a CI stage name explicitly names the capability or a sub-path.

If owned paths cannot be determined for a capability, set the relevant fields to `"not-collected"` — do not silently substitute zero.

### QC2 — Build QA Context Per Capability

For each capability (L1 and L2), construct:

**Automation status:**
- `has_unit_tests`: `true | false | "not-collected"`
- `has_integration_tests`: `true | false | "not-collected"`
- `has_e2e_tests`: `true | false | "not-collected"`
- `has_contract_tests`: `true | false | "not-collected"`
- `test_levels_present`: deduplicated array of levels with ≥1 test

**Coverage summary:**
- `tests_per_kloc`: number or `"not-collected"`
- `measured_coverage`: `{ "lines": 0 | "not-collected", "branches": 0 | "not-collected" }` (inherited from nearest tool config)
- `thresholds_declared`: inherited from nearest tool config or `"not-collected"`
- `coverage_gap_indicator`: `none | low | moderate | high | "not-collected"`
  - `none`: measured ≥ threshold, or tests_per_kloc ≥ 10 (proxy)
  - `low`: measured within 10% of threshold, or tests_per_kloc 5–10
  - `moderate`: measured 10–25% below threshold, or tests_per_kloc 2–5
  - `high`: measured >25% below threshold, or tests_per_kloc <2
  - `"not-collected"`: neither measured coverage nor proxy coverage available

**Testability summary:**
- `findings_count`: number of testability findings in this capability
- `high_severity_findings`: count
- `top_issues`: up to 3 descriptions from the highest-severity findings
- `testability_rating`: `good | fair | poor | "not-collected"`
  - `good`: 0 HIGH findings, ≤2 MEDIUM
  - `fair`: 1–2 HIGH findings, or 3–5 MEDIUM
  - `poor`: ≥3 HIGH findings
  - `"not-collected"`: capability owned-paths couldn't be mapped

**Defect profile:**
- `defects_last_90_days`: number or `"not-collected"`
- `defect_density`: number or `"not-collected"`
- `defect_source`: `"not-collected"` unless `qa_scope.defect_sources` was set

**Change velocity:**
- `commits_last_90_days`: number or `"not-collected"`
- `hotspot_files`: array of file paths or `"not-collected"`

**CI posture (global context inherited):**
- `ci_system`: name or `"not-collected"`
- `test_stages_run_on_pr`: array or `"not-collected"`
- `blocking_quality_gates`: array of gate types that block merges or `"not-collected"`

**Environment parity:**
- `shared_infrastructure_with_prod`: `true | false | "not-collected"`
- `parity_notes`: array

**Relevant signals:** List QA signal IDs that fed this context.

### QC3 — Roll Up Capability QA Posture

For each capability, compute a `qa_posture`:
- `strong`: tests at ≥2 levels, coverage_gap_indicator ≤ low, testability_rating = good
- `adequate`: tests at ≥1 level, coverage_gap_indicator ≤ moderate, testability_rating ≤ fair
- `weak`: missing a level the capability's criticality demands, OR coverage_gap_indicator = high, OR testability_rating = poor
- `unknown`: ≥2 of (coverage, testability, test inventory) are `"not-collected"`

## Output

Generate `docs/qa/capability-qa-contexts.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "contexts": [
    {
      "capability_id": "BC-001",
      "capability_name": "{name}",
      "qa_context": {
        "automation_status": {
          "has_unit_tests": true,
          "has_integration_tests": false,
          "has_e2e_tests": "not-collected",
          "has_contract_tests": false,
          "test_levels_present": ["unit"]
        },
        "coverage": {
          "tests_per_kloc": 3.2,
          "measured_coverage": { "lines": "not-collected", "branches": "not-collected" },
          "thresholds_declared": "not-collected",
          "coverage_gap_indicator": "moderate"
        },
        "testability": {
          "findings_count": 4,
          "high_severity_findings": 1,
          "top_issues": ["..."],
          "testability_rating": "fair"
        },
        "defect_profile": {
          "defects_last_90_days": "not-collected",
          "defect_density": "not-collected",
          "defect_source": "not-collected"
        },
        "change_velocity": {
          "commits_last_90_days": "not-collected",
          "hotspot_files": "not-collected"
        },
        "ci_posture": {
          "ci_system": "github_actions",
          "test_stages_run_on_pr": ["unit-test"],
          "blocking_quality_gates": "not-collected"
        },
        "environment_parity": {
          "shared_infrastructure_with_prod": "not-collected",
          "parity_notes": []
        },
        "qa_posture": "adequate",
        "relevant_signals": ["QS1-...", "QS3-..."]
      },
      "l2_contexts": [
        {
          "capability_id": "BC-001-01",
          "capability_name": "{L2 name}",
          "qa_context": { "... same shape as L1 ..." }
        }
      ]
    }
  ],
  "summary": {
    "capabilities_assessed": 0,
    "strong_posture_count": 0,
    "adequate_posture_count": 0,
    "weak_posture_count": 0,
    "unknown_posture_count": 0,
    "high_coverage_gap_count": 0,
    "poor_testability_count": 0,
    "not_collected_fields_per_capability": { "BC-001": ["defect_profile.*", "change_velocity.*"] }
  }
}
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `qa_risk_analysis`, `status` to `in_progress`
- Tell the user: "QA context attached to {N} capabilities ({strong} strong, {adequate} adequate, {weak} weak, {unknown} unknown). Next: QA risk analysis."

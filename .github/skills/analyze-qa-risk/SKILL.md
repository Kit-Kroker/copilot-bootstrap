---
name: analyze-qa-risk
description: Compute per-capability QA risk scores across coverage gap, testability, defect density, and change velocity. Emits "unknown" when inputs are not-collected rather than defaulting to zero. Use this when workflow step is "qa_risk_analysis" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/qa/qa-risk-scores.json` already exists, report that it was found and skip to the next step.

Read:
- `docs/qa/capability-qa-contexts.json` ← required
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required
- `.discovery/context.json` ← optional, for `risk_scope.weights` overrides

## Process

### QR1 — Weight Configuration

Read QA risk dimension weights from `.discovery/context.json` at `risk_scope.weights.qa`. If absent, apply defaults:
```
coverage_gap:    0.35
testability:     0.30
defect_density:  0.20
change_velocity: 0.15
```
Weights must sum to 1.0; if overrides don't sum to 1.0, normalize and record the adjustment in metadata.

### QR2 — Per-Capability QA Risk Scoring

For each L1 capability (and each L2), compute four dimension scores in 0.0–1.0 (higher = more risk). A dimension is `"not-collected"` if its underlying inputs are not-collected.

#### coverage_gap (0.0–1.0)
Based on `qa_context.coverage.coverage_gap_indicator`:
- `none` → 0.1
- `low` → 0.3
- `moderate` → 0.6
- `high` → 0.9
- `"not-collected"` → dimension is `"not-collected"`

#### testability (0.0–1.0)
Based on `qa_context.testability.testability_rating` + high-severity findings:
- `good` → 0.1
- `fair` → 0.4
- `poor` → 0.8
- Add `min(0.1 × high_severity_findings, 0.2)` on top
- Cap at 1.0
- `"not-collected"` rating → dimension is `"not-collected"`

#### defect_density (0.0–1.0)
Based on `qa_context.defect_profile.defect_density`:
- `0` → 0.0
- `≤ 1 per kloc` → 0.3
- `≤ 3 per kloc` → 0.6
- `> 3 per kloc` → 0.9
- `"not-collected"` → dimension is `"not-collected"`

#### change_velocity (0.0–1.0)
Based on `qa_context.change_velocity.commits_last_90_days` and hotspot count:
- `< 10 commits` → 0.1
- `10–30 commits` → 0.3
- `30–80 commits` → 0.6
- `> 80 commits` → 0.85
- Add `min(0.05 × hotspot_files_count, 0.15)`
- Cap at 1.0
- `"not-collected"` commits → dimension is `"not-collected"`

#### QA Composite

If all four dimensions are numeric:
```
qa_composite = (coverage_gap × w.coverage_gap)
             + (testability × w.testability)
             + (defect_density × w.defect_density)
             + (change_velocity × w.change_velocity)
```

If any dimension is `"not-collected"`:
- Compute over the subset of numeric dimensions using their renormalized weights
- Record `qa_composite` as the renormalized value AND set `qa_composite_status = "partial"`
- List which dimensions were missing

If three or more dimensions are `"not-collected"`:
- Set `qa_composite` to `"unknown"` (string), `qa_composite_status = "unknown"`

### QR3 — Risk Ranking

Sort capabilities by `qa_composite` (descending). Capabilities with `qa_composite = "unknown"` appear at the bottom under a `unknown_qa_risk` group, not mixed with numeric scores.

### QR4 — QA Risk Gaps

For each capability with `qa_composite ≥ 0.6` OR with `"unknown"` status, emit a gap:
- `id`: `QAGAP-{NNN}`
- `type`: `coverage_gap | testability_gap | defect_hotspot | change_velocity_risk | qa_signal_missing`
- `severity`: CRITICAL (composite ≥ 0.8) | HIGH (≥ 0.6) | MEDIUM (≥ 0.4) | INFO (unknown due to missing signals)
- `capability`: BC-NNN
- `description`: specific gap
- `recommendation`: specific action (e.g., "Add integration tests covering the payment-retry path", "Refactor TransferOrchestrator to inject Clock")
- `effort`: LOW | MEDIUM | HIGH
- `source_dimension`: which dimension(s) drove this gap

For `qa_signal_missing` gaps, recommendation should explain what signal would need to be collected (e.g., "Connect Jira to collect defect density", "Run `go test -cover` in CI to measure real coverage").

## Output

Generate `docs/qa/qa-risk-scores.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "weights_applied": {
    "coverage_gap": 0.35,
    "testability": 0.30,
    "defect_density": 0.20,
    "change_velocity": 0.15
  },
  "weights_source": "default | override",
  "weights_normalized_from": null,
  "capability_scores": [
    {
      "capability_id": "BC-{NNN}",
      "capability_name": "{name}",
      "dimensions": {
        "coverage_gap": 0.6,
        "testability": 0.4,
        "defect_density": "not-collected",
        "change_velocity": "not-collected"
      },
      "qa_composite": 0.52,
      "qa_composite_status": "complete | partial | unknown",
      "missing_dimensions": ["defect_density", "change_velocity"],
      "drivers": ["coverage_gap", "testability"],
      "top_reasons": [
        "Moderate coverage gap — proxy tests_per_kloc = 2.1",
        "4 testability findings (1 HIGH): singleton config access in PaymentRouter"
      ],
      "l2_scores": {
        "BC-{NNN}-{NN}": {
          "qa_composite": 0.0,
          "qa_composite_status": "complete",
          "dimensions": { "coverage_gap": 0.0, "testability": 0.0, "defect_density": 0.0, "change_velocity": 0.0 }
        }
      }
    }
  ],
  "risk_ranking": ["BC-{NNN}"],
  "unknown_qa_risk": ["BC-{NNN}"],
  "summary": {
    "capabilities_assessed": 0,
    "complete_scores": 0,
    "partial_scores": 0,
    "unknown_scores": 0,
    "highest_qa_risk_capability": "BC-{NNN}",
    "average_qa_composite": 0.0,
    "capabilities_above_0_7": 0,
    "capabilities_above_0_5": 0
  }
}
```

Generate `docs/qa/qa-gaps.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "gaps": [
    {
      "id": "QAGAP-{NNN}",
      "type": "coverage_gap | testability_gap | defect_hotspot | change_velocity_risk | qa_signal_missing",
      "severity": "CRITICAL | HIGH | MEDIUM | INFO",
      "capability": "BC-{NNN}",
      "description": "{what is missing or weak}",
      "recommendation": "{specific action}",
      "effort": "LOW | MEDIUM | HIGH",
      "source_dimension": ["..."]
    }
  ],
  "prioritized_remediation": ["{QAGAP-NNN: description (capability BC-NNN, severity, effort)}"]
}
```

After generating the files:
- Update `.project/state/workflow.json`: set `step` to `generate_sdet_report`, `status` to `in_progress`
- Tell the user: "QA risk analysis complete. {complete} scored fully, {partial} partially, {unknown} unknown. Highest QA risk: {BC-NNN} ({composite}). {gap_count} QA gaps identified."

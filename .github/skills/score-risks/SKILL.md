---
name: score-risks
description: Calculate per-capability risk scores (likelihood, impact, exposure) and identify cross-capability systemic risks. Use this when workflow step is "score_risks" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/security/risk-scores.json` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated risk scores.

Read:
- `docs/security/threats/` ← all BC-{NNN}.json threat model files (required)
- `docs/security/vulnerabilities/catalog.json` ← required
- `docs/security/controls/control-map.json` ← required
- `docs/security/capability-security-contexts.json` ← required
- `docs/discovery/domain-model.md` ← for dependency graph and blast radius
- `.project/state/answers.json` (security_scope: compliance_targets, risk_tolerance)
- `.discovery/context.json` ← optional, for `risk_scope.weights.unified` overrides
- `docs/qa/qa-risk-scores.json` ← optional; when present, this skill also emits a unified security+QA risk map

## Process

### RS1 — Per-Capability Risk Scoring

For each L1 capability, compute three scores and a composite:

#### Likelihood (0.0–1.0)
Measures how probable it is that the capability will be successfully attacked.

Inputs:
- Vulnerability count by classification: each Confirmed adds 0.15, Probable adds 0.08, Potential adds 0.03 (cap sub-total at 0.6)
- Coverage gaps (from control-map.json): each CRITICAL gap adds 0.15, HIGH gap adds 0.08 (cap sub-total at 0.4)
- Attack surface: `external_exposure = public` adds 0.1, `mixed` adds 0.05

Normalize to 0.0–1.0 range.

#### Impact (0.0–1.0)
Measures the business damage if the capability is successfully compromised.

Inputs:
- Data sensitivity (from capability-security-contexts.json):
  - Financial data: 0.4
  - Authentication data: 0.4
  - PII data: 0.3
  - Health data: 0.35
  - No sensitive data: 0.1
  - Multiple classifications: use max, not sum
- Business criticality: `high` criticality adds 0.2, `medium` adds 0.1, `low` adds 0.0
- Blast radius — dependents from domain-model.md dependency graph: each capability that depends on this one adds 0.05 (cap at 0.25)

Normalize to 0.0–1.0 range.

#### Exposure (0.0–1.0)
Measures the attack surface and how reachable the capability is to attackers.

Inputs:
- External exposure: `public` = 0.7, `mixed` = 0.5, `internal` = 0.2
- Trust boundaries crossed: each external service integration adds 0.05 (cap at 0.2)
- Threat count (proxy for attack surface complexity): each CRITICAL threat adds 0.03, HIGH adds 0.02 (cap at 0.1)

Normalize to 0.0–1.0 range.

#### Composite Score
```
composite = (likelihood × 0.3) + (impact × 0.4) + (exposure × 0.3)
```

#### L2 Scores
For each L2 within an L1, score independently using the same formula but using the L2's own security context, vulnerability count, and L2-specific threats.

### RS2 — Risk Ranking

Sort capabilities by composite score (descending). This is the risk-prioritized order for remediation planning.

### RS3 — Cross-Capability Risk Analysis

Analyze systemic risks that span multiple capabilities:

#### Shared Vulnerabilities
Identify vulnerabilities (from catalog.json) that appear in multiple capabilities — same category (e.g., injection) in 3+ capabilities suggests a systemic issue:
- Shared library with a flaw: multiple capabilities use the same vulnerable dependency
- Shared infrastructure gap: same missing control across multiple capabilities (e.g., no rate limiting anywhere)
- Pattern-level weakness: same coding pattern repeated across capabilities (e.g., raw SQL in 4 services)

For each shared vulnerability pattern:
- `pattern`: what the shared weakness is
- `affected_capabilities`: list of capability IDs
- `root_cause`: likely systemic reason (shared library, shared framework config, shared code pattern)
- `severity`: highest severity among instances

#### Cascading Failure Risks
Use the dependency graph from domain-model.md to identify cascade paths:

A cascade risk exists when:
- Capability A has HIGH/CRITICAL vulnerabilities AND capabilities B, C depend on A
- If A is compromised, the attacker gains a position to attack B and C

For each cascade risk:
- `entry_point`: the capability that would be compromised first (BC-NNN)
- `cascade_to`: capabilities that would then be at risk (list of BC-NNN)
- `path`: how the attack would propagate
- `severity`: CRITICAL if financial/auth data at end of chain, HIGH otherwise

#### Weak Trust Boundaries
From capability-security-contexts.json → trust_boundaries, identify boundaries where:
- `controls_present` is empty or has only weak controls
- The data crossing is Financial, Authentication, or PII
- The boundary crosses to an external (third-party) service

#### Privilege Escalation Paths
Identify sequences of capability operations that could chain into unauthorized access:
- Low-privilege capability A can write data that high-privilege capability B reads without re-validation
- Capability A's output (e.g., a token or flag) is consumed by capability B with elevated trust
- A sequence of legitimate operations that bypasses privilege checks

### RS4 — Gap Analysis

Synthesize actionable gaps:

**Missing controls**: From control-map.json → coverage_gaps where no control exists for CRITICAL/HIGH threats
**Weak implementations**: From control-map.json → controls with effectiveness = LOW
**High-risk areas**: Capabilities with composite score ≥ 0.7 AND low control coverage (fewer than 3 controls)
**Compliance gaps**: If `security_scope.compliance_targets` is set:
- GDPR: PII-handling capabilities without data minimization, audit logging, or consent management signals
- PCI-DSS: Financial data capabilities without encryption, access control, and audit logging
- HIPAA: Health data capabilities without access controls and audit logs

### RS5 — Unified Security + QA Composite (conditional)

If `docs/qa/qa-risk-scores.json` exists, compute a unified composite per capability.

Read QA composite weights from `.discovery/context.json` at `risk_scope.weights.unified`. Defaults:
```
security: 0.55
qa:       0.45
```
If the overrides do not sum to 1.0, normalize and record the adjustment in `weights_normalized_from`.

For each L1 capability (and each L2):

1. Look up the security `composite` score from this skill's own per-capability output.
2. Look up the QA `qa_composite` and `qa_composite_status` from `qa-risk-scores.json`.
3. Compute `unified_composite`:
   - If both are numeric: `unified_composite = (security × w.security) + (qa × w.qa)`, `unified_status = "complete"`
   - If QA status is `"partial"` (QA composite is numeric but some dimensions were not-collected): compute the weighted sum as above, set `unified_status = "partial"`
   - If QA composite is the string `"unknown"`: set `unified_composite` to security × w.security (renormalized over the present component — i.e., `unified_composite = security`), `unified_status = "partial"`, and record `missing_components = ["qa"]`
   - If security composite is missing (shouldn't happen during /assess, but possible if score is `null`): analogous handling with `missing_components = ["security"]`

4. Record `drivers_unified`: the top 2 contributors across security (likelihood/impact/exposure) and QA (coverage_gap/testability/defect_density/change_velocity) that pushed this capability's unified score up.

If `docs/qa/qa-risk-scores.json` does NOT exist, skip RS5 entirely. The `unified-risk-map.json` is not written. The stakeholder, architect, and dev reports will still render a security-only view.

## Output

Generate `docs/security/risk-scores.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "risk_tolerance": "{from security_scope}",
  "capability_scores": [
    {
      "capability_id": "BC-{NNN}",
      "capability_name": "{name}",
      "scores": {
        "likelihood": 0.0,
        "impact": 0.0,
        "exposure": 0.0,
        "composite": 0.0
      },
      "scoring_factors": {
        "likelihood_inputs": "{brief description of what drove the likelihood score}",
        "impact_inputs": "{brief description of what drove the impact score}",
        "exposure_inputs": "{brief description of what drove the exposure score}"
      },
      "top_threats": ["{threat description}"],
      "top_vulnerabilities": ["{VULN-NNN: title}"],
      "control_gaps": ["{GAP-NNN: description}"],
      "l2_scores": {
        "BC-{NNN}-{NN}": {
          "composite": 0.0,
          "likelihood": 0.0,
          "impact": 0.0,
          "exposure": 0.0
        }
      }
    }
  ],
  "risk_ranking": ["{BC-NNN}", "{BC-NNN}"],
  "summary": {
    "highest_risk_capability": "BC-{NNN}",
    "average_composite_score": 0.0,
    "capabilities_above_0_7": 0,
    "capabilities_above_0_5": 0
  }
}
```

Generate `docs/security/cross-capability-risks.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "shared_vulnerabilities": [
    {
      "pattern": "{weakness pattern}",
      "affected_capabilities": ["{BC-NNN}"],
      "root_cause": "{systemic reason}",
      "severity": "CRITICAL | HIGH | MEDIUM | LOW",
      "recommendation": "{systemic fix}"
    }
  ],
  "cascading_risks": [
    {
      "entry_point": "BC-{NNN}",
      "cascade_to": ["{BC-NNN}"],
      "path": "{how attack propagates}",
      "severity": "CRITICAL | HIGH"
    }
  ],
  "weak_boundaries": [
    {
      "boundary": "{description}",
      "capabilities": ["{BC-NNN}"],
      "weakness": "{what makes it weak}",
      "severity": "HIGH | MEDIUM"
    }
  ],
  "escalation_paths": [
    {
      "path": ["{BC-NNN-NN}", "{BC-NNN-NN}"],
      "description": "{how privilege escalation works}",
      "severity": "CRITICAL | HIGH"
    }
  ],
  "compliance_gaps": [
    {
      "standard": "GDPR | PCI-DSS | HIPAA",
      "requirement": "{specific requirement}",
      "affected_capabilities": ["{BC-NNN}"],
      "gap": "{what is missing}"
    }
  ]
}
```

Generate `docs/security/gaps.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "gaps": [
    {
      "id": "SECGAP-{NNN}",
      "type": "missing_control | weak_implementation | high_risk_area | compliance",
      "severity": "CRITICAL | HIGH | MEDIUM | LOW",
      "capability": "BC-{NNN}",
      "description": "{what is missing or weak}",
      "evidence": "{reference to threat, vulnerability, or control that surfaced this gap}",
      "recommendation": "{specific action to close the gap}",
      "effort": "LOW | MEDIUM | HIGH"
    }
  ],
  "prioritized_remediation": [
    "{SECGAP-NNN: description (capability BC-NNN, severity, effort)}"
  ]
}
```

If RS5 ran, also generate `docs/risk/unified-risk-map.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "weights_applied": {
    "security": 0.55,
    "qa": 0.45
  },
  "weights_source": "default | override",
  "weights_normalized_from": null,
  "capability_unified_scores": [
    {
      "capability_id": "BC-{NNN}",
      "capability_name": "{name}",
      "security_composite": 0.0,
      "qa_composite": 0.0,
      "qa_composite_status": "complete | partial | unknown",
      "unified_composite": 0.0,
      "unified_status": "complete | partial",
      "missing_components": [],
      "drivers_unified": ["security.exposure", "qa.coverage_gap"],
      "l2_unified": {
        "BC-{NNN}-{NN}": {
          "unified_composite": 0.0,
          "unified_status": "complete | partial"
        }
      }
    }
  ],
  "unified_ranking": ["BC-{NNN}"],
  "summary": {
    "capabilities_scored": 0,
    "complete_unified_scores": 0,
    "partial_unified_scores": 0,
    "highest_unified_risk_capability": "BC-{NNN}",
    "average_unified_composite": 0.0,
    "capabilities_above_0_7": 0,
    "capabilities_above_0_5": 0
  }
}
```

Create the `docs/risk/` directory if it does not exist.

After generating the files:
- Update `.project/state/workflow.json`: set `step` to `generate_security_contexts`, `status` to `in_progress`
- Tell the user: "Risk scoring complete. Highest risk: BC-{NNN} ({name}, composite {score}). {high_risk_count} capabilities above 0.7 composite. {gaps_count} actionable gaps identified.{unified_msg} Next: generate AI-ready security context packages."
  - Where `{unified_msg}` is " Unified security+QA risk map written to docs/risk/unified-risk-map.json ({complete} complete, {partial} partial)." when RS5 ran, or empty string otherwise.

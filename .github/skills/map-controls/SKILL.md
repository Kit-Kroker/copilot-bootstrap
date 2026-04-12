---
name: map-controls
description: Map existing security controls to identified threats and vulnerabilities. Identifies coverage gaps. Use this when workflow step is "map_controls" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/security/controls/control-map.json` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated control mapping.

Read:
- `docs/security/threats/` ← all BC-{NNN}.json threat model files (required)
- `docs/security/vulnerabilities/catalog.json` ← required
- `docs/security/security-signals.json` ← required
- `docs/security/capability-security-contexts.json` ← required

## Process

### CM1 — Extract Existing Controls from Security Signals

From `security-signals.json → static_signals`, identify signals that represent CONTROLS (positive security measures in place, not vulnerabilities):

**Authentication controls:**
- JWT validation, OAuth2 flows, session management → authentication control
- Confidence: use the signal's confidence level

**Authorization controls:**
- RBAC implementations, permission guards, middleware authorization → authorization control
- Record: which capabilities they cover (from signal file location)

**Input validation controls:**
- Parameterized queries, input schemas, sanitization functions → validation control
- Record: which input paths they protect

**Encryption controls:**
- TLS enforcement, at-rest encryption, field-level encryption → encryption control
- Record: what data and paths they cover

**Monitoring controls:**
- Audit logging patterns, security event logging → monitoring control
- Record: what operations are logged

**Rate limiting controls:**
- Rate limiting middleware, throttling decorators → rate limiting control
- Record: which endpoints are protected

For each identified control:
- Assign a unique ID: `CTRL-{NNN}`
- Record `category`, `implementation` (what technology/pattern), `location` (file and line)
- Assess `effectiveness`: HIGH (correctly implemented, standard approach), MEDIUM (implemented but with gaps), LOW (present but likely bypassable)

### CM2 — Map Controls to Threats

For each control, determine which threats from `docs/security/threats/BC-{NNN}.json` it mitigates:

- An authentication control (JWT validation) covers: all spoofing threats that note "JWT validation" as an existing control
- An authorization control (RBAC) covers: elevation of privilege threats related to unauthorized access
- Input validation covers: tampering threats related to injection
- Encryption covers: information disclosure threats related to data at rest/transit

Match by:
1. Threat references the control in `existing_controls` → direct match
2. Control category logically addresses the threat category (auth → spoofing, validation → tampering, etc.) → inferred match
3. Control file location overlaps with the capability owning the threat → scope match

Record: `covers_threats: ["BC-{NNN}/stride_category/NNN"]`

### CM3 — Map Controls to Vulnerabilities

For each control, determine which vulnerabilities from `catalog.json` it partially or fully mitigates:

Match by:
1. Vulnerability's `existing_controls` lists this control → direct match
2. Control category addresses the vulnerability category → inferred match

Record: `covers_vulnerabilities: ["VULN-{NNN}"]`

### CM4 — Assess Control Consistency

For each control, check whether it's consistently applied across the capability's L2 operations:

Read `capability-security-contexts.json` to see which L2s exist for the capability the control is in. Then check whether the control applies to:
- ALL L2s within the capability (consistent)
- SOME L2s (partial — list which are covered, which are not)
- ONLY some specific L2s (missing in others — flag the gaps)

Record: `consistency`: `"All L2s"` | `"Partial — missing in {BC-NNN-NN}"` | `"Single L2 only"`

### CM5 — Identify Coverage Gaps

A coverage gap exists where a threat or CRITICAL/HIGH vulnerability has NO corresponding control:

1. For each CRITICAL or HIGH threat from threat model files: check if any control covers it. If none → gap.
2. For each CRITICAL or HIGH vulnerability from catalog.json: check if any control covers it. If none → gap.
3. For each L2 in a HIGH criticality capability: check if authentication and authorization controls apply. If absent → gap.

For each gap:
- `threat_or_vuln`: reference (BC-NNN/stride/NNN or VULN-NNN)
- `description`: what control is missing and why it matters
- `severity`: inherit from the threat/vulnerability severity
- `recommendation`: specific action to close the gap (e.g., "Add rate limiting to POST /api/v1/auth/login using express-rate-limit or equivalent")

## Output

Generate `docs/security/controls/control-map.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "controls": [
    {
      "id": "CTRL-{NNN}",
      "category": "authentication | authorization | input_validation | encryption | monitoring | rate_limiting",
      "implementation": "{description — e.g., 'JWT validation middleware', 'bcrypt password hashing'}",
      "location": { "file": "{path}", "line": 0 },
      "source_signal": "{SS1-category-NNN}",
      "effectiveness": "HIGH | MEDIUM | LOW",
      "effectiveness_notes": "{why this rating — e.g., 'JWT validation present but no expiry check'}",
      "consistency": "All L2s | Partial — missing in BC-{NNN}-{NN} | Single L2 only",
      "covers_threats": ["{BC-NNN/stride_category/NNN}"],
      "covers_vulnerabilities": ["{VULN-NNN}"]
    }
  ],
  "coverage_gaps": [
    {
      "id": "GAP-{NNN}",
      "threat_or_vuln": "{BC-NNN/stride_category/NNN | VULN-NNN}",
      "capability": "BC-{NNN}",
      "description": "{what control is missing}",
      "severity": "CRITICAL | HIGH | MEDIUM | LOW",
      "recommendation": "{specific recommended action}"
    }
  ],
  "summary": {
    "controls_identified": 0,
    "authentication_controls": 0,
    "authorization_controls": 0,
    "validation_controls": 0,
    "encryption_controls": 0,
    "monitoring_controls": 0,
    "rate_limiting_controls": 0,
    "coverage_gaps_count": 0,
    "critical_gaps": 0,
    "high_gaps": 0
  }
}
```

Generate `docs/security/controls/control-summary.md`:

```markdown
# Control Coverage Summary

## Overview

- **Controls identified**: {count}
- **Coverage gaps**: {count} ({critical} CRITICAL, {high} HIGH, {medium} MEDIUM, {low} LOW)

## Controls by Category

| Category | Count | Avg Effectiveness | Notes |
|----------|-------|-------------------|-------|
| Authentication | {n} | HIGH/MEDIUM/LOW | {summary} |
| Authorization | {n} | HIGH/MEDIUM/LOW | {summary} |
| Input Validation | {n} | HIGH/MEDIUM/LOW | {summary} |
| Encryption | {n} | HIGH/MEDIUM/LOW | {summary} |
| Monitoring | {n} | HIGH/MEDIUM/LOW | {summary} |
| Rate Limiting | {n} | HIGH/MEDIUM/LOW | {summary} |

## Coverage Matrix

| Capability | Auth | AuthZ | Validation | Encryption | Monitoring | Rate Limit | Gaps |
|-----------|------|-------|------------|------------|------------|------------|------|
| BC-001: {name} | ✓ | ✓ | ✗ | ✓ | ✗ | ✗ | 3 |

*(✓ = control present and effective, ~ = present but gaps, ✗ = absent)*

## Critical Coverage Gaps

| Gap | Capability | Description | Recommendation |
|-----|-----------|-------------|----------------|
| GAP-001 | BC-{NNN} | {description} | {recommendation} |

*(List all CRITICAL and HIGH gaps)*

## Well-Protected Areas

{2-3 sentences describing where controls are strongest and what they protect well.}

## Highest-Risk Gaps

{2-3 sentences describing the most dangerous gaps — where threats have no mitigations.}
```

After generating the files:
- Update `.project/state/workflow.json`: set `step` to `score_risks`, `status` to `in_progress`
- Tell the user: "{controls} controls identified across {categories} categories. {gaps} coverage gaps found ({critical} CRITICAL, {high} HIGH). Next: calculate per-capability risk scores."

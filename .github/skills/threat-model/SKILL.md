---
name: threat-model
description: Generate STRIDE threat models per capability. Evaluates spoofing, tampering, repudiation, information disclosure, denial of service, and elevation of privilege against each capability's security context. Use this when workflow step is "threat_model" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/security/threats/threat-summary.md` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated threat models.

Read:
- `docs/security/capability-security-contexts.json` ← required
- `docs/security/security-signals.json` ← required
- `docs/discovery/domain-model.md` ← required
- `.project/state/answers.json` (security_scope: standard, compliance_targets, risk_tolerance)

## Process

### TM1 — Prioritize Capabilities

Order capabilities for threat modeling by criticality (from `capability-security-contexts.json`):
1. HIGH criticality capabilities first
2. Within each level, public-facing capabilities before internal
3. Capabilities with Financial or Authentication data before PII-only

### TM2 — STRIDE Analysis Per Capability

For each capability, apply all six STRIDE threat categories. Use the capability's security context to focus the analysis.

#### Spoofing
Can an attacker impersonate a legitimate user or system?

Evaluate against the capability's `auth_mechanisms`. Consider:
- Missing authentication on endpoints that should require it
- Weak token validation (no expiry check, no signature verification, no issuer check)
- Session fixation: session ID not rotated after login
- Credential stuffing exposure: no brute force protection on login endpoints
- Service-to-service spoofing: no mutual TLS or API key validation on internal calls
- Trust boundary crossing without re-authentication

Existing mitigations: check `static_signals` for authentication patterns in the capability's code.
Missing mitigations: identify what's absent that the threat requires.

#### Tampering
Can data be modified in transit or at rest without detection?

Evaluate against `data_sensitivity`. Consider:
- Missing input validation on data that flows into the capability (SQL injection, mass assignment)
- Unsigned payloads: API requests without HMAC or digital signature
- Missing integrity checks on stored sensitive data
- Mutable shared state: data owned by this capability modified by other capabilities without going through its API
- CSRF: state-changing operations without CSRF protection
- Parameter pollution: duplicate parameters accepted with unpredictable behavior

#### Repudiation
Can a user or system deny performing an action?

Evaluate against audit logging in the capability. Consider:
- Missing audit trail for sensitive operations (who did what, when)
- Unsigned transactions: no non-repudiation for financial or identity operations
- Log tampering: logs not write-protected or centrally collected
- Missing correlation IDs: inability to trace an action across capability boundaries
- No event sourcing or audit table for critical state changes

#### Information Disclosure
Can sensitive data leak to unauthorized parties?

Evaluate against `data_sensitivity` and `external_exposure`. Consider:
- Verbose error messages exposing internal structure (stack traces, SQL errors, internal paths)
- Logging PII or credentials (check `configuration_signals` for logging issues)
- Insecure API responses: returning more data than the caller needs (over-fetching)
- Missing field-level access control: all authenticated users can see all fields
- Data exposure through indirect reference: sequential IDs allowing enumeration
- Caching sensitive data without appropriate cache-control headers
- Insecure direct object reference (IDOR): accessing other users' data by changing an ID

#### Denial of Service
Can the capability be overwhelmed or made unavailable?

Evaluate against `external_exposure`. Consider:
- Missing rate limiting on public endpoints (check `configuration_signals` for rate limiting)
- Unbounded queries: no pagination, no result limits on database queries
- Resource-intensive operations without throttling (file uploads, report generation, bulk operations)
- Algorithmic complexity attacks: regular expression DOS, nested loop operations on user input
- Missing timeout on external service calls (a slow third party blocks the capability)
- No circuit breaker on external dependencies

#### Elevation of Privilege
Can an attacker gain access beyond their authorization level?

Evaluate against authorization patterns in `static_signals`. Consider:
- Missing authorization checks (endpoints that authenticate but don't authorize)
- Insecure direct object reference where authorization depends only on knowing the ID
- Privilege escalation through capability chaining: sequence of operations across L2s that bypasses privilege boundaries
- Role confusion: attacker sets their own role via user-controlled input
- JWT claims manipulation if claims are trusted without server-side verification
- Admin functions accessible to non-admin users

### TM3 — Threat Severity and Likelihood

For each identified threat, assign:

**Severity**: CRITICAL | HIGH | MEDIUM | LOW
- CRITICAL: Exploitable without authentication, directly impacts Financial or Authentication data, affects all users
- HIGH: Exploitable with basic authentication, significant data exposure, requires common attack tooling
- MEDIUM: Requires specific conditions or moderate skill, limited data exposure, or impacts subset of users
- LOW: Requires significant skill or insider access, minimal data exposure, or theoretical only

**Likelihood**: HIGH | MEDIUM | LOW
- HIGH: Known attack tooling exists, attack surface is publicly reachable, no existing mitigations
- MEDIUM: Attack requires some setup or skill, partial mitigations present, or requires specific conditions
- LOW: Requires significant attacker skill/access, multiple mitigations present, or theoretical attack path

### TM4 — Generate Threat Files

For each capability, generate `docs/security/threats/BC-{NNN}.json`:

```json
{
  "capability_id": "BC-{NNN}",
  "capability_name": "{name}",
  "criticality": "high | medium | low",
  "modeled_at": "{ISO 8601 timestamp}",
  "threat_model": {
    "spoofing": [
      {
        "id": "BC-{NNN}/spoofing/{NNN}",
        "threat": "{threat description}",
        "severity": "CRITICAL | HIGH | MEDIUM | LOW",
        "likelihood": "HIGH | MEDIUM | LOW",
        "attack_vector": "{how the attack would be executed}",
        "existing_controls": ["{control from security-signals.json}"],
        "missing_controls": ["{what control would mitigate this}"],
        "affected_l2": ["{BC-NNN-NN}"]
      }
    ],
    "tampering": [],
    "repudiation": [],
    "information_disclosure": [],
    "denial_of_service": [],
    "elevation_of_privilege": []
  },
  "threat_counts": {
    "total": 0,
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  }
}
```

Write one file per capability. Skip capabilities with `criticality: low` if they have zero HIGH or CRITICAL threats — write an empty threat model with a note "No significant threats identified for low-criticality capability."

### TM5 — Generate Threat Summary

Generate `docs/security/threats/threat-summary.md`:

```markdown
# Threat Model Summary

## Overview

- **Capabilities modeled**: {count}
- **Total threats identified**: {count}
- **CRITICAL**: {count}
- **HIGH**: {count}
- **MEDIUM**: {count}
- **LOW**: {count}

## Top Threats by Severity

| # | Threat | Capability | Category | Severity | Likelihood | Existing Controls | Missing Controls |
|---|--------|-----------|----------|----------|------------|------------------|-----------------|
| 1 | {description} | BC-{NNN}: {name} | {STRIDE category} | CRITICAL | HIGH | {controls} | {gaps} |

*(List all CRITICAL threats, then HIGH threats, up to 20 entries total)*

## Threats per Capability

| Capability | CRITICAL | HIGH | MEDIUM | LOW | Total |
|-----------|----------|------|--------|-----|-------|
| BC-001: {name} | {n} | {n} | {n} | {n} | {n} |

*(Sort by total threats descending)*

## STRIDE Distribution

| STRIDE Category | CRITICAL | HIGH | MEDIUM | LOW | Total |
|----------------|----------|------|--------|-----|-------|
| Spoofing | {n} | {n} | {n} | {n} | {n} |
| Tampering | {n} | {n} | {n} | {n} | {n} |
| Repudiation | {n} | {n} | {n} | {n} | {n} |
| Information Disclosure | {n} | {n} | {n} | {n} | {n} |
| Denial of Service | {n} | {n} | {n} | {n} | {n} |
| Elevation of Privilege | {n} | {n} | {n} | {n} | {n} |

## Capability Detail

{For each capability with HIGH or CRITICAL threats, write 3-5 sentences describing its threat landscape:
- What is the highest-risk threat and why?
- What existing controls are in place?
- What is the most critical missing control?}

### BC-{NNN}: {Capability Name}

{threat landscape narrative}
```

After generating the files:
- Update `.project/state/workflow.json`: set `step` to `vulnerability_detection`, `status` to `in_progress`
- Tell the user: "Threat models generated for {N} capabilities. {total} threats identified ({critical} CRITICAL, {high} HIGH, {medium} MEDIUM, {low} LOW). Next: vulnerability detection and classification."

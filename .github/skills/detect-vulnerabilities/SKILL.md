---
name: detect-vulnerabilities
description: Combine static patterns, dependency risks, and configuration issues into a classified vulnerability catalog. Maps each vulnerability to capabilities. Use this when workflow step is "vulnerability_detection" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/security/vulnerabilities/catalog.json` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated vulnerability data from external scanners.

Read:
- `docs/security/security-signals.json` ← required
- `docs/security/capability-security-contexts.json` ← required
- `docs/security/threats/` ← required (all BC-{NNN}.json threat model files)
- `docs/discovery/domain-model.md` ← for capability-to-code mapping
- The codebase (for deeper analysis of flagged patterns from security-signals.json)

## Process

### VD1 — Derive Vulnerabilities from Static Signals (SS1)

From `security-signals.json → static_signals`, identify patterns that represent exploitable vulnerabilities:

**Direct vulnerability mappings:**
- `secrets` category with HIGH confidence → Confirmed vulnerability: hardcoded credentials
- `password` category with pattern containing `md5` or `sha1` → Confirmed vulnerability: weak password hashing
- `input_validation` with pattern indicating raw SQL concatenation → Confirmed vulnerability: SQL injection risk
- `authentication` signals with LOW confidence (inferred, not found) → Probable vulnerability: missing authentication

For each static signal, determine:
- Is this a vulnerability (exploitable weakness) or just a security pattern that's present (good)?
- A JWT validation signal is a GOOD sign (mitigating control), not a vulnerability
- A missing JWT validation where authentication is expected IS a vulnerability
- Raw SQL without parameterization is a vulnerability; parameterized queries are not

Look deeper in the codebase for flagged patterns:
- If a `secrets` signal was found, read the file to confirm it's not a test file or placeholder
- If raw SQL was flagged, read the context to confirm it's not inside a safe abstraction layer

### VD2 — Derive Vulnerabilities from Dependency Signals (SS2)

From `security-signals.json → dependency_signals`:
- HIGH risk dependencies → Probable vulnerability (specific CVEs require external tools, but high-risk version is confirmable)
- MEDIUM risk dependencies → Potential vulnerability
- Severely outdated packages (multiple major versions behind) → Potential vulnerability

Note: Mark all dependency vulnerabilities as Probable unless a specific CVE pattern is identifiable in the code.

### VD3 — Derive Vulnerabilities from Configuration Signals (SS3)

From `security-signals.json → configuration_signals`:
- `cors` with wildcard origin + credentials enabled → Confirmed vulnerability: CORS misconfiguration
- `rate_limiting` absent on authentication endpoints → Probable vulnerability: brute force exposure
- `error_handling` exposing stack traces → Confirmed vulnerability: information disclosure
- `logging` with PII → Confirmed vulnerability: sensitive data in logs

### VD4 — Derive Vulnerabilities from Threat Models

From the threat files in `docs/security/threats/`:
- Threats with `existing_controls: []` (no controls) AND severity HIGH or CRITICAL → Probable vulnerability (the unmitigated threat path is likely exploitable)
- Threats with severity CRITICAL and low likelihood → Potential vulnerability
- Multiple threats in the same STRIDE category for the same L2 → Look for a root cause vulnerability

### VD5 — Classify Each Vulnerability

For each identified vulnerability, assign a classification:

- **Confirmed**: Directly observable in code with clear exploit path. Evidence is a specific code pattern at a specific location.
  - Example: Raw string concatenation in a SQL query at payments/src/search.js:87
  - Example: Hardcoded API key in config/secrets.js:12

- **Probable**: Pattern strongly suggests vulnerability but needs runtime verification.
  - Example: CORS wildcard configured — confirmed in code, but whether it causes harm depends on what cookies are set
  - Example: No rate limiting middleware found — confirmed absent, but WAF may handle it at infrastructure level

- **Potential**: Theoretical based on architecture, configuration, or absence of expected controls.
  - Example: No audit logging found for financial operations — could be architectural gap or could be handled by a layer not in the codebase scan
  - Example: Dependency with known vulnerabilities — requires specific code paths to be exploitable

### VD6 — Map Vulnerabilities to Capabilities

For each vulnerability:
1. Identify the affected capability (L1) from the file path using domain-model.md code locations
2. Identify the affected L2 if the file path is within a specific L2's code footprint
3. If file path maps to shared infrastructure, flag as "cross-cutting" and list all capabilities that use it
4. Map to the related STRIDE category from the threat model (the vulnerability enables a specific threat)

### VD7 — Flag False Positive Candidates

Identify findings that warrant careful review before accepting as real vulnerabilities:

- **Unreachable code**: Flagged pattern is in dead code (commented out, feature-flagged off, test-only path)
- **Mitigated elsewhere**: Pattern looks dangerous but there's evidence of mitigation at another layer (e.g., WAF rules, input sanitized upstream)
- **Intentional**: Configuration that appears insecure is intentional and documented (e.g., permissive CORS for a public widget)
- **Test code**: Pattern is in test fixtures or mocks, not production code

Mark these separately — do not remove them from the catalog, but set `false_positive: true` with a documented reason.

## Output

Generate `docs/security/vulnerabilities/catalog.json`:

```json
{
  "scan_metadata": {
    "timestamp": "{ISO 8601 timestamp}",
    "total": 0,
    "confirmed": 0,
    "probable": 0,
    "potential": 0,
    "false_positive_candidates": 0
  },
  "vulnerabilities": [
    {
      "id": "VULN-{NNN}",
      "title": "{short descriptive title}",
      "classification": "confirmed | probable | potential",
      "severity": "CRITICAL | HIGH | MEDIUM | LOW",
      "category": "injection | authentication | authorization | cryptography | configuration | dependency | information_disclosure | denial_of_service",
      "description": "{full description of the vulnerability and its impact}",
      "evidence": {
        "file": "{file path}",
        "line": 0,
        "pattern": "{pattern description}",
        "code_snippet": "{relevant code excerpt — sanitize to remove actual credentials if found}",
        "signal_source": "{SS1-category-NNN | SS2 | SS3-category-NNN | threat BC-NNN/category/NNN}"
      },
      "affected_capability": "BC-{NNN}",
      "affected_l2": "BC-{NNN}-{NN} | null",
      "related_threat": "{BC-NNN/stride_category/NNN | null}",
      "existing_controls": ["{controls that partially mitigate this}"],
      "false_positive": false,
      "false_positive_reason": null
    }
  ],
  "false_positive_candidates": [
    {
      "id": "FP-{NNN}",
      "original_finding": "{description of what was flagged}",
      "reason": "{why this is likely a false positive}",
      "evidence": "{what evidence supports the false positive assessment}"
    }
  ]
}
```

Generate `docs/security/vulnerabilities/vulnerability-summary.md`:

```markdown
# Vulnerability Catalog Summary

## Overview

- **Total findings**: {count}
- **Confirmed**: {count}
- **Probable**: {count}
- **Potential**: {count}
- **False positive candidates**: {count}

## Findings by Severity

| Severity | Confirmed | Probable | Potential | Total |
|----------|-----------|----------|-----------|-------|
| CRITICAL | {n} | {n} | {n} | {n} |
| HIGH     | {n} | {n} | {n} | {n} |
| MEDIUM   | {n} | {n} | {n} | {n} |
| LOW      | {n} | {n} | {n} | {n} |

## Findings by Category

| Category | CRITICAL | HIGH | MEDIUM | LOW | Total |
|----------|----------|------|--------|-----|-------|
| Injection | {n} | {n} | {n} | {n} | {n} |
| Authentication | {n} | {n} | {n} | {n} | {n} |
| Authorization | {n} | {n} | {n} | {n} | {n} |
| ...

## Findings by Capability

| Capability | CRITICAL | HIGH | MEDIUM | LOW | Total |
|-----------|----------|------|--------|-----|-------|
| BC-001: {name} | {n} | {n} | {n} | {n} | {n} |

*(Sort by total findings descending)*

## Top Findings

| ID | Title | Capability | Severity | Classification | Evidence |
|----|-------|-----------|----------|----------------|----------|
| VULN-001 | {title} | BC-{NNN} | CRITICAL | confirmed | {file:line} |

*(List all CRITICAL and HIGH findings)*

## False Positive Candidates

| ID | Finding | Reason |
|----|---------|--------|
| FP-001 | {finding} | {reason} |

## Detection Limitations

{List any areas where detection coverage is limited, e.g.:
- "Full CVE lookup not performed — dependency vulnerabilities may be under-reported"
- "Dynamic analysis not performed — runtime-only vulnerabilities not captured"
- "Infrastructure layer not scanned — WAF/firewall configurations not evaluated"}
```

After generating the files:
- Update `.project/state/workflow.json`: set `step` to `map_controls`, `status` to `in_progress`
- Tell the user: "{total} vulnerabilities cataloged ({confirmed} confirmed, {probable} probable, {potential} potential). {critical} CRITICAL, {high} HIGH severity findings. {fp} false positive candidates flagged. Next: map existing controls to threats and vulnerabilities."

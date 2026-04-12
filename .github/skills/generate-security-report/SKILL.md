---
name: generate-security-report
description: Generate final security reports — executive summary, risk map, threat catalog, and secured domain model. Use this when workflow step is "security_report" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/security/security-report.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/security/risk-scores.json` ← required
- `docs/security/vulnerabilities/catalog.json` ← required
- `docs/security/threats/threat-summary.md` ← required
- `docs/security/controls/control-summary.md` ← required
- `docs/security/cross-capability-risks.json` ← required
- `docs/security/gaps.json` ← required
- `docs/security/capability-security-contexts.json` ← required
- `docs/discovery/domain-model.md` ← required
- `.project/state/answers.json` (security_scope)
- All individual threat files from `docs/security/threats/BC-*.json`

## Process

### GR1 — Generate Executive Security Report

Write for a technical lead or architect reading the report before a planning meeting. Not a raw data dump — a synthesized, prioritized narrative.

The report must answer:
1. What are the top risks and why?
2. What is the compliance posture?
3. What should be fixed first, and in what order?
4. Are there systemic risks beyond individual findings?

Write to: `docs/security/security-report.md`

```markdown
# Security Assessment Report

**System**: {project name from answers.json}
**Assessment Date**: {today}
**Security Standard**: {standard from security_scope}
**Compliance Targets**: {compliance_targets or "None specified"}
**Risk Tolerance**: {risk_tolerance}

---

## Executive Summary

{3-5 sentences: overall security posture, most critical finding, top systemic risk, and one key recommendation}

---

## Risk Overview

- **Capabilities assessed**: {count}
- **Total threats identified**: {count} ({critical} CRITICAL, {high} HIGH, {medium} MEDIUM, {low} LOW)
- **Total vulnerabilities**: {count} ({confirmed} confirmed, {probable} probable, {potential} potential)
- **Control gaps**: {count} ({critical_gaps} CRITICAL, {high_gaps} HIGH)
- **Highest risk capability**: BC-{NNN} ({name}) — composite score {score}

---

## Top Risks

*Ranked by composite risk score. Focus remediation here first.*

| # | Capability | Risk Score | Top Threat | Top Vulnerability | Missing Control |
|---|-----------|------------|------------|-------------------|-----------------|
| 1 | BC-{NNN}: {name} | {score} | {threat} | {vuln} | {gap} |

*(List top 5-10 capabilities by composite score)*

---

## Critical Findings

{List all CONFIRMED CRITICAL and CONFIRMED HIGH vulnerabilities with:
- Vulnerability ID, title, capability
- Specific file and line
- Why it is CRITICAL/HIGH in this system's context (not generic)}

### {VULN-NNN}: {Title}

**Capability**: BC-{NNN} — {name}
**Severity**: CRITICAL | HIGH
**Classification**: confirmed
**Evidence**: `{file}:{line}`

{2-3 sentences: what the vulnerability is, how it would be exploited in this system, and what business impact it would have}

**Recommended fix**: {specific fix — not "improve validation" but "replace string concatenation at {file}:{line} with parameterized query using {ORM/framework method}"}

---

## Mitigation Priorities

Order of recommended remediation. Optimizes for: fixing exploitable issues first, then closing systemic gaps, then addressing probable findings.

### Immediate (CRITICAL findings — address before next release)

{List CRITICAL vulnerabilities and gaps, each with:
- What to fix (specific)
- Where (file/component)
- Effort estimate: LOW (< 1 day) | MEDIUM (1-3 days) | HIGH (3+ days)}

### Short-term (HIGH findings — address within current sprint/iteration)

{List HIGH vulnerabilities and gaps}

### Medium-term (MEDIUM findings and systemic gaps)

{List MEDIUM vulnerabilities and systemic improvements}

---

## Compliance Posture

{If compliance_targets in security_scope:}

### {GDPR | PCI-DSS | HIPAA}

| Requirement | Status | Evidence | Gap |
|------------|--------|----------|-----|
| {requirement} | Met | {evidence} | — |
| {requirement} | Partial | {partial evidence} | {what's missing} |
| {requirement} | Not Met | — | {what needs to be implemented} |

**Overall {standard} posture**: {MET | PARTIALLY MET | NOT MET}

{If no compliance targets: "No specific compliance targets were configured for this assessment."}

---

## Systemic Risks

*Risks that span multiple capabilities. These require architectural changes, not just code fixes.*

### Shared Vulnerabilities

{From cross-capability-risks.json → shared_vulnerabilities:
For each: describe the pattern, list affected capabilities, explain the root cause, and recommend the systemic fix}

### Cascading Failure Risks

{From cross-capability-risks.json → cascading_risks:
For each: describe the entry point, the cascade path, and the potential impact if the entry point is compromised}

### Weak Trust Boundaries

{From cross-capability-risks.json → weak_boundaries:
For each: describe the boundary, what makes it weak, and what would strengthen it}

---

## Capability Risk Map

| Capability | Composite | Likelihood | Impact | Exposure | Critical | High | Medium | Low |
|-----------|-----------|------------|--------|----------|----------|------|--------|-----|
| BC-001: {name} | {score} | {n} | {n} | {n} | {n} | {n} | {n} | {n} |

*(Sorted by composite score, descending)*

---

## Assessment Coverage

- **Threat modeling**: STRIDE applied to all {count} capabilities
- **Vulnerability detection**: Static analysis (SS1-SS4), dependency analysis, configuration analysis
- **Control mapping**: {count} controls identified, {count} gaps documented
- **Limitations**: CVE lookup requires external tools; dynamic/runtime analysis not performed; infrastructure layer (WAF, firewall) not evaluated
```

### GR2 — Generate Machine-Readable Risk Map

Write to: `docs/security/security-risk-map.json`

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "system": "{project name}",
  "capabilities": {
    "BC-{NNN}": {
      "name": "{capability name}",
      "risk_score": {
        "likelihood": 0.0,
        "impact": 0.0,
        "exposure": 0.0,
        "composite": 0.0
      },
      "top_threats": ["{threat description}"],
      "top_vulnerabilities": ["{VULN-NNN: title}"],
      "control_gaps": ["{GAP-NNN: description}"],
      "l2_risks": {
        "BC-{NNN}-{NN}": { "composite": 0.0 }
      }
    }
  },
  "risk_ranking": ["{BC-NNN}"],
  "systemic_risks": {
    "shared_vulnerabilities": "{count}",
    "cascading_risks": "{count}",
    "weak_boundaries": "{count}"
  }
}
```

### GR3 — Generate Complete Threat Catalog

Consolidate all threat data into a single cross-referenced catalog.

Write to: `docs/security/threat-catalog.json`

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "threats": [
    {
      "id": "BC-{NNN}/{stride_category}/{NNN}",
      "capability_id": "BC-{NNN}",
      "capability_name": "{name}",
      "stride_category": "spoofing | tampering | repudiation | information_disclosure | denial_of_service | elevation_of_privilege",
      "threat": "{threat description}",
      "severity": "CRITICAL | HIGH | MEDIUM | LOW",
      "likelihood": "HIGH | MEDIUM | LOW",
      "attack_vector": "{attack description}",
      "existing_controls": ["{CTRL-NNN: description}"],
      "missing_controls": ["{description}"],
      "related_vulnerabilities": ["{VULN-NNN}"],
      "affected_l2": ["{BC-NNN-NN}"]
    }
  ],
  "summary": {
    "total_threats": 0,
    "critical": 0,
    "high": 0,
    "medium": 0,
    "low": 0
  }
}
```

### GR4 — Generate Domain Model with Security Overlay

Enrich the discovery domain model with the full security assessment. This is the primary handoff artifact — it tells a team not just what they own, but what security risks come with it.

Write to: `docs/security/domain-model-secured.md`

For each capability in the domain model, preserve the full original content AND append a security overlay section:

```markdown
{...original domain model content for this capability, unchanged...}

Security Assessment:
  Risk Score:       {composite} (#{rank} of {total})
  Criticality:      {high | medium | low}
  Data Handled:     {sensitivity classifications}
  Top Threats:      {STRIDE category}: {threat title} ({severity})
                    {STRIDE category}: {threat title} ({severity})
  Confirmed Vulns:  {count} — {VULN-NNN: title at file:line}
  Control Gaps:     {count} — {description}
  Priority:         {IMMEDIATE | SHORT-TERM | MEDIUM-TERM | LOW}

{Repeat for each capability}
```

After generating all files:
- Update `.project/state/workflow.json`: set `step` to `security_complete`, `status` to `completed`
- Tell the user: "Security assessment complete. {N} capabilities assessed, {threats} threats modeled, {vulns} vulnerabilities cataloged ({confirmed} confirmed), {gaps} control gaps identified. Top risk: BC-{NNN} ({name}) with composite score {score}. All artifacts in docs/security/. Primary handoff artifact: docs/security/domain-model-secured.md"

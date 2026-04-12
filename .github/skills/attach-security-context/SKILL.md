---
name: attach-security-context
description: Attach security context to each L1/L2 capability using security signals. Links auth flows, sensitive data, and exposure levels to the capability model. Use this when workflow step is "attach_security_context" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/security/capability-security-contexts.json` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated security context.

Read:
- `docs/security/security-signals.json` ← required
- `docs/discovery/domain-model.md` ← required
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required
- `.project/state/answers.json` (security_scope)

## Process

### SC1 — Map Security Signals to Capabilities

For each L1 and L2 capability, scan `security-signals.json` to find relevant signals:

**Data sensitivity mapping:** From `data_sensitivity` entries, find entities whose `related_capabilities` reference this capability (by name or ID). If `related_capabilities` is empty, infer from entity names and capability description — a "Customer Onboarding" capability almost certainly handles `Customer`, `Person`, and `Address` entities.

**Authentication mapping:** From `static_signals` with category `authentication` or `authorization`, determine which capabilities each signal applies to. Match by:
- File path: signals in `payments/` map to the Payments capability
- Entry point references: if the signal is on a controller or handler, map to the capability that owns that entry point (use domain-model.md for code location references)

**Configuration exposure:** From `configuration_signals`, map CORS, rate limiting, and error handling signals to the capabilities that own those endpoints.

### SC2 — Build Security Context Per Capability

For each capability (L1 and L2), construct a security context block:

**Data sensitivity:** Aggregate all sensitivity classifications from mapped entities (PII, Financial, Authentication, Health, Regulatory). De-duplicate.

**Auth required:** Set `true` if any auth signal applies to this capability. Note the specific mechanisms found.

**External exposure:** Determine from domain-model.md:
- `public`: capability has endpoints accessible without network authentication (public API, web frontend)
- `internal`: capability only accessed from within the system (internal service, admin only)
- `mixed`: some endpoints public, some internal

**Criticality:** Assess based on:
- `high`: handles Financial or Authentication data, OR has public exposure with PII, OR is a dependency for 3+ other capabilities
- `medium`: handles PII without financial data, OR is a dependency for 1-2 other capabilities, OR has internal exposure with sensitive data
- `low`: handles no sensitive data, OR is infrastructure-adjacent, OR has no external dependencies

**Trust boundaries:** Identify from domain-model.md `External` fields — where capabilities interact with third-party services, cross network boundaries, or change privilege levels. Each external integration is a trust boundary.

**Sensitive operations:** List the key operations (from L2) that directly handle sensitive data or perform privileged actions.

**Relevant signals:** Reference the signal IDs (e.g., `SS1-auth-jwt-001`) from `security-signals.json` that informed this context.

### SC3 — Detect Trust Boundaries

Across all capabilities, identify system-level trust boundaries:

A trust boundary exists wherever:
- Internal → External service (KYC provider, payment gateway, notification service)
- Unauthenticated → Authenticated context (login flow, token exchange)
- Lower privilege → Higher privilege (user action triggers admin operation)
- Internal service → Public network

For each boundary:
- `boundary`: description (e.g., "Internal → Fourthline KYC")
- `capabilities`: list of capability IDs that cross this boundary
- `data_crossing`: what data types cross (from data sensitivity of the capability)
- `controls_present`: security controls found in `security-signals.json` that protect this boundary
- `controls_missing`: expected controls not found (e.g., if data crosses but no TLS signal found for that path)

## Output

Generate `docs/security/capability-security-contexts.json`:

```json
{
  "generated_at": "{ISO 8601 timestamp}",
  "contexts": [
    {
      "capability_id": "BC-001",
      "capability_name": "{name}",
      "security_context": {
        "data_sensitivity": ["{PII | Financial | Authentication | Health | Regulatory}"],
        "auth_required": true,
        "auth_mechanisms": ["{JWT | OAuth2 | Session | API Key}"],
        "external_exposure": "public | internal | mixed",
        "criticality": "high | medium | low",
        "sensitive_operations": ["{operation description}"],
        "trust_boundaries_crossed": ["{external service or boundary description}"],
        "relevant_signals": ["{signal IDs from security-signals.json}"]
      },
      "l2_contexts": [
        {
          "capability_id": "BC-001-01",
          "capability_name": "{L2 name}",
          "security_context": {
            "data_sensitivity": ["{classifications}"],
            "auth_required": true,
            "auth_mechanisms": ["{mechanisms}"],
            "external_exposure": "public | internal | mixed",
            "criticality": "high | medium | low",
            "sensitive_operations": ["{operations}"],
            "trust_boundaries_crossed": ["{boundaries}"],
            "relevant_signals": ["{signal IDs}"]
          }
        }
      ]
    }
  ],
  "trust_boundaries": [
    {
      "boundary": "{description}",
      "capabilities": ["{BC-NNN}", "{BC-NNN-NN}"],
      "data_crossing": ["{PII | Financial | Authentication}"],
      "controls_present": ["{control description}"],
      "controls_missing": ["{missing control description}"]
    }
  ],
  "summary": {
    "capabilities_assessed": 0,
    "high_criticality_count": 0,
    "medium_criticality_count": 0,
    "low_criticality_count": 0,
    "trust_boundaries_count": 0,
    "capabilities_with_pii": 0,
    "capabilities_with_financial_data": 0,
    "publicly_exposed_capabilities": 0
  }
}
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `threat_model`, `status` to `in_progress`
- Tell the user: "Security context attached to {N} capabilities ({high} high criticality, {medium} medium, {low} low). {M} trust boundaries identified. Next: per-capability threat modeling."

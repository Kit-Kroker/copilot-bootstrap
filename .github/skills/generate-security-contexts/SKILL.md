---
name: generate-security-contexts
description: Generate AI-ready context packages and security prompts per capability for downstream tooling (Cursor, Copilot, Claude Code). Use this when workflow step is "generate_security_contexts" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/security/generate/security-prompts.md` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated context packages.

Read:
- `docs/discovery/domain-model.md` ← required
- `docs/security/risk-scores.json` ← required
- `docs/security/threats/` ← all BC-{NNN}.json threat model files
- `docs/security/vulnerabilities/catalog.json` ← required
- `docs/security/controls/control-map.json` ← required
- `docs/security/capability-security-contexts.json` ← required
- `docs/security/gaps.json` ← required

## Process

### GC1 — Generate Capability-Scoped AI Context Packages

For each capability (prioritize HIGH and CRITICAL risk first, then MEDIUM, then LOW), generate a self-contained context file.

The purpose of these files is to give an AI tool (Claude Code, Cursor, Copilot) everything it needs to work on a specific capability without needing to read the entire codebase. Constrain scope. Make the security context explicit.

Each context file should include:

**Capability Overview:**
- Name, ID, description (from domain-model.md)
- Composite risk score and risk ranking position

**Code Scope:**
- All file paths and directories that belong to this capability (from domain-model.md L2 code locations)
- Key entry points: API endpoints, scheduled jobs, event consumers
- Key entities owned by this capability

**Security Profile:**
- Data sensitivity: what sensitive data is handled, which entities, which fields
- Auth requirements: authentication and authorization mechanisms expected
- External exposure: public/internal/mixed
- Trust boundaries: which external services this capability integrates with

**Threats:**
- Top 3-5 STRIDE threats (CRITICAL and HIGH) with brief descriptions
- Existing controls that mitigate each

**Vulnerabilities:**
- All CONFIRMED vulnerabilities with file:line evidence
- PROBABLE vulnerabilities with confidence level
- For each: category, severity, and evidence location

**Control Gaps:**
- Missing controls from gaps.json that apply to this capability
- Specific recommendations

**AI Guidance:**
- Specific instructions for working safely on this capability
- What NOT to change without security review
- Compliance constraints that apply (from security_scope)

Write to: `docs/security/generate/capability-contexts/BC-{NNN}-context.md`

```markdown
# BC-{NNN}: {Capability Name} — Security Context

**Risk Score**: {composite} (#{ranking} of {total} by risk)
**Criticality**: {high | medium | low}

## Code Scope

Files and directories for this capability:
- `{path/to/capability/}` — {description}
- `{path/to/specific/file.ext}` — {description}

Key entry points:
- `{HTTP method} {endpoint}` — {what it does}
- `{job name}` — {what it does}

## Security Profile

**Data handled**: {PII | Financial | Authentication} — entities: {entity names}
**Sensitive fields**: {field list}
**Auth required**: {yes/no} via {mechanism}
**Exposure**: {public | internal | mixed}
**External integrations**: {list or "none"}

## Top Threats

{For each CRITICAL/HIGH threat:}
### {STRIDE category}: {threat title} (Severity: {severity})
{2-sentence description of the threat and attack vector}
**Existing controls**: {list or "none"}
**Missing controls**: {list}

## Vulnerabilities

{For each confirmed vulnerability:}
- **{VULN-NNN}**: {title} — {severity} — `{file}:{line}`

{For each probable vulnerability:}
- **{VULN-NNN}** (probable): {title} — {severity} — `{file}:{line}`

## Control Gaps

{For each gap from gaps.json:}
- **{GAP-NNN}**: {description} — {recommendation}

## AI Working Instructions

When working on this capability:
1. All input validation changes must be reviewed against OWASP Input Validation Cheat Sheet
2. Do not log: {list sensitive fields} — these are PII/financial and must not appear in logs
3. Authentication middleware ({mechanism}) must remain on all {public|external} endpoints
4. {Any compliance-specific instruction from security_scope}

Do not modify without explicit security review:
- {list files or patterns that contain security-critical code}
```

### GC2 — Generate Security-Aware Prompts

Generate targeted prompts for AI-assisted security remediation. Each prompt must:
- Reference a specific capability by ID and name
- Reference specific files and line numbers where relevant
- Reference the specific threat or vulnerability being addressed
- Not be generic — no "improve security" prompts

Organize by priority:
1. CRITICAL vulnerability remediation
2. HIGH vulnerability remediation
3. Control gap closure (CRITICAL/HIGH gaps)
4. MEDIUM vulnerability remediation
5. Compliance gap closure
6. Refactoring for least privilege

Prompt format:
```
## {Priority}: {Short Title}

**Capability**: BC-{NNN} {name}
**Addresses**: {VULN-NNN | GAP-NNN | threat ref}
**Severity**: {CRITICAL | HIGH | MEDIUM}

{2-3 sentence prompt with specific files, line numbers, and threat context}

Example:
Analyze `{file path}` for SQL injection. Line {N} concatenates user input into a SQL query string: `{brief code description}`. Rewrite using parameterized queries. Ensure the fix applies consistently to all query construction in this file. Verify against OWASP SQL Injection Prevention Cheat Sheet.
```

Write to: `docs/security/generate/security-prompts.md`

```markdown
# Security Remediation Prompts

Generated {date} | {N} prompts | Ordered by priority

## Usage

These prompts are scoped to specific capabilities and files. Use the capability context file in `docs/security/generate/capability-contexts/` to give the AI tool the full security context before running the prompt.

---

## CRITICAL Priority

{prompts for CRITICAL findings}

---

## HIGH Priority

{prompts for HIGH findings}

---

## MEDIUM Priority

{prompts for MEDIUM findings}

---

## Compliance

{prompts for compliance gaps, if any compliance_targets defined}
```

### GC3 — Generate Specification Seeds

For capabilities with:
- Composite risk score ≥ 0.6 (high enough to warrant modernization consideration), OR
- Listed as "MISSING" or "Partial" in blueprint comparison (if `docs/discovery/blueprint-comparison.md` exists)

Generate a specification seed that includes both functional requirements (from domain model) and security requirements (from assessment).

Write to: `docs/security/generate/spec-seeds/BC-{NNN}-spec-seed.md`

```markdown
# BC-{NNN}: {Capability Name} — Specification Seed

**Purpose**: Starting point for modernization or security-focused refactoring
**Risk Score**: {composite} | **Criticality**: {high | medium | low}

## Functional Scope

{From domain-model.md: 2-3 sentences on what this capability must do}

### L2 Operations to Support

{List each L2 with its key operations — what must be preserved}

### Entity Ownership

{List entities OWNED by this capability with key fields}

### External Dependencies

{List external services/APIs this capability integrates with, and what operations they serve}

## Security Requirements

### Must Preserve (existing controls to maintain)
- {list existing controls that should be kept/improved}

### Must Fix (confirmed vulnerabilities)
- {list confirmed vulnerabilities that must be addressed in any implementation}

### Must Implement (critical gaps)
- {list critical control gaps that must be closed}

### Compliance Constraints

{If compliance targets in security_scope:}
- {GDPR}: {specific requirements for this capability's data}
- {PCI-DSS}: {specific requirements for financial data handling}

## Recommended Architecture Notes

{2-3 sentences on security-relevant architectural decisions for this capability, based on threats and gaps identified}
```

After generating all files:
- Update `.project/state/workflow.json`: set `step` to `security_report`, `status` to `in_progress`
- Tell the user: "Security context packages generated for {N} capabilities. {prompts} targeted remediation prompts created ({critical} CRITICAL, {high} HIGH priority). {seeds} specification seeds generated for high-risk capabilities. Next: generate security assessment report."

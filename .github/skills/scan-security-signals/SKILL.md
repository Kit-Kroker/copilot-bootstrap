---
name: scan-security-signals
description: Extract security signals from the codebase — authentication patterns, dependency vulnerabilities, configuration exposure, and data sensitivity classification. Runs after discover-candidates or in parallel. Use this when workflow step is "scan_security" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/security/security-signals.json` already exists, report that it was found and skip to the next step. This allows users to provide pre-generated security analysis from external tools.

Read:
- `.project/state/answers.json` (specifically `codebase_setup`: path, language, architecture, database_path, has_frontend, and `security_scope`: standard, threat_modeling, compliance_targets, risk_tolerance)
- The codebase at the configured path
- `docs/discovery/candidates.md` ← optional (for cross-referencing data sensitivity with capabilities)

## Security Context

Before scanning, read `security_scope` from `.project/state/answers.json`. If not present, apply defaults:
- `standard`: `OWASP_ASVS`
- `threat_modeling`: `true`
- `compliance_targets`: `[]`
- `risk_tolerance`: `medium`

## Signal Extraction (4 sub-steps)

### SS1 — Static Security Signals

Scan the codebase for security-relevant code patterns:

**Authentication mechanisms:**
- JWT usage: look for `jsonwebtoken`, `jose`, `jwt.verify`, `jwt.sign`, `JWT`, `JwtHelper`, `JwtService`
- OAuth providers: look for OAuth2 flows, `passport`, `openid-connect`, Google/Facebook/GitHub auth integrations
- Session management: `express-session`, `HttpSession`, `ISession`, `session_store`, cookie configuration
- API key authentication: `x-api-key`, `Authorization: ApiKey`, `api_key` headers

**Authorization patterns:**
- RBAC: role-based checks, `@Role`, `[Authorize(Roles=...)]`, `hasRole`, `user.roles`, `permission.check`
- Middleware guards: `AuthMiddleware`, `RoleGuard`, `PermissionGuard`, `@UseGuards`, `[Authorize]`
- Resource-level checks: ownership verification patterns, `userId == resource.ownerId`

**Password handling:**
- Secure: `bcrypt`, `argon2`, `scrypt`, `PBKDF2`, `password_hash`
- Weak (flag as HIGH risk): `md5`, `sha1`, `sha256` used for passwords, plain text comparison
- Salt usage: look for salt generation alongside hash functions

**TLS enforcement:**
- HTTPS redirects, `requireHttps`, `HSTS`, `Strict-Transport-Security`
- Certificate pinning, SSL configuration, `ssl=true` in connection strings

**Input validation:**
- Parameterized queries: `?`, `@param`, `$1`, ORM query builders
- Raw SQL concatenation (flag as HIGH risk): string interpolation in SQL contexts
- Input sanitization: `sanitize`, `escape`, `strip_tags`, validation decorators

**Secrets handling:**
- Hardcoded credentials (flag as CRITICAL): passwords, API keys, tokens in source files
- `.env` usage: `process.env`, `Environment.GetEnvironmentVariable`, `os.environ`
- Vault integration: HashiCorp Vault, AWS Secrets Manager, Azure Key Vault
- API keys in code: check for patterns like `sk_`, `pk_`, `Bearer `, hardcoded tokens

**Encryption usage:**
- At-rest: field encryption, column encryption, `@Encrypted`, `[Encrypted]`
- Key management: key rotation, KMS integration, key derivation

For each signal found, record:
- `category`: authentication | authorization | password | tls | input_validation | secrets | encryption
- `pattern`: descriptive name of what was found
- `location`: `{ "file": "...", "line": N }`
- `confidence`: HIGH (direct evidence) | MEDIUM (inferred) | LOW (contextual)
- `detection_method`: `static_pattern` | `ast_analysis` | `inference`
- `details`: specific finding description

### SS2 — Dependency Vulnerability Signals

Identify and analyze all dependency manifest files:
- JavaScript/TypeScript: `package.json`, `package-lock.json`, `yarn.lock`
- Java: `pom.xml`, `build.gradle`, `gradle.lockfile`
- Python: `requirements.txt`, `Pipfile`, `Pipfile.lock`, `pyproject.toml`
- Ruby: `Gemfile`, `Gemfile.lock`
- .NET: `*.csproj`, `packages.config`, `*.deps.json`
- Go: `go.mod`, `go.sum`
- Rust: `Cargo.toml`, `Cargo.lock`

For each manifest found:
1. Extract all direct dependencies with their declared versions
2. Flag dependencies matching known risk patterns:
   - **Outdated major versions**: libraries significantly behind current major (e.g., lodash 3.x when 4.x exists)
   - **Known problematic packages**: `event-stream`, `flatmap-stream`, packages with known supply chain incidents
   - **Deprecated packages**: packages with `DEPRECATED` notices on npm/pypi/maven
   - **Abandoned packages**: no releases in 2+ years with known CVEs
3. Note: Full CVE lookup requires external tools (npm audit, snyk, OWASP dependency-check). Flag this as a limitation and record what can be determined statically.

For each dependency signal:
- `manifest`: the file path
- `dependency`: package name
- `version`: declared version
- `risk`: HIGH | MEDIUM | LOW
- `reason`: explanation of why flagged

### SS3 — Configuration & Infrastructure Signals

Extract security-relevant configuration:

**CORS configuration:**
- Origins: wildcard `*` (HIGH risk), specific domains, `reflect-origin` patterns
- Credentials: `credentials: true` with wildcard origin (CRITICAL)
- Methods: overly permissive method lists

**Exposed ports and binding:**
- Binding to `0.0.0.0` (externally accessible), vs `127.0.0.1` (local only)
- Non-standard ports, debug ports (9229, 5005) in production configs

**Rate limiting:**
- API rate limiting: `express-rate-limit`, `throttle`, `@Throttle`, `[RateLimit]`
- Brute force protection on auth endpoints
- Absence of rate limiting on public endpoints (flag as MEDIUM risk)

**Database connection security:**
- SSL/TLS in connection strings: `ssl=true`, `sslmode=require`
- Default credentials in config files
- Connection string with credentials (flag if not using env vars)

**Logging configuration:**
- Log levels in production: DEBUG level in prod (MEDIUM risk)
- PII in log statements: `log(user.email)`, `log(password)`, `log(token)`
- Log injection: unsanitized user input in log statements

**Error handling:**
- Stack traces to clients: `res.json(err.stack)`, verbose error middleware
- Verbose error messages: database errors exposed to API consumers
- Generic error handlers that swallow security exceptions

**Environment-specific configs:**
- Dev vs prod divergence in security settings
- Feature flags disabling security controls

For each signal:
- `category`: cors | ports | rate_limiting | database | logging | error_handling | config_divergence
- `finding`: description of what was found
- `location`: `{ "file": "...", "line": N }`
- `risk_level`: HIGH | MEDIUM | LOW
- `details`: specific details

### SS4 — Data Sensitivity Classification

From schema files, ORM models, entity definitions, and code:

Classify entities/tables by sensitivity level:
- **PII**: names (`first_name`, `last_name`, `full_name`), emails, phone numbers, addresses, dates of birth, national IDs, passport numbers
- **Financial**: account numbers, transaction amounts, card details (`card_number`, `cvv`, `pan`), balances, payment methods
- **Authentication**: passwords (any field), tokens, API keys, session data, refresh tokens, MFA secrets
- **Health**: medical records, diagnoses, prescriptions, health metrics (if applicable)
- **Regulatory**: any entity subject to GDPR (EU personal data), PCI-DSS (cardholder data), HIPAA (PHI)

For each sensitive entity:
- `entity`: class/model name
- `table`: database table name (if known)
- `classification`: array of applicable categories (PII, Financial, Authentication, Health, Regulatory)
- `sensitive_fields`: list of specific sensitive field names
- `related_capabilities`: capabilities that handle this entity (cross-reference `candidates.md` if available; leave empty if not)

## Output

Create directory structure if it doesn't exist:
```
docs/security/
  findings/
  threats/
  vulnerabilities/
  controls/
  generate/
    capability-contexts/
    spec-seeds/
```

Generate `docs/security/security-signals.json`:

```json
{
  "scan_metadata": {
    "timestamp": "{ISO 8601 timestamp}",
    "codebase_path": "{path from answers.json}",
    "security_standard": "{standard from security_scope}",
    "compliance_targets": ["{targets from security_scope}"],
    "signal_sources": ["SS1", "SS2", "SS3", "SS4"],
    "limitations": ["Full CVE lookup requires external tools (npm audit, snyk, OWASP dependency-check)"]
  },
  "static_signals": [
    {
      "id": "SS1-{category}-{NNN}",
      "category": "{category}",
      "pattern": "{pattern name}",
      "location": { "file": "{path}", "line": 0 },
      "confidence": "HIGH | MEDIUM | LOW",
      "detection_method": "static_pattern | ast_analysis | inference",
      "details": "{description}"
    }
  ],
  "dependency_signals": [
    {
      "manifest": "{manifest file path}",
      "dependency": "{package name}",
      "version": "{version}",
      "risk": "HIGH | MEDIUM | LOW",
      "reason": "{why flagged}"
    }
  ],
  "configuration_signals": [
    {
      "id": "SS3-{category}-{NNN}",
      "category": "{category}",
      "finding": "{finding description}",
      "location": { "file": "{path}", "line": 0 },
      "risk_level": "HIGH | MEDIUM | LOW",
      "details": "{details}"
    }
  ],
  "data_sensitivity": [
    {
      "entity": "{entity name}",
      "table": "{table name or null}",
      "classification": ["{PII | Financial | Authentication | Health | Regulatory}"],
      "sensitive_fields": ["{field name}"],
      "related_capabilities": ["{capability name if known}"]
    }
  ],
  "summary": {
    "static_signals_count": 0,
    "dependency_signals_count": 0,
    "configuration_signals_count": 0,
    "sensitive_entities_count": 0,
    "high_risk_count": 0,
    "medium_risk_count": 0,
    "low_risk_count": 0
  }
}
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `attach_security_context`, `status` to `in_progress`
- Tell the user: "{N} security signals extracted ({auth} authentication, {dep} dependency risks flagged, {config} configuration signals, {data} sensitive entities classified). Next: attach security context to capabilities."

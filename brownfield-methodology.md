# Evidence-Driven Capability Reconstruction (EDCR) + Security Assessment Extension

## Overview

This framework reconstructs business capabilities directly from existing codebases, then layers a first-class security assessment on top of the same evidence. It replaces both manual architecture discovery and generic security scanning with a single, traceable pipeline.

The result is a unified model that maps **business capabilities, implementation structure, and security posture** — with shared evidence, stable identifiers, and full code traceability.

---

## Glossary

See [EDRC-glossary.md](EDRC-glossary.md) for the full term reference — capability model, signal extraction, security assessment, reports, migration, and abbreviations.

---

## Core Principles

1. **Security is capability-aware.** Vulnerabilities are assessed per capability, not per system. A threat mapped to a capability, its data, and its trust boundary is actionable. A threat without that context is noise.

2. **Evidence over assertion.** Every capability, threat, and risk score traces back to specific files, entry points, entities, and configurations in the codebase. No capability exists without code-level proof. No security finding exists without a detection method and confidence level.

3. **Business lens over deployment lens.** When deployment boundaries and business boundaries disagree, the business lens wins. A microservice boundary is not a capability boundary. A parameter variation (e.g., scheduled payments = payments + frequency) does not create a new capability.

4. **Explicit ambiguity over false confidence.** A half-right model is more dangerous than a wrong one. A wrong model gets challenged in the first review. One that nails half the capabilities and misclassifies the rest reads professionally, looks credible, and gets nodded through. When the pipeline cannot determine something from code alone, it flags — it does not guess.

5. **Adaptive by default.** The pipeline does not assume perfect visibility. If database access is unavailable, schema analysis is skipped. If there is no frontend layer, UI entry point analysis is removed. The sequence adjusts without breaking the overall flow.

---

## Pipeline

```
/init → /scan → /discover → [/report] → /assess → /generate → /finish
```

`/report` is optional and can be run at any point after `/discover` completes. If run after `/assess`, it also generates the security report.

Each phase reads defined inputs, produces defined outputs, and feeds the next. If context breaks — and on large codebases it will — you resume from the last completed phase. Outputs are written to files, so nothing is lost.

---

# `/init` — Initialization & Context Setup

## Purpose

Establish the project context, configure the security scope, and prepare the evidence stores that all downstream phases will write into. This phase produces no analytical output — it sets up the infrastructure for everything that follows.

## Inputs

- Project metadata: codebase path, primary language, architecture style (monolith / modular-monolith / microservices), database path (if available), whether a frontend layer exists
- Security scope parameters: compliance targets, threat modeling standard, risk tolerance
- Pre-generated external inputs (optional): package exports from nDepend or Structure101, database schemas from a DBA, entry point lists from IDE analyzers, architecture notes or existing documentation

## Process

### Project Context

Capture the system identity and structural characteristics:

```json
{
  "project_info": {
    "name": "...",
    "domain": "banking | telecom | insurance | retail | ...",
    "description": "..."
  },
  "codebase_setup": {
    "path": "/path/to/codebase",
    "language": "C# | Java | Python | ...",
    "architecture": "monolith | modular-monolith | microservices",
    "database_path": "/path/to/schema/or/migrations | null",
    "has_frontend": true,
    "reports": ["path/to/ndepend-export.xml", "path/to/schema-dump.sql"]
  }
}
```

### Security Context

Define the security assessment scope. This determines what the `/assess` phase evaluates against:

```json
{
  "security_scope": {
    "standard": "OWASP_ASVS | NIST | custom",
    "threat_modeling": true,
    "compliance_targets": ["GDPR", "PCI-DSS"],
    "risk_tolerance": "low | medium | high"
  }
}
```

### Evidence Store Initialization

Create the directory structure that all phases write into:

```
/evidence/
  ├── discovery/
  │   ├── candidates.md
  │   ├── analysis.md
  │   ├── coverage.md
  │   ├── l1-capabilities.md
  │   ├── l2-capabilities.md
  │   ├── domain-model.md
  │   └── blueprint-comparison.md
  ├── security/
  │   ├── findings/
  │   ├── threats/
  │   ├── vulnerabilities/
  │   ├── controls/
  │   └── security-signals.json
  └── state/
      └── workflow.json
```

### Pre-Generated Input Registration

When externally generated analysis files are provided (nDepend exports, DBA schema dumps, IDE-generated entry point lists, architecture notes), register them for use in `/scan`. These inputs do not replace analysis — they anchor it in higher-quality signals. The model does less guesswork and more verification.

## Output

- `context.json` — project metadata, codebase setup, security scope
- `workflow.json` — pipeline state tracker (current phase, status, completion timestamps)
- Initialized directory structure for all evidence artifacts

## Exit Criteria

Context is recorded, security scope is defined, evidence stores exist. The pipeline is ready for signal extraction.

---

# `/scan` — Multi-Source Signal Extraction

## Purpose

Extract raw signals independently from multiple sources in the codebase. This phase does not interpret or classify — it collects evidence that `/discover` will synthesize into capability candidates and that `/assess` will use for security evaluation.

The key design choice: each signal source is analyzed independently before merging. A signal that appears across multiple sources carries high confidence. One that shows up in only one source gets a medium or low rating. This cross-referencing is what separates pipeline-driven extraction from single-pass analysis.

## Inputs

- `context.json` — codebase path, language, architecture, database access, frontend presence
- Pre-generated reports (if registered in `/init`)
- The codebase itself

## Process

### Capability Signals (5 sub-steps)

#### S1 — Package Structure Analysis

Scan the top-level directory structure and module/package organization.

**Strong signals**: Domain-suggestive names — `payments`, `customers`, `orders`, `lending`, `accounts`, `notifications`, `auth`. These exist because developers named them deliberately. That discipline is what makes extraction possible.

**Ambiguous signals**: Generic names — `processing`, `management`, `utils`, `common`, `shared`, `core`. These require corroboration from other sources.

**Infrastructure (not capabilities)**: `config`, `middleware`, `migrations`, `tests`, `scripts`, `build`.

For each package/module, record: name, path, approximate file count and line count, whether it contains business logic or is infrastructure.

#### S2 — Database Schema Analysis

*Skip if `codebase_setup.database_path` is null and no migration files are found.*

In legacy systems, the database often reveals business domains more clearly than the code. Analyze:

- Table clusters that suggest business domains
- Foreign key relationships that reveal entity dependencies
- Stored procedures or triggers grouped by domain
- Enum types that encode business concepts
- Migration files that show schema evolution

#### S3 — Backend Entry Point Analysis

Identify all backend entry points:

- REST/API controllers — group by resource/domain, not by HTTP method
- Scheduled jobs / cron tasks — background business operations
- Message consumers — event-driven operations (Kafka, RabbitMQ, SQS, etc.)
- CLI commands — administrative operations
- RPC/gRPC services — service-to-service operations

**Key rule**: Group by business operation, not by technical type. A `PaymentController`, a `RecurringPaymentJob`, and a `PaymentEventConsumer` are all evidence of the same "Payments" capability — not three separate candidates.

#### S4 — Frontend/UI Entry Point Analysis

*Skip if `codebase_setup.has_frontend` is false.*

- Pages/routes — each route maps to a user journey
- Navigation structure — menus, sidebars, breadcrumbs reveal capability hierarchy
- Feature folders — frontend module organization
- Screen components — major views and their purpose

#### S5 — Signal Merge & Confidence Rating

Cross-reference all signal sources (S1–S4). Assign confidence:

- **HIGH**: Candidate appears in 3+ signal sources (package + DB + entry points)
- **MEDIUM**: Candidate appears in 2 sources, or is strong in 1 but ambiguous
- **LOW**: Candidate appears in only 1 source with weak evidence

Flag ambiguous candidates with a specific reason:
- "Is this a standalone capability or a feature within another domain?"
- "Is this active in the system or a leftover artifact?"
- "Is this a business capability or infrastructure/cross-cutting concern?"

**Target**: 15–25 raw candidates across all confidence levels.

### Security Signals (4 sub-steps)

Extracted in parallel with capability signals, using the same codebase pass.

#### SS1 — Static Security Signals

Extract authentication and authorization patterns:

- JWT usage, OAuth providers, session management
- Password hashing methods, credential storage
- Role-based access control patterns, permission checks
- TLS enforcement, certificate handling
- Input validation patterns (or absence of them)
- Secrets handling — hardcoded credentials, environment variable usage, vault integration

#### SS2 — Dependency Vulnerability Signals

Analyze dependency manifests (`package.json`, `pom.xml`, `requirements.txt`, `.csproj`, etc.):

- Known CVEs in declared dependencies
- Outdated libraries with known security issues
- Transitive dependency risks

Output: `evidence/security/security-dependencies.json`

#### SS3 — Configuration & Infrastructure Signals

Extract security-relevant configuration:

- Environment configs (dev vs. prod divergence)
- Exposed ports and network surface
- CORS settings (overly permissive origins)
- API gateway configs (rate limiting, WAF rules)
- Database connection security (SSL, credential rotation)
- Logging configuration (sensitive data in logs)

#### SS4 — Data Sensitivity Signals

From schema and code, classify entities by sensitivity:

- PII (names, emails, addresses, phone numbers)
- Financial data (account numbers, transaction amounts, card details)
- Authentication data (passwords, tokens, API keys)
- Health data (if applicable)
- Regulatory data (anything subject to GDPR, PCI-DSS, HIPAA)

### Signal Quality Requirements

All signals — capability and security — must include:

- **Confidence level**: HIGH / MEDIUM / LOW
- **Detection method**: static analysis, pattern inference, external database lookup, pre-generated input
- **Source location**: specific file paths, line ranges, or configuration keys

## Output

- `evidence/discovery/candidates.md` — 15–25 raw capability candidates with confidence ratings and evidence trails
- `evidence/security/security-signals.json` — all security signals, classified and confidence-rated
- `evidence/security/security-dependencies.json` — dependency vulnerability report

## Exit Criteria

All applicable signal sources have been extracted independently. Each candidate and security signal has a confidence rating and traceable evidence. The pipeline is ready for capability synthesis and analysis.

---

# `/discover` — Capability Analysis, Verification & Locking

## Purpose

Transform raw candidates into a validated, locked capability model with two levels of granularity. This phase performs four distinct activities in sequence: deep analysis of each candidate, coverage verification, L1 locking, and L2 decomposition. It also attaches the security context from `/scan` to each capability.

This is where structural signals meet business judgment. The pipeline does not just confirm what it finds — it forces every candidate into an explicit decision and flags what it cannot determine.

## Inputs

- `evidence/discovery/candidates.md` — raw candidates from `/scan`
- `evidence/security/security-signals.json` — security signals from `/scan`
- `context.json` — codebase setup
- The codebase itself (for deep code analysis)

## Process

### D1 — Deep Candidate Analysis

For each candidate, assess three dimensions:

**Cohesion** — Does the candidate have a single, coherent business responsibility?
- HIGH: All code serves one business purpose
- MEDIUM: Mostly coherent, with some tangential functionality
- LOW: Mixed concerns, multiple unrelated operations

**Coupling** — How many other candidates does it depend on?
- LOW (good): 0–1 dependencies
- MEDIUM: 2–3 dependencies
- HIGH (concerning): 4+ dependencies

**Boundary Clarity** — Does it have clean interfaces?
- CLEAR: Well-defined API/interface, minimal internal exposure
- PARTIAL: Some clean boundaries, some shared state or circular dependencies
- UNCLEAR: Deeply entangled, no clear separation

### D2 — Action Determination

Force each candidate into exactly one action:

- **CONFIRM** — Valid L1 business capability. High cohesion, clear boundaries.
- **SPLIT** — Contains multiple distinct business capabilities. Define what to split into.
- **MERGE** — Sub-feature of another capability, not independent. Specify target and rationale.
- **DE-SCOPE** — Not a business capability. Infrastructure, cross-cutting concern, test harness, or delivery channel. Classify what it actually is.
- **FLAG** — Cannot determine from code alone. Needs architect or domain expert input. State the specific question.

**Decision heuristics:**

- A delivery channel (mobile app, web portal) is NOT a capability — it's how capabilities are accessed.
- Infrastructure (logging, config, auth middleware) is NOT a capability — it's cross-cutting.
- If it has its own microservice but is a parameter variation of another capability (e.g., "scheduled payments" = payments + frequency), MERGE it.
- If deployment boundaries and business boundaries disagree, trust the business lens. A service boundary is not a capability boundary.
- When in doubt between CONFIRM and FLAG, prefer FLAG. Explicit ambiguity is more useful than false confidence.

### D3 — Coverage Verification

Map all source files to discovered capabilities. Target: >90% coverage.

For each orphan file/directory not mapped to any capability:
- **Assign to existing capability** — clearly part of a capability but missed
- **Create new capability** — represents undiscovered business functionality
- **Mark as infrastructure** — cross-cutting (logging, config, middleware, build scripts)
- **Mark as dead code** — appears unused or is a leftover artifact

Identify shared files that serve multiple capabilities — these are coupling indicators.

### D4 — Lock L1 Capabilities

Finalize the L1 list from all preceding decisions:

1. Confirmed candidates → include as-is
2. Split candidates → include each part as a separate L1
3. Merged candidates → absorbed into their target (not listed separately)
4. New capabilities from coverage → include
5. De-scoped and flagged → excluded, documented for reference

Assign stable IDs: `BC-001`, `BC-002`, etc. Group related capabilities together. Core capabilities first, supporting after.

### D5 — L2 Sub-Capability Decomposition

For each L1 capability, identify Level 2 sub-capabilities. L1 defines the system at a functional level — what exists. L2 defines it at an operational level — what can be acted on, migrated, extended, or replaced.

Each L2 should be an **executable unit of work** — something a team can own independently.

For each L2:

- Map to specific code locations (files, classes, functions)
- Identify key entities with ownership semantics:
  - **OWNS** — source of truth, single writer
  - **CREATES** — creates instances; another capability owns the record
  - **MANAGES** — full CRUD via external API (no local table)
  - **TRACKS** — reads and monitors state owned elsewhere
  - **READS** — read-only consumer
- List key operations (API endpoints, job triggers, message topics)
- Identify external dependencies (third-party APIs, services, providers)

Assign L2 IDs: `BC-{L1}-{NN}` (e.g., BC-001-01, BC-001-02).

### D6 — Security Context Attachment

Extend each capability (L1 and L2) with security context derived from `/scan` signals:

```json
"security_context": {
  "data_sensitivity": ["PII", "financial"],
  "auth_required": true,
  "auth_mechanisms": ["JWT", "OAuth2"],
  "external_exposure": "public | internal",
  "criticality": "low | medium | high",
  "sensitive_operations": ["payment processing", "identity verification"],
  "trust_boundaries_crossed": ["external KYC provider", "payment gateway"]
}
```

Link security signals to capabilities: auth flows, sensitive data usage, external endpoints, configuration exposures.

### D7 — Domain Model Generation

Build a consolidated domain model — a single, traceable representation of what the system does. Each capability entry must be self-contained: a team handed a single entry should know exactly what to own, where to find it, what it depends on, and what its security profile is.

```
BC-{NNN}: {Capability Name}                              {L2 count} L2s
─────────────────────────────────────────────────────────────────────────
{2-3 sentence description of what this capability orchestrates.}

L2 Operations:

  BC-{NNN}-01: {L2 Name}
    Code:       {package/module path}
    Entities:   {OWNS EntityA, CREATES EntityB}
    Operations:
      - {description} ({HTTP method} {endpoint})
    External:   {third-party service} ({purpose})

  BC-{NNN}-02: {L2 Name}
    ...

Security Context:
  Data Sensitivity: {PII, financial, authentication, ...}
  Auth Required:    {yes/no — mechanism}
  Exposure:         {public / internal}
  Criticality:      {low / medium / high}

Cross-Capability Dependencies:
  → BC-{NNN} {Capability Name} ({what is shared or created})
```

Include: entity catalog, entity ownership matrix, dependency graph, bounded context candidates, and infrastructure/cross-cutting concerns.

### D8 — Industry Blueprint Comparison

Compare the code-derived model against an industry capability reference:

| Domain | Reference Framework |
|--------|-------------------|
| Banking, finance, payments | BIAN |
| Telecom, communications | TM Forum |
| Insurance | ACORD |
| Healthcare | HL7 / FHIR |
| Retail, e-commerce | ARTS |
| Cross-industry / other | APQC |

Classify each capability:
- **ALIGNED** — maps to an expected industry capability
- **ORG-SPECIFIC** — exists but has no industry equivalent
- **MISSING** — expected by industry, absent from code

The MISSING category is the most useful output. It drives targeted questions: is this handled by an external system, or is it a genuine gap? This is context for modernization planning, not validation — the code remains the source of truth.

## Output

- `evidence/discovery/analysis.md` — detailed per-candidate analysis with actions
- `evidence/discovery/coverage.md` — file-to-capability mapping, orphan resolution
- `evidence/discovery/l1-capabilities.md` — locked L1 list with stable IDs
- `evidence/discovery/l2-capabilities.md` — L2 sub-capabilities per L1
- `evidence/discovery/domain-model.md` — consolidated domain model with security contexts
- `evidence/discovery/blueprint-comparison.md` — industry alignment analysis

## Exit Criteria

1. Every candidate has an explicit action (confirm/split/merge/de-scope/flag)
2. Coverage exceeds 90%
3. L1 capabilities are locked with stable IDs
4. L2 sub-capabilities are defined with code traceability
5. Security context is attached to every capability
6. Domain model is generated with full evidence
7. Industry comparison is complete

---

# `/report` — Discovery Report Suite

## Purpose

Translate the evidence produced by `/discover` (and optionally `/assess`) into four audience-specific documents. Each report is derived directly from the discovery artifacts and includes inline source links so every conclusion traces back to the file it came from.

This phase is **optional and non-blocking** — it does not alter pipeline state and can be re-run at any time after `/discover` completes. The security report is conditionally generated: if `/assess` has not been run, that step is skipped with a note directing to `/assess`.

## Inputs

- `evidence/discovery/l1-capabilities.md` — required for all three discovery reports
- `evidence/discovery/blueprint-comparison.md` — required (all 7 discovery steps must be complete)
- `evidence/discovery/domain-model.md`, `analysis.md`, `coverage.md`, `l2-capabilities.md`
- `evidence/security/risk-scores.json` — checked to determine whether security report is available
- All `/assess` outputs — if present, used by both the architect report (security overlay) and the security report

## Process

### Report 1 — Stakeholder Report

**Audience**: executives, product managers, business analysts, engineering managers

**Writes to**: `evidence/discovery/stakeholder-report.md`

Translates all discovery outputs into plain language — no technical terms, no file paths, no code. Every section includes a `*Source:*` citation linking to the specific artifact it draws from:

- **What This System Does** — plain-language system description `[domain-model.md]`
- **Core Business Capabilities** — capability list with health signals (Strong / Needs Attention / At Risk) `[l1-capabilities.md · analysis.md]`
- **System Health Overview** — coverage and orphan code as business risk `[analysis.md · coverage.md]`
- **Industry Alignment** — alignment summary with genuine gaps separated from externally-handled capabilities `[blueprint-comparison.md]`
- **Key Findings** — strengths and concerns with capability names and business impact `[analysis.md · blueprint-comparison.md · coverage.md]`
- **Modernisation Positioning** — Retain / Extend / Refactor / Evaluate / Replace per capability `[analysis.md · blueprint-comparison.md]`
- **Proposed Team Ownership** — ownership areas from bounded context analysis `[domain-model.md]`

The "About This Report" section includes a linked artifact index pointing to all technical discovery files.

### Report 2 — Architect Report

**Audience**: solutions architects, enterprise architects

**Writes to**: `evidence/discovery/architect-report.md`

Technical report using DDD terminology, capability IDs, and metric values. Every section includes a `*Source:*` citation:

- **System Overview** — tech stack, dominant architectural style, code volume `[domain-model.md · l1-capabilities.md]`
- **Capability Topology** — cohesion/coupling/LOC table for all capabilities, sorted by coupling DESC `[l1-capabilities.md · l2-capabilities.md · analysis.md]`
- **Coupling Analysis** — per-capability deep analysis for HIGH/VERY HIGH coupling `[analysis.md]`
- **Bounded Context Analysis** — context candidates with cross-context dependency table `[domain-model.md · analysis.md]`
- **Decomposition Options** — ranked feasibility options given current coupling topology `[analysis.md · domain-model.md]`
- **Modernisation Positioning** — posture per capability with metric-level rationale `[analysis.md · blueprint-comparison.md]`
- **Industry Blueprint Gaps** — architect-framed gap analysis (net-new vs. vendor vs. integration) `[blueprint-comparison.md]`
- **Code Coverage & Orphan Zones** — orphan hotspots with architectural risk assessment `[coverage.md]`
- **Security Risk Overlay** — condensed per-capability risk summary for architectural planning `[../security/domain-model-secured.md]` *(if available)*

Discovery artifacts table at the bottom links to all source files.

### Report 3 — Dev Report

**Audience**: developers, tech leads, engineering managers

**Writes to**: `evidence/discovery/dev-report.md`

Engineering-focused report using exact file paths, capability IDs, metric values, and line counts. Every section includes a `*Source:*` citation:

- **Capability Map** — capability-to-code mapping with file paths and L2 sub-capability table `[l1-capabilities.md · l2-capabilities.md · analysis.md · domain-model.md]`
- **Ownership Assignments** — squad assignments from bounded context candidates `[domain-model.md]`
- **Health Dashboard** — cohesion/coupling/LOC quick-scan for sprint planning `[analysis.md]`
- **Refactor Targets** — At Risk capabilities with specific techniques, scope estimates, and evidence `[analysis.md]`
- **Orphan Code** — hotspots with paths, LOC, and recommended action per zone `[coverage.md]`
- **Coverage Breakdown** — per-capability LOC and coverage percentage `[coverage.md]`
- **Security Findings for Developers** — confirmed CRITICAL/HIGH vulnerabilities with file:line references and specific fixes; critical control gaps with where-to-add guidance `[../security/vulnerabilities/catalog.json · ../security/gaps.json]` *(if available)*
- **Sprint Recommendations** — 5–7 ticket-ready action items with scope estimates

Discovery artifacts table at the bottom links to all source files.

### Report 4 — Security Report

**Audience**: security team, tech leads

**Writes to**: `evidence/security/security-report.md`

Conditionally generated — only if `evidence/security/risk-scores.json` exists (i.e. `/assess` has completed). Also produces `security-risk-map.json`, `threat-catalog.json`, and `domain-model-secured.md`.

Content: risk-ranked CRITICAL/HIGH findings with file:line references, mitigation priorities (Immediate / Short-term / Medium-term), compliance posture per target standard, systemic cross-capability risks, and the domain model enriched with full security overlay per capability.

## Source Linking Convention

Every section header in every report carries a source line:

```
*Source: [filename](relative-path)* 
```

or for multiple sources:

```
*Sources: [analysis.md](analysis.md) · [blueprint-comparison.md](blueprint-comparison.md)*
```

Relative paths use the report's location as the base (`evidence/discovery/`). Links to security artifacts use `../security/filename`. This ensures every conclusion in every report is one click from the raw evidence it draws from.

## Output

- `evidence/discovery/stakeholder-report.md` — plain-language capability summary
- `evidence/discovery/architect-report.md` — bounded context and coupling analysis
- `evidence/discovery/dev-report.md` — engineering team guide with file-level detail
- `evidence/security/security-report.md` — risk-ranked security findings *(if `/assess` has run)*
- `evidence/security/security-risk-map.json` — machine-readable risk map *(if `/assess` has run)*
- `evidence/security/threat-catalog.json` — complete threat catalog *(if `/assess` has run)*
- `evidence/security/domain-model-secured.md` — domain model with security overlay *(if `/assess` has run)*

## Exit Criteria

All three discovery reports are generated. Security report is generated if `/assess` has run, or skipped with a clear message if not. Every section in every report includes a source link to the artifact it draws from.

---

# `/assess` — Security Assessment Phase

## Purpose

Evaluate security posture **per capability**, not per system. This phase uses the capability model from `/discover` and the security signals from `/scan` to produce capability-aware threat models, vulnerability classifications, control mappings, and risk scores.

A generic security scan treats the system as a flat surface. This phase treats it as a structured set of business capabilities with different criticality levels, data sensitivities, trust boundaries, and exposure profiles. That structure changes what matters. A SQL injection in an internal admin tool and a SQL injection in a public-facing payment endpoint are not the same risk, even though they are the same vulnerability class.

## Inputs

- `evidence/discovery/domain-model.md` — capability model with security contexts
- `evidence/security/security-signals.json` — all security signals
- `evidence/security/security-dependencies.json` — dependency vulnerabilities
- `context.json` — security scope, compliance targets

## Process

### Phase 1 — Threat Modeling (Per Capability)

For each capability, generate a threat model using STRIDE:

- **Spoofing** — Can an attacker impersonate a legitimate user or system? Evaluate against the capability's auth mechanisms.
- **Tampering** — Can data be modified in transit or at rest? Evaluate against the capability's data sensitivity and integrity controls.
- **Repudiation** — Can actions be denied? Evaluate against audit logging and non-repudiation controls.
- **Information Disclosure** — Can sensitive data leak? Evaluate against the capability's data classification and access controls.
- **Denial of Service** — Can the capability be overwhelmed? Evaluate against the capability's external exposure and rate limiting.
- **Elevation of Privilege** — Can an attacker gain unauthorized access? Evaluate against the capability's authorization patterns and trust boundaries.

Output per capability: `evidence/security/threats/{capability_id}.json`

### Phase 2 — Vulnerability Detection

Combine evidence from multiple detection methods:

- Static patterns from code analysis (SS1)
- Dependency vulnerabilities from manifest analysis (SS2)
- Configuration misconfigurations (SS3)
- Data exposure risks from sensitivity classification (SS4)

Classify each finding:

- **Confirmed** — Vulnerability is directly observable in code with clear exploit path
- **Probable** — Pattern strongly suggests vulnerability but requires runtime verification
- **Potential** — Theoretical vulnerability based on architecture or configuration

### Phase 3 — Control Mapping

For each identified threat and vulnerability, map existing controls:

- **Authentication controls** — What mechanisms protect access? Are they correctly implemented?
- **Authorization controls** — What permission models are enforced? Are there bypass paths?
- **Validation controls** — What input validation exists? Are there gaps?
- **Monitoring controls** — What is logged and alerted on? What is invisible?
- **Encryption controls** — What is encrypted at rest and in transit? What is not?

For each control, assess: is it present? Is it correctly implemented? Is it consistently applied across the capability's L2 operations?

### Phase 4 — Risk Scoring (Per Capability)

Score each capability across three dimensions:

```json
"risk_score": {
  "likelihood": 0.0-1.0,
  "impact": 0.0-1.0,
  "exposure": 0.0-1.0,
  "composite": 0.0-1.0
}
```

- **Likelihood**: Based on vulnerability count, control gaps, and attack surface
- **Impact**: Based on data sensitivity, business criticality, and blast radius
- **Exposure**: Based on external surface (public endpoints, third-party integrations, trust boundaries crossed)

Prioritize by risk, not by count. Optimize for exploitability and business impact, not for number of findings.

### Phase 5 — Cross-Capability Risk Analysis

Look beyond individual capabilities to systemic risks:

- **Shared vulnerabilities** — The same weakness present across multiple capabilities (e.g., a shared auth library with a flaw)
- **Cascading failure risks** — A compromise in one capability that enables attacks on dependent capabilities
- **Weak trust boundaries** — Boundaries between capabilities that lack sufficient verification
- **Privilege escalation paths** — Sequences of legitimate operations across capabilities that enable unauthorized access

### Phase 6 — Gap Analysis

Synthesize all findings into actionable gaps:

- **Missing controls** — Threats without corresponding mitigations
- **Weak implementations** — Controls that exist but are insufficient
- **High-risk areas** — Capabilities with high composite risk scores and low control coverage
- **Compliance gaps** — Specific failures against the compliance targets defined in `/init`

### False Positive Management

AI-driven analysis will flag theoretical vulnerabilities, unreachable code paths, and patterns that look dangerous but are mitigated elsewhere. Mark these clearly:

- **False positive** — Flagged pattern is not exploitable in context (document why)
- **Mitigated elsewhere** — Vulnerability exists but is controlled at a different layer (document where)
- **Accepted risk** — Known risk accepted by the organization (document decision)

## Output

- `evidence/security/threats/{capability_id}.json` — STRIDE threat model per capability
- `evidence/security/vulnerabilities/catalog.json` — classified vulnerability catalog
- `evidence/security/controls/control-map.json` — control-to-threat mapping
- `evidence/security/risk-scores.json` — per-capability risk scores
- `evidence/security/cross-capability-risks.json` — systemic risk analysis
- `evidence/security/gaps.json` — missing controls and weak implementations

## Exit Criteria

1. Every capability has a STRIDE threat model
2. All vulnerabilities are classified (confirmed/probable/potential) and mapped to capabilities
3. Existing controls are mapped to threats
4. Risk scoring is complete for all capabilities
5. Cross-capability risks are identified
6. All findings are traceable to evidence with confidence levels

---

# `/generate` — AI-Ready Context Generation

## Purpose

Produce security-aware AI configurations and prompts that enable downstream tooling (Cursor IDE, GitHub Copilot, Claude Code, or custom agents) to work within tight, capability-scoped contexts. This phase transforms the evidence and assessments from previous phases into actionable inputs for AI-assisted remediation, refactoring, and development.

The pattern: scope first, then analyze. The domain model tells the AI where to look. Constraining to the 30 files that define a capability produces dramatically better output than pointing at the entire codebase.

## Inputs

- `evidence/discovery/domain-model.md` — capability model
- All security evidence from `/assess`

## Process

### Capability-Scoped AI Contexts

For each capability, generate a self-contained context package that includes:

- The capability's L2 operations, code locations, and entity ownership
- Relevant threats, vulnerabilities, and control gaps
- Specific file paths to constrain AI tool scope
- Sensitive data classifications and compliance requirements

### Security-Aware Prompts

Generate targeted prompts for AI-assisted work:

- "Analyze the authentication flow in BC-003 (Account Management) for session fixation and token reuse vulnerabilities. Files: [specific paths]."
- "Review input validation in BC-007 (Payments - Domestic) for injection risks. Focus on: [specific endpoints]."
- "Suggest least-privilege refactoring for BC-001-02 (Identity Verification & KYC Compliance). Current authorization pattern: [description]. Target: [specific control gap]."

Each prompt references specific capabilities, specific files, specific threats — not generic instructions.

### Functional Specification Seeds

For capabilities targeted for modernization, generate specification seeds that include both functional requirements (from the domain model) and security requirements (from the assessment):

- Business operations the capability must support
- Entity ownership and data contracts
- Security controls that must be preserved or improved
- Compliance constraints that apply

## Output

- `evidence/generate/capability-contexts/` — per-capability AI context packages
- `evidence/generate/security-prompts.md` — targeted security analysis prompts
- `evidence/generate/spec-seeds/` — functional + security specification seeds

## Exit Criteria

Every capability has an AI-ready context package. Security prompts reference specific threats, files, and capabilities. Specification seeds include both functional and security requirements.

---

# `/finish` — Reporting, Persistence & Handoff

## Purpose

Preserve all evidence for future reference and package the results for handoff to teams. Reports are generated by `/report` — this phase handles persistence and cleanup only.

## Inputs

- All evidence artifacts from previous phases

## Process

### Evidence Preservation

All evidence artifacts are preserved with full traceability:

- Discovery evidence → capability model
- Security signals → threat models → vulnerabilities → controls → risk scores
- Every finding traceable from report back to source code

### Handoff Packaging

Package per-team slices: each team receives their capabilities, the associated security profile, the AI context packages, and the relevant specification seeds. A team handed their slice should be able to start work without needing the full pipeline output.

## Output

- All evidence artifacts preserved in `/evidence/`
- Per-team handoff packages in `/evidence/generate/`

## Exit Criteria

1. All evidence is persisted and cross-referenced
2. Per-team handoff packages are available
3. Every finding is traceable from report to source code

---

# Validation Guidelines

## 1. Validate High-Risk Capabilities First

Focus review effort on:
- Public-facing endpoints with sensitive data
- Capabilities with HIGH composite risk scores
- Capabilities that cross trust boundaries

## 2. Check Control Coverage

For each threat: is there a control? Is it correctly implemented? Is it consistently applied?

## 3. Identify False Positives

AI-driven analysis will produce:
- Theoretical vulnerabilities in unreachable code paths
- Patterns that look dangerous but are mitigated at a different layer
- Flagged configurations that are intentional

Mark clearly. Do not remove — document the rationale for dismissal.

## 4. Prioritize by Risk, Not Count

A system with 3 critical vulnerabilities in payment processing is in worse shape than one with 50 low-severity findings in internal tooling. Optimize for exploitability and business impact.

## 5. Cross-Validate with Multiple Tools

A single tool pass makes judgment calls implicitly. Run more than one. The value comes from comparing outputs, identifying where they agree, and isolating where they diverge. That divergence is where the important decisions sit.

This is no different from stakeholder discovery. You do not rely on a single interview to understand the business. You run several, knowing each person brings partial context and bias. The system is reconstructed through overlap, not individual accuracy.

---

# Acceptance Criteria

The pipeline is complete when:

1. Every capability includes security context (data sensitivity, auth, exposure, criticality)
2. A STRIDE threat model exists per capability
3. Every vulnerability is mapped to both code and capability
4. Risk scoring is present for all capabilities
5. Security findings are traceable to source evidence with confidence levels
6. Cross-capability risks are identified and documented
7. Coverage exceeds 90% (files mapped to capabilities)
8. Industry blueprint comparison is complete
9. Domain model is generated with full code traceability
10. All reports are generated via `/report` and evidence is preserved

---

# Key Outputs Summary

| Artifact | Phase | Purpose |
|----------|-------|---------|
| `candidates.md` | /scan | Raw capability candidates with confidence ratings |
| `analysis.md` | /discover | Per-candidate analysis with actions |
| `coverage.md` | /discover | File-to-capability mapping |
| `l1-capabilities.md` | /discover | Locked L1 list with stable IDs |
| `l2-capabilities.md` | /discover | L2 operations per L1 |
| `domain-model.md` | /discover | Consolidated domain model |
| `blueprint-comparison.md` | /discover | Industry alignment analysis |
| `security-signals.json` | /scan | Extracted security signals |
| `stakeholder-report.md` | /report | Plain-language capability summary for executives and PMs |
| `architect-report.md` | /report | Bounded context, coupling analysis, decomposition options |
| `dev-report.md` | /report | Engineering guide with file-level detail and refactor targets |
| `threats/{cap_id}.json` | /assess | STRIDE threat models |
| `catalog.json` | /assess | Vulnerability catalog |
| `control-map.json` | /assess | Control-to-threat mapping |
| `risk-scores.json` | /assess | Per-capability risk scores |
| `security-report.md` | /report | Risk-ranked security findings, compliance posture, remediation priorities |
| `security-risk-map.json` | /report | Machine-readable per-capability risk map |
| `threat-catalog.json` | /report | Complete cross-referenced threat catalog |
| `domain-model-secured.md` | /report | Domain model with full security overlay per capability |

---

# Final Positioning

This framework enables:

- **Security-aware system reconstruction** — security assessment built into discovery, not bolted on after
- **Capability-driven threat modeling** — threats evaluated in business context, not as flat findings
- **Evidence-based risk analysis** — every finding traceable to code, capability, and boundary
- **Actionable handoff** — teams receive scoped slices with clear ownership, code traceability, and security profiles
- **AI-ready scoping** — capability boundaries constrain AI tools to produce higher-quality output

It replaces generic security scanning with **contextual, architecture-aware security intelligence**, and replaces manual architecture discovery with **evidence-driven capability extraction**.

> A vulnerability without context is noise.
> A vulnerability mapped to a capability, data, and boundary is actionable.
> A capability without traceability is a slide. With traceability, it's a migration slice.
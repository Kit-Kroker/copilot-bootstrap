# EDCR Glossary

Full term reference for the EDCR framework. For pipeline phase details, process steps, and acceptance criteria see [brownfield-methodology.md](brownfield-methodology.md).

---

## Pipeline & Framework

**EDCR (Evidence-Driven Capability Reconstruction)**
The overarching framework. A multi-phase pipeline that reconstructs business capabilities from an existing codebase and assesses their security posture — with shared evidence and full code traceability. Replaces both manual architecture discovery and generic security scanning.

**Pipeline**
The ordered sequence of phases that EDCR executes: `/init → /scan → /discover → [/report] → /assess → /generate → /finish`. Each phase reads defined inputs, produces defined outputs, and feeds the next. `/report` is optional and non-blocking — it can be run at any point after `/discover` completes. Designed to be resumable — if context breaks mid-analysis, work resumes from the last completed phase.

**Phase**
A top-level stage of the EDCR pipeline (e.g., `/scan`, `/discover`, `/assess`). Each phase contains multiple steps or sub-steps. Phases produce evidence artifacts that downstream phases consume.

**Step**
A discrete unit of work within a phase (e.g., A1.1 Package Structure Analysis within `/scan`, or D3 Coverage Verification within `/discover`). Each step reads one input, produces one output, and feeds the next step.

**Skill**
The implementation unit in Claude Code. Each step or group of related steps is packaged as a skill with a YAML frontmatter, instructions, input/output definitions, and a workflow state update. Skills are the executable form of the methodology.

**Report Suite**
The set of four audience-specific documents produced by the `/report` phase: stakeholder report, architect report, dev report, and security report (conditional on `/assess` having run). Each report draws from the same discovery and security evidence but frames findings differently for its audience.

**Workflow State**
The tracking mechanism (`workflow.json`) that records which step the pipeline is on, its status, and completion timestamps. Enables resumability and progress tracking across sessions.

---

## Capability Model

**Business Capability**
A distinct business function that the system performs, identified from code evidence. Defined by what the business does — not by how the code is deployed or organized. A capability has coherent scope, clear boundaries, and traceable code.

**L1 Capability (Level 1)**
The system described at a functional level — what exists. L1 capabilities are the top-level business domains (e.g., "Customer Onboarding", "Payments - Domestic", "Account Management"). Each L1 gets a stable ID: `BC-001`, `BC-002`, etc.

**L2 Sub-Capability (Level 2)**
The system described at an operational level — what can be acted on. L2s are executable units of work within an L1 that a team can own, migrate, extend, or replace independently (e.g., "Customer Registration & Account Provisioning", "Identity Verification & KYC Compliance"). Each L2 gets an ID: `BC-{L1}-{NN}` (e.g., BC-001-01).

**Capability Candidate**
A raw, unvalidated potential capability extracted during signal analysis. Candidates are not capabilities until they pass through analysis and receive a CONFIRM action. The pipeline produces 15–25 candidates, which are then refined into the final L1 list.

**Domain Model**
The consolidated, traceable representation of what the system does. Contains the full capability hierarchy (L1 + L2), entity catalog, dependency graph, bounded context candidates, and infrastructure inventory. Each element is backed by code-level evidence. The primary handoff artifact.

**Capability Hierarchy**
The tree structure of L1 capabilities and their L2 sub-capabilities. Represents the system's functional decomposition from a business perspective.

**Capability Map**
A visual or tabular representation of all capabilities. Without traceability, it's useful for slides. With traceability (code locations, entity ownership, dependency counts), it becomes a working tool for migration planning.

**Blueprint Comparison**
The phase D8 activity that maps each code-derived capability against an industry reference framework (BIAN, TM Forum, ACORD, etc.) and classifies it as ALIGNED, ORG-SPECIFIC, or MISSING. The MISSING category is the most actionable — it drives questions about genuine gaps vs. externally-handled capabilities. The code remains the source of truth; the blueprint adds modernisation context.

**Decomposition Option**
A ranked proposal for how the system could be split into independently deployable or ownable units, based on the current coupling topology and bounded context candidates. Produced in the architect report. Multiple options are presented so teams can choose a path that fits their constraints — not a single prescribed migration plan.

**Health Signal**
A three-tier assessment of a capability's structural condition used in stakeholder and dev reports:
- **Strong** — HIGH cohesion and LOW or MEDIUM coupling. Well-defined, easy to own.
- **Needs Attention** — MEDIUM cohesion OR HIGH coupling. Functions correctly but changes are harder.
- **At Risk** — LOW cohesion OR very HIGH coupling across multiple capabilities. Fragile; changes are likely to cause side effects.
Derived from the cohesion/coupling metrics in `analysis.md`.

---

## Signal Extraction

**Signal**
A piece of evidence extracted from the codebase that suggests the existence, shape, or behavior of a capability. Signals come from multiple independent sources (package structure, database schema, entry points, frontend routes) and are cross-referenced for confidence.

**Signal Source**
An independent category of evidence. The pipeline uses four capability signal sources: package structure (S1), database schema (S2), backend entry points (S3), and frontend/UI entry points (S4). Security signals add four more: static patterns (SS1), dependency vulnerabilities (SS2), configuration/infrastructure (SS3), and data sensitivity (SS4).

**Cross-Source Corroboration**
The principle that a signal appearing in multiple independent sources carries higher confidence than one appearing in a single source. A candidate found in package structure AND database schema AND entry points gets HIGH confidence. One found only in package structure gets LOW.

**Confidence Rating**
The reliability assessment assigned to each candidate and security signal. Three levels: HIGH (3+ signal sources corroborate), MEDIUM (2 sources, or strong in 1 with corroboration), LOW (1 source with weak evidence).

**Detection Method**
How a signal was identified. Categories: static pattern match (code scanning), AST analysis (syntax tree inspection), inference (reasoning from surrounding code), external database lookup (CVE databases), pre-generated input (from external tools like nDepend or Structure101).

**Pre-Generated Input**
Externally produced analysis files provided by the user — package exports from nDepend, database schemas from a DBA, entry point lists from IDE analyzers, architecture notes. These anchor confidence upward and reduce guesswork but do not replace pipeline analysis.

**Strong Signal**
A domain-suggestive name or pattern that clearly indicates a business capability: `payments`, `customers`, `orders`, `lending`. Exists because developers named things deliberately.

**Ambiguous Signal**
A name or pattern that could indicate a capability or could be infrastructure: `processing`, `management`, `utils`, `core`. Requires corroboration from other sources to classify.

---

## Candidate Analysis

**Cohesion**
Whether a candidate has a single, coherent business responsibility. HIGH: all code serves one business purpose. MEDIUM: mostly coherent with some tangential functionality. LOW: mixed concerns, multiple unrelated operations.

**Coupling**
How many other candidates a candidate depends on. LOW (good): 0–1 dependencies. MEDIUM: 2–3 dependencies. HIGH (concerning): 4+ dependencies.

**Boundary Clarity**
Whether a candidate has clean interfaces. CLEAR: well-defined API, minimal internal exposure. PARTIAL: some clean boundaries, some shared state. UNCLEAR: deeply entangled, no clear separation.

**Action**
The decision applied to each candidate during analysis. Every candidate must receive exactly one action:

- **CONFIRM** — Valid L1 business capability. Passes cohesion, coupling, and boundary checks.
- **SPLIT** — Contains multiple distinct capabilities. Defines what to split into.
- **MERGE** — Sub-feature of another capability, not independent. Specifies the merge target and rationale.
- **DE-SCOPE** — Not a business capability. Classified as infrastructure, cross-cutting concern, delivery channel, or test harness.
- **FLAG** — Cannot determine from code alone. Requires architect or domain expert input. States the specific question.

**Delivery Channel**
A technical surface through which capabilities are accessed (mobile app, web portal, API gateway). Not a capability itself. Common misclassification trap — a "Mobile Banking" package at 43% of codebase is a delivery channel, not a capability.

**Cross-Cutting Concern**
Functionality that serves multiple capabilities horizontally: authentication middleware, logging, error handling, notifications. Not a capability — documented as infrastructure in the domain model.

**Parameter Variation**
Two candidates that share the same core entities and operations but differ by a configuration parameter (frequency, channel, product type). Example: "Payments - Scheduling" is a parameter variation of "Payments - Domestic" (adds frequency). Merged, not separate capabilities.

**Business Lens**
The principle of defining capabilities by business meaning, not by technical or deployment structure. When deployment boundaries and business boundaries disagree, trust the business lens. A microservice boundary is not a capability boundary.

---

## Coverage & Ownership

**Coverage**
The percentage of significant business source files (and LOC) mapped to discovered capabilities. Target: >90%. Calculated after candidate analysis and before L1 locking.

**Significant Source File**
A file that contains business logic, configuration defining business behavior, or database schema. Excludes: tests, build scripts, IDE configuration, documentation, static assets, generated code, dependency lock files.

**Orphan File**
A significant source file not mapped to any capability after initial coverage analysis. Resolved by: assigning to an existing capability, creating a new capability, marking as infrastructure, or marking as dead code.

**Orphan Zone**
A cluster of orphan files concentrated in a single directory or module. Orphan zones are tech debt indicators and ownership ambiguity signals. A large orphan zone adjacent to a high-coupling capability is an architectural risk — it may contain hidden coupling, dead code from a prior migration, or shared logic with no clear owner. Surfaced in the architect and dev reports.

**Dead Code**
Source files with no references from other files, no recent modifications, or residing in deprecated packages. Marked for removal or investigation. When in doubt, classify as "Investigate" rather than "Dead code."

**Entity Ownership**
The relationship between a capability and the data entities it interacts with. Five levels:

- **OWNS** — Source of truth, single writer. This capability creates, updates, and deletes the entity. No other capability writes to it.
- **CREATES** — Creates new instances, but another capability owns the entity going forward.
- **MANAGES** — Full CRUD via an external API. No local database table.
- **TRACKS** — Reads and monitors state changes owned elsewhere. May cache or project data.
- **READS** — Pure read-only consumption. No caching, no projection, no state tracking.

**Ownership Conflict**
When two capabilities both write to the same entity. Indicates a boundary problem — the entity should be split, one capability should use an API instead of direct write, or the two capabilities are actually one.

**Bounded Context**
A proposed grouping of capabilities that share high internal cohesion and low external coupling. Candidates for deployment boundaries or team boundaries. Proposed based on shared entities, coupling scores, and data ownership patterns.

---

## Security Assessment

**Security Context**
The security profile attached to each capability: data sensitivity classifications, auth mechanisms, external exposure level, criticality rating, sensitive operations, and trust boundaries crossed.

**Security Signal**
Evidence extracted from the codebase that relates to security posture. Four categories: static security patterns (SS1), dependency vulnerabilities (SS2), configuration/infrastructure exposure (SS3), and data sensitivity (SS4).

**Trust Boundary**
A point where data or control flow crosses between different trust levels — between capabilities, between internal and external systems, between privilege levels. Where capabilities interact with external services, change privilege levels, or cross network boundaries.

**Criticality**
The business importance of a capability from a security perspective. Derived from data sensitivity, external exposure, and business impact. Three levels: LOW, MEDIUM, HIGH.

**STRIDE**
The threat modeling framework used per capability. Six threat categories:

- **Spoofing** — Impersonation of a legitimate user or system.
- **Tampering** — Unauthorized modification of data in transit or at rest.
- **Repudiation** — Ability to deny having performed an action.
- **Information Disclosure** — Unauthorized exposure of sensitive data.
- **Denial of Service** — Overwhelming a capability to prevent legitimate use.
- **Elevation of Privilege** — Gaining unauthorized access or permissions.

**Threat Model**
The per-capability STRIDE analysis that identifies threats, assigns severity, assesses likelihood, maps existing controls, and notes missing controls. One threat model per L1 capability, stored as `threats/{capability_id}.json`.

**Vulnerability**
A specific weakness in code, configuration, or dependencies that could be exploited. Classified by confidence:

- **Confirmed** — Directly observable in code with a clear exploit path.
- **Probable** — Pattern strongly suggests vulnerability but requires runtime verification.
- **Potential** — Theoretical, based on architecture or configuration patterns.

**Control**
A security mechanism that mitigates a threat or vulnerability. Categories: authentication, authorization, input validation, encryption, monitoring, rate limiting. Assessed for: presence, correct implementation, and consistent application across L2 operations.

**Control Gap**
A threat or vulnerability without a corresponding control, or with a control that is present but insufficient.

**Risk Score**
A per-capability numerical assessment across three dimensions:

- **Likelihood** (0.0–1.0) — Based on vulnerability count, control gaps, and attack surface.
- **Impact** (0.0–1.0) — Based on data sensitivity, business criticality, and blast radius.
- **Exposure** (0.0–1.0) — Based on external surface (public endpoints, third-party integrations, trust boundaries crossed).
- **Composite** (0.0–1.0) — Weighted combination: `(likelihood × 0.3) + (impact × 0.4) + (exposure × 0.3)`.

**Cross-Capability Risk**
A systemic risk that spans multiple capabilities: shared vulnerabilities (same flaw in a shared library), cascading failure risks (compromise in one enabling attack on dependents), weak trust boundaries, and privilege escalation paths.

**False Positive**
A flagged pattern that is not exploitable in context. Documented with rationale rather than silently removed. Three subtypes: not exploitable (code path unreachable), mitigated elsewhere (controlled at a different layer), accepted risk (known and accepted by the organization).

**Data Sensitivity Classification**
The categorization of entities and fields by the type of sensitive data they contain: PII (personally identifiable information), financial data, authentication data, health data, regulatory data (subject to GDPR, PCI-DSS, HIPAA, etc.).

---

## QA & Test Readiness

**QA Context**
The QA profile attached to each capability: test coverage (unit / integration / e2e) with source and confidence, automation status per test type, testability rating, defect profile, environment coverage, and flagged test-strategy gaps. Mirrors `security_context` in shape so the two overlays render side-by-side in reports.

**QA Signal**
Evidence extracted from the codebase, coverage reports, CI configs, and (when registered) defect-tracker and CI-history exports, relating to QA posture. Four categories: test inventory (QS1), coverage signals (QS2), testability signals (QS3), environment & CI signals (QS4).

**Test Inventory**
The enumerated, classified list of all tests in the codebase. Classified by level (unit, integration, contract, e2e, performance, manual) and mapped to target production code. Produced in QS1, consumed by D6a and the SDET report.

**Test Pyramid**
The target distribution of tests across levels, declared in `qa_scope.test_pyramid`. Standard pyramid weights unit > integration > e2e; trophy flips integration above unit; inverted puts e2e at the top (anti-pattern, but named so the report can call it out).

**Coverage Signal**
Per-file or per-package code coverage, sourced from a report (JaCoCo, Cobertura, Istanbul, coverlet) at HIGH confidence or computed as a proxy (tested-file presence) at LOW confidence. A capability's coverage is aggregated from these signals; missing data is represented as `"not-collected"`, not zero.

**Proxy Coverage**
A coverage estimate computed from test-file presence when no real coverage report is registered. Always flagged LOW confidence and labeled "proxy" in outputs so it cannot be mistaken for measured coverage.

**Testability**
The degree to which a capability's code can be tested in isolation and at low cost. Rated `good` / `impeded` / `blocked` based on QS3 findings inside the capability's files. Findings include hidden dependencies, direct instantiation of infrastructure, global state, missing seams, untestable constructs, and test hostility (ignored tests, swallowed assertions).

**Testability Finding**
A specific code pattern that makes testing harder, recorded with file:line, pattern category, and severity: `blocks` (tests impossible without refactor), `impedes` (tests costly or brittle), `smell` (localized concern).

**Automation Status**
Per-capability classification of which test types are automated: `full` / `partial` / `manual` / `none` / `not-applicable`. Scored separately for regression, smoke, contract, and performance tests.

**Defect Profile**
Per-capability defect and flakiness summary: open defects attributed to the capability (from defect tracker export), flaky-test rate over the capability's test files, and change velocity (commits/month) over the last 6 months. High velocity amplifies the risk impact of coverage gaps and testability issues.

**Change Velocity**
Normalized rate of commits to a capability's files over a rolling window. Untested code that rarely changes is tolerable; untested code being rewritten weekly is a release risk. Used as an amplifier in QA risk scoring.

**Coverage Gap**
The distance between a capability's measured coverage and the target defined in `qa_scope.coverage_targets`. Weighted by target depth — unit gaps count less than integration/e2e gaps for capabilities with high external exposure.

**Environment Parity**
The degree to which configuration is consistent across declared environments (dev, staging, pre-prod, prod). Divergent keys between prod and lower environments are parity issues. Surfaced per capability and aggregated in the SDET report.

**CI Quality Gate**
A test stage that is required on the default branch before merge: mandatory unit tests, integration tests, coverage thresholds, security scans. Recorded from CI config parsing in QS4.

**QA Risk Score**
Per-capability score with four dimensions: coverage_gap, testability, defect_density, change_velocity. Each is 0.0–1.0 or `null` when signals are not collected. Composite: `(coverage_gap × 0.35) + (testability × 0.30) + (defect_density × 0.20) + (change_velocity × 0.15)`. If any dimension is `null`, the composite is `"unknown"` — never silently substituted.

**QA Posture**
Classification derived from QA risk score and context: `release-ready` / `needs work` / `high-risk` / `unknown`. `unknown` is a first-class value indicating insufficient signals, not a failure to classify.

**Unified Composite Risk**
The per-capability combined security + QA risk score: `(security_composite × 0.55) + (qa_composite × 0.45)` when both are numeric. Weights are overridable in `context.json` under `risk_scope.weights`. When QA dimensions are `"not-collected"`, the unified composite is reported as `"partial"` with the security score and the drivers list states `"QA signals not collected"`.

**Driver**
A short phrase listed alongside each unified composite risk score that explains the top 1–3 reasons for the score (e.g., "public exposure + no integration tests", "high change velocity + blocked testability"). Drivers are what turn a number into an action item.

**Not-Collected**
A first-class value for QA signals that were unavailable (no coverage report, no defect tracker, no CI config). Flows through to the SDET report as an explicit gap rather than being omitted or replaced with a default. The Not-Collected Summary section of the SDET report enumerates all such gaps.

**SDET Report**
The audience-specific report generated by `/report` for SDETs, QA engineers, QA leads, test architects, and release managers. Always emitted after `/discover`. Covers test strategy snapshot, per-capability coverage map, automation matrix, testability hotspots, defect and flakiness profile, environment readiness, CI quality gates, QA risk ranking, unified risk view, per-capability test strategy recommendations, sprint-ready QA backlog, and a Not-Collected Summary.

---

## Industry Comparison

**Industry Blueprint**
A reference framework of expected capabilities for a given industry. Used to add context to the code-derived model — not to validate it.

**BIAN (Banking Industry Architecture Network)**
Industry capability reference for banking, finance, and payments.

**TM Forum (Frameworx)**
Industry capability reference for telecom and communications.

**ACORD**
Industry capability reference for insurance.

**HL7 / FHIR**
Industry capability reference for healthcare.

**ARTS (Association for Retail Technology Standards)**
Industry capability reference for retail and e-commerce.

**APQC (Process Classification Framework)**
Cross-industry process reference. Used as default when no domain-specific framework applies.

**Alignment Classification**
How each capability relates to the industry reference:

- **ALIGNED** — Code capability maps to an expected industry capability (full or partial match).
- **ORG-SPECIFIC** — Code capability exists but has no industry equivalent. May be a competitive differentiator or custom business logic.
- **MISSING** — Expected industry capability has no code-level presence. The most useful category — drives targeted questions about whether the capability is handled externally, is a genuine gap, or is out of scope.

**Modernization Posture**
The strategic positioning of each capability based on alignment and code quality:

- **Retain** — Well-aligned with industry, clean code structure. Keep as-is.
- **Extend** — Good foundation, missing some scope. Add missing operations.
- **Refactor** — Misaligned boundaries or poor code quality. Restructure.
- **Replace** — Poor alignment and poor quality. Consider rebuild.
- **Evaluate** — Org-specific capability needing a business decision on its future.

---

## Reports

**Stakeholder Report**
An audience-specific report generated by `/report` for executives, product managers, business analysts, and engineering managers. Plain language throughout — no technical terms, no file paths, no code. Covers business capabilities with health signals, industry alignment summary, modernisation posture per capability, and proposed team ownership areas. Every section includes an inline source citation linking to the discovery artifact it draws from.

**Architect Report**
An audience-specific report generated by `/report` for solutions architects and enterprise architects. Uses DDD terminology, capability IDs, and actual metric values. Covers capability topology (cohesion/coupling/LOC), bounded context analysis, cross-context dependency table, decomposition options ranked by feasibility, orphan zone risk assessment, a QA risk overlay per capability, and — if `/assess` has run — a security risk overlay and unified risk map per capability.

**Dev Report**
An audience-specific report generated by `/report` for developers, tech leads, and engineering managers. Uses exact file paths, capability IDs, and line counts. Covers capability-to-code mapping, ownership assignments from bounded contexts, health dashboard for sprint planning, refactor targets with specific techniques and scope estimates, orphan hotspots with recommended actions, QA findings (testability blockers with file:line pointers, coverage gaps on highest-churn files, flaky tests to stabilise or retire), and — if `/assess` has run — confirmed vulnerabilities and critical control gaps with sprint-ready ticket items.

**Security Report**
An audience-specific report generated by `/report` for the security team and tech leads. Conditionally generated — only if `/assess` has completed. Covers risk-ranked CRITICAL/HIGH findings with file:line references, mitigation priorities (Immediate / Short-term / Medium-term), compliance posture per target standard, systemic cross-capability risks, and the capability risk map. Also produces `security-risk-map.json`, `threat-catalog.json`, and `domain-model-secured.md`.

**Inline Source Citation**
The convention used in all four reports to make every conclusion traceable to its source artifact. Each section header is followed by a `*Source: [filename](relative-path)*` line (or `*Sources: ...*` for multiple). Links are relative from the report's location so they work in any markdown viewer without absolute paths. Example: a stakeholder report section on industry alignment carries `*Source: [blueprint-comparison.md](blueprint-comparison.md)*`.

---

## Migration & Handoff

**Migration Slice**
A self-contained unit of work for a team, defined by a capability's code footprint, entity ownership, dependencies, and security profile. The domain model provides the data needed to define migration slices without additional discovery.

**Migration Complexity**
The estimated difficulty of extracting and migrating a capability. Derived from coupling score, L2 count, and external dependency count. Three levels: SIMPLE, MODERATE, COMPLEX.

**Coupling Score**
The degree of entanglement between a capability and other capabilities. Determined from shared files, cross-capability entity access, and dependency direction. LOW / MEDIUM / HIGH.

**Capability Context Package**
An AI-ready bundle generated per capability during `/generate`. Contains: capability description, L2 operations, code file paths, entity ownership, relevant threats, vulnerabilities, control gaps, and compliance requirements. Used to scope AI tools (Cursor, Copilot, Claude Code) to a tight set of files for higher-quality output.

**Specification Seed**
A starting point for a functional specification, generated per capability during `/generate`. Combines business operations (from the domain model) with security requirements (from the assessment). Used for capabilities targeted for modernization.

**Handoff Package**
The per-team deliverable from `/finish`. Contains the team's capability slice, security profile, AI context packages, and specification seeds. A team receiving their package should be able to start work without needing the full pipeline output.

---

## Evidence & Traceability

**Evidence**
Any artifact — file, signal, finding, assessment — produced by the pipeline and stored in the evidence directory. All evidence is preserved and cross-referenced so that any claim in a report can be traced back to source code.

**Evidence Trail**
The chain of references from a high-level finding back to its source: report → risk score → vulnerability → security signal → code location. Also applies to capability claims: domain model → L2 → L1 → candidate → signal → code location.

**Traceability**
The property of every pipeline output being connected to its source evidence. A capability without traceability is a slide. A capability with traceability — code locations, entity ownership, endpoint counts, dependency references — is a migration slice.

**Pre-Generated Input Check**
The convention where every skill checks whether its output file already exists before starting analysis. If it exists, the skill reports it was found and skips to the next step. Enables users to provide their own analysis from external tools and enables resumability.

---

## Abbreviations

| Abbreviation | Expansion |
|-------------|-----------|
| EDCR | Evidence-Driven Capability Reconstruction |
| L1 | Level 1 (functional capability) |
| L2 | Level 2 (operational sub-capability) |
| BC | Business Capability (prefix for capability IDs) |
| LOC | Lines of Code |
| STRIDE | Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege |
| PII | Personally Identifiable Information |
| CVE | Common Vulnerabilities and Exposures |
| OWASP | Open Worldwide Application Security Project |
| ASVS | Application Security Verification Standard |
| NIST | National Institute of Standards and Technology |
| GDPR | General Data Protection Regulation |
| PCI-DSS | Payment Card Industry Data Security Standard |
| HIPAA | Health Insurance Portability and Accountability Act |
| BIAN | Banking Industry Architecture Network |
| APQC | American Productivity & Quality Center |
| ACORD | Association for Cooperative Operations Research and Development |
| ARTS | Association for Retail Technology Standards |
| RBAC | Role-Based Access Control |
| ABAC | Attribute-Based Access Control |
| JWT | JSON Web Token |
| KYC | Know Your Customer |
| TLS | Transport Layer Security |
| CORS | Cross-Origin Resource Sharing |
| WAF | Web Application Firewall |
| ORM | Object-Relational Mapping |
| DBA | Database Administrator |
| CRUD | Create, Read, Update, Delete |
| QA | Quality Assurance |
| SDET | Software Development Engineer in Test |
| E2E | End-to-End (test level) |
| CI | Continuous Integration |
| SUT | System Under Test |
| DI | Dependency Injection |
| DoD | Definition of Done |
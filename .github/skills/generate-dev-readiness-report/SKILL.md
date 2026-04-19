---
name: generate-dev-readiness-report
description: Generate the developer readiness report — dependency health, environment setup guide, architecture fitness, code health dashboard, integration risk, implementation blockers, and estimation anchors. Always emits an honest account when dev signals are absent. Runs in /report after /assess dev lane completes.
argument-hint: "[leave blank to generate full report]"
---

# Skill Instructions

**Pre-generated input check:** If `docs/dev/dev-readiness-report.md` already exists, report that it was found and skip to the next step.

The dev readiness report is ALWAYS emitted when invoked. If dev signals have not been scanned, still generate the report — all fields will be explicitly marked `not-collected` and the "Not-Collected Summary" section will guide the team on what to run next.

Read (all optional except capabilities; emit not-collected markers when absent):
- `docs/dev/dev-signals.json` ← if present
- `docs/dev/capability-dev-contexts.json` ← if present
- `docs/dev/dev-readiness-scores.json` ← if present
- `docs/dev/dev-blockers.json` ← if present
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← if present
- `docs/discovery/domain-model.md` ← required
- `.project/state/answers.json` (for project name, stack)
- `.discovery/context.json` ← for stack/framework metadata

If `docs/dev/dev-signals.json` is absent entirely, note at top of report: "Dev signal scan has not been run. This report is a capability scaffold with every field marked not-collected. Run `/assess` (or the `scan-dev-signals` step) to populate." Still emit the full capability scaffold.

## Report Generation

Write for engineering leads and developers entering an implementation sprint. Be concrete: use file paths, dep names, env var names, and metric values. Every finding should translate directly into a ticket or a setup action.

Every section that draws from a specific artifact must include a source line immediately below the section heading in the form `*Source: [filename](relative-path-from-docs/dev/)*`. The report lives in `docs/dev/`. Links to discovery artifacts use `../discovery/filename`; links to QA or security use `../qa/` or `../security/`. Multiple sources are separated with ` · `.

When a value is `"not-collected"`, render it literally as `not-collected` in the report — this is a first-class honesty mechanism, not a placeholder.

## Output

Write to: `docs/dev/dev-readiness-report.md`

```markdown
# {Project Name} — Developer Readiness Report

**Date**: {today}
**System**: {project name from answers.json}
**Stack**: {language/framework/persistence from context.json or "not-collected"}
**Audience**: Engineering leads, developers, tech leads

---

## Summary

{3–5 sentences:
- Overall readiness status: X BLOCKED, Y NEEDS_ATTENTION, Z READY capabilities (or "not-collected" if dev signals absent)
- Most critical blocker, if any — name it specifically
- Top structural risk (biggest code health or integration finding)
- Top recommendation for sprint zero
- If many not-collected signals: note that implementation planning confidence is limited until those are collected}

---

## Readiness Dashboard

*Source: [dev-readiness-scores.json](dev-readiness-scores.json) · [capability-dev-contexts.json](capability-dev-contexts.json)*

| Capability | Status | Dep Health | Env Complexity | Code Health | Integration Risk | Score |
|-----------|--------|-----------|----------------|-------------|-----------------|-------|
| BC-{NNN}: {name} | READY / NEEDS_ATTENTION / BLOCKED | healthy / at_risk / not-collected | low / medium / high / not-collected | healthy / needs_attention / at_risk / not-collected | 0 services / N without mock | {0.00 or not-collected} |

{Sort by Status descending (BLOCKED first), then by Score descending within each status group.}

**Status legend**: READY (<0.40 composite) · NEEDS_ATTENTION (0.40–0.69) · BLOCKED (≥0.70 or explicit blocker)

---

## Blockers & Prerequisites

*Source: [dev-blockers.json](dev-blockers.json)*

Must be resolved before implementation can start safely. Ordered by severity.

{If no blockers at all: "No blockers detected. All capabilities are implementation-ready subject to the findings below."}

### CRITICAL

{If any CRITICAL blockers:}

| ID | Scope | Issue | Resolution |
|----|-------|-------|-----------|
| DEV-BLK-{NNN} | BC-{NNN} / global | {description — name the specific file, dep, or var} | {resolution} |

### HIGH

{If any HIGH blockers:}

| ID | Scope | Issue | Resolution |
|----|-------|-------|-----------|
| DEV-BLK-{NNN} | BC-{NNN} / global | {description} | {resolution} |

### MEDIUM

{If any MEDIUM blockers:}

| ID | Scope | Issue | Resolution |
|----|-------|-------|-----------|
| DEV-BLK-{NNN} | BC-{NNN} / global | {description} | {resolution} |

---

## Dependency Health

*Source: [dev-signals.json](dev-signals.json) · [capability-dev-contexts.json](capability-dev-contexts.json)*

### Manifest Overview

| Manifest | Type | Runtime Deps | Dev Deps | Lockfile | Pinning | Wildcards | Deprecated |
|---------|------|-------------|---------|---------|---------|----------|-----------|
| {file} | npm / maven / pip / ... | N | N | yes / no | strict / loose / none | N | N |

**Totals**: {runtime_deps} runtime + {dev_deps} dev dependencies across {manifest_count} manifest(s).
{If no lockfile: "⚠ No lockfile detected — dependency resolution is non-deterministic."}

### Dependency Risks by Capability

{For each capability with `dependency_health = "at_risk"`:}

| Capability | Wildcard Deps | Deprecated Markers | Recommended Action |
|-----------|--------------|-------------------|-------------------|
| BC-{NNN}: {name} | {dep-a, dep-b or none} | {dep-c or none} | {e.g., Pin {dep-a} to a specific version. Replace {dep-c} before sprint 1.} |

{If no at-risk capabilities: "All capabilities have healthy dependency posture — no wildcard versions or deprecated markers detected."}

### License Summary

{If copyleft_risk_count > 0: "⚠ {N} dependencies could not be confirmed as permissive. Review before distributing. Copyleft-risk candidates: {dep names}."}
{If copyleft_risk_count = 0: "No copyleft-risk dependencies detected."}
{Note: license classification is best-effort from dep names — legal review is required for compliance.}

---

## Environment Setup Guide

*Source: [dev-signals.json](dev-signals.json) · [capability-dev-contexts.json](capability-dev-contexts.json)*

### Required Environment Variables

{If env_vars detected:}

| Variable | Purpose | Required | Default | Category |
|---------|---------|---------|---------|---------|
| {VAR_NAME} | {purpose or "not documented"} | yes / no | {value or "⚠ none"} | {category} |

{Mark required-without-default rows with ⚠ in the Default column.}
{If required_vars_without_default > 0: "⚠ {N} required variable(s) have no default value. These must be configured before the application starts."}

{If no env_vars detected: "No environment variable catalog found. Add a `.env.example` or `.env.template` file to document required configuration."}

### External Services

| Service | Type | Required For | Mock Available | Local Setup |
|--------|------|-------------|----------------|-------------|
| {name} | {type} | {scope} | yes / no / not-collected | {hint or "not-collected"} |

{If any services without mocks: "⚠ {N} service(s) lack local mocks. Integration tests will require live instances unless test doubles are added."}

### Secrets Management

**Approach**: {approach}

{If hardcoded_secret_warnings > 0:}
**⚠ CRITICAL: Hardcoded credentials detected in {N} source file(s):**
| File | Line | Pattern |
|------|------|---------|
| {file} | {line} | {pattern} |
*These must be extracted to environment variables or a secrets manager before any further work.*

### Local Development Setup

**Complexity**: {simple / moderate / complex / not-collected} ({setup_step_count} steps{, or "not-collected"})

{If setup_documented: "Setup guide found in README."}
{If docker_compose_available: "Docker Compose available for local service orchestration."}
{If not setup_documented AND external_services_count > 1: "⚠ No local setup guide found. This is a HIGH blocker — document the setup steps in README before onboarding developers."}

---

## Architecture Fitness

*Source: [dev-signals.json](dev-signals.json) · [capability-dev-contexts.json](capability-dev-contexts.json)*

**Detected pattern**: {pattern or "not-detected"} ({confidence} confidence)

### Layer Violations

{If layer_violations present:}

| ID | Severity | Pattern | File:Line | Capability | Suggested Fix |
|----|---------|---------|----------|-----------|--------------|
| DS2-VIO-{NNN} | HIGH / MEDIUM / LOW | {type} | {file}:{line} | BC-{NNN} | {hint} |

*(Show all HIGH and MEDIUM violations. For the full list including LOW, see [dev-signals.json](dev-signals.json).)*

{If no violations: "No layer violations detected. Architecture boundaries appear well-maintained."}

### Module Structure

- **Top-level modules**: {total_top_level_dirs}
- **Maximum nesting depth**: {max_nesting_depth}
- **Shared kernel**: {present / absent}
- **Circular dependency risk**: {possible / not-detected / not-collected}

{If circular_dependency_indicators = "possible": "⚠ Possible circular dependencies detected. Run a dependency analysis tool to confirm before adding new cross-module imports."}

---

## Code Health Dashboard

*Source: [dev-signals.json](dev-signals.json) · [capability-dev-contexts.json](capability-dev-contexts.json)*

### Complexity Hotspots

{If complexity_hotspots present:}

| File | LOC (est.) | Complexity | Capability | Risk |
|------|-----------|-----------|-----------|------|
| {path} | {N or not-collected} | HIGH / MEDIUM | BC-{NNN} / not-collected | HIGH: refactor before adding features |

*(Include all HIGH. For MEDIUM hotspots see dev-signals.json.)*

{If no hotspots: "No high-complexity files detected above the 500-LOC threshold."}

### Technical Debt by Area

| Area | TODOs | FIXMEs | HACKs | Debt Density |
|------|-------|-------|------|-------------|
| {directory} | N | N | N | {x.x/KLOC or not-collected} |

**Total debt markers**: {todo_total} TODOs · {fixme_total} FIXMEs · {hack_total} HACKs

{If any area has debt_density > 3.0: "⚠ High debt density in {area} — {N}/KLOC. Address before sprint 1 to avoid compounding slowdown."}

### Coupling Hotspots

{Top 5 files with HIGH coupling (>15 imports):}

| File | Import Count | Capability |
|------|-------------|-----------|
| {path} | N | BC-{NNN} / not-collected |

{If no high-coupling files: "No high-coupling files detected above the 15-import threshold."}

### Documentation Coverage

**Estimated doc coverage**: {N}% ({confidence} confidence) or `not-collected`

{If doc_coverage_estimate < 30: "⚠ Low documentation coverage ({N}%). Consider adding JSDoc/docstrings to public APIs before onboarding developers."}

---

## Integration Risk Assessment

*Source: [dev-signals.json](dev-signals.json) · [capability-dev-contexts.json](capability-dev-contexts.json)*

| Service | Type | Required For | Mock | Capability | Risk |
|--------|------|-------------|------|-----------|------|
| {service} | {type} | {scope} | yes / no / not-collected | BC-{NNN} / multiple | LOW / MEDIUM / HIGH |

**Risk classification**:
- LOW: mock available
- MEDIUM: no mock but service is stateless/replaceable
- HIGH: no mock and service is database or message broker

{If services_without_mocks > 0:}
**{N} service(s) require live instances for integration tests.** Adding test doubles before implementation starts will reduce test flakiness and unblock local development.

---

## Estimation Anchors

*Source: [dev-readiness-scores.json](dev-readiness-scores.json) · [capability-dev-contexts.json](capability-dev-contexts.json)*

Use these signals to calibrate effort estimates. These are static heuristics — validate with team knowledge.

| Capability | Complexity Hotspots | Tech Debt | Env Setup | Integration Points | Blockers | Effort |
|-----------|--------------------|-----------|-----------|--------------------|---------|--------|
| BC-{NNN}: {name} | {N} HIGH files | {density/KLOC or low} | simple / moderate / complex | {N} services | {N} blockers | LOW / MEDIUM / HIGH |

**Effort scale**:
- **LOW** (<1 sprint): clean code, simple env setup, no blockers
- **MEDIUM** (1–2 sprints): some complexity or environment work required, no CRITICAL blockers
- **HIGH** (3+ sprints): significant code health issues, complex setup, external blockers, or CRITICAL/HIGH blockers

{Derive Effort from: readiness_status (BLOCKED → HIGH), complexity_hotspots_in_capability, env complexity, blocker count.}

---

## Sprint Zero Recommendations

{5–7 concrete actions, ordered by priority. Each must be ticket-ready — specific enough to create a JIRA/Linear/GitHub issue from.}

1. **[CRITICAL]** {action resolving CRITICAL blocker, if any} — Scope: {estimate} — Rationale: {one sentence}
2. **[SETUP]** {action for highest-priority env/setup gap} — Scope: {estimate} — Rationale: {one sentence}
3. **[ARCH]** {action for highest-priority architecture violation or coupling issue} — Capability: BC-{NNN} — Scope: {estimate}
4. **[DEPS]** {action for wildcard or deprecated dependency} — Capability: BC-{NNN} — Scope: LOW
5. **[MOCKS]** {action to add test double for highest-risk service without mock} — Capability: BC-{NNN} — Scope: {estimate}
6. **[DEBT]** {action to address highest-density tech debt area} — Area: {directory} — Scope: {estimate}
7. **[DOCS]** {action to document env vars, setup steps, or API contracts if gaps exist} — Scope: LOW

{If no blockers or risk items: replace with 3–4 low-effort hygiene recommendations.}

---

## Not-Collected Summary

{If any fields were recorded as not-collected:}

The following signals could not be determined from static analysis. Collecting them will improve readiness scoring accuracy.

| Signal | Why Not Collected | How to Collect |
|-------|-----------------|---------------|
| {signal description} | {reason — e.g., "no .env.example file present"} | {specific action — e.g., "add .env.example with all required vars"} |

{Derive from `dev-signals.json → summary.not_collected_fields`. Map each field path to a human-readable signal description and collection action.}

{If no not-collected fields: "All dev signals were collected successfully."}

---

## Dev Artifacts

| Artifact | Use For |
|---------|---------|
| [dev-signals.json](dev-signals.json) | Raw dev signals — dependency inventory, architecture, env config, code health |
| [capability-dev-contexts.json](capability-dev-contexts.json) | Per-capability dev context |
| [dev-readiness-scores.json](dev-readiness-scores.json) | Readiness scores and risk ranking |
| [dev-blockers.json](dev-blockers.json) | Blockers requiring resolution before implementation |
| [../discovery/dev-report.md](../discovery/dev-report.md) | Engineering discovery report — capability map, ownership, refactor targets |
| [../qa/sdet-report.md](../qa/sdet-report.md) | QA posture and test strategy |
| [../security/security-report.md](../security/security-report.md) | Security risk assessment *(if available)* |
```

After writing the file:
- Tell the user: "Dev readiness report generated at docs/dev/dev-readiness-report.md. {blocked} capabilities BLOCKED, {needs_attention} NEEDS_ATTENTION, {ready} READY. {blocker_count} blockers ({critical} CRITICAL, {high} HIGH) require resolution before implementation starts."

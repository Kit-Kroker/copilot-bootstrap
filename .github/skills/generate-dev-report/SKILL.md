---
name: generate-dev-report
description: Generate an engineering-team discovery report from brownfield discovery outputs. Provides capability-to-code mapping, file coverage, orphan code hotspots, refactor targets, and ownership boundaries in a format directly useful for development teams.
argument-hint: "[leave blank to generate full report]"
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/dev-report.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required (if present)
- `docs/discovery/domain-model.md` ← required
- `docs/discovery/analysis.md` ← required
- `docs/discovery/coverage.md` ← required
- `.discovery/context.json` ← required (for file paths and metrics)
- `.project/state/answers.json` (for project name, tech stack)
- `docs/security/vulnerabilities/catalog.json` (if present — surface confirmed/probable findings)
- `docs/security/gaps.json` (if present — surface critical control gaps)
- `docs/qa/qa-signals.json` (if present — surface testability findings)
- `docs/qa/capability-qa-contexts.json` (if present)
- `docs/qa/qa-gaps.json` (if present — surface QA gaps needing code changes)
- `docs/dev/dev-readiness-scores.json` (if present — surface implementation blockers and readiness status)
- `docs/dev/dev-blockers.json` (if present — surface CRITICAL and HIGH blockers)

## Report Generation

Write for the engineering team — developers, tech leads, and engineering managers. Be concrete: use file paths, capability IDs, metric values, and line counts. No abstraction. Every finding should be actionable by a developer today.

Every section that draws from a specific discovery artifact must include a source line immediately below the section heading, in the form `*Source: [filename](relative-path-from-docs/discovery/)*`. The report lives in `docs/discovery/` so links to other files in that folder are just the filename; links to security artifacts use `../security/filename`. Multiple sources are separated with ` · `.

## Output

Write to: `docs/discovery/dev-report.md`

```markdown
# {Project Name} — Engineering Discovery Report

**Date**: {today}
**System**: {project name from answers.json}
**Stack**: {language/framework/persistence from context.json}
**Audience**: Developers, tech leads, engineering managers

---

## Summary

{3–4 sentences:
- Total capabilities discovered, LOC analysed, coverage percentage
- Biggest structural finding (top coupling hotspot, largest orphan zone, or most fragmented capability)
- Top recommendation for the first sprint of improvement work}

---

## Capability Map
*Sources: [l1-capabilities.md](l1-capabilities.md) · [l2-capabilities.md](l2-capabilities.md) · [analysis.md](analysis.md) · [domain-model.md](domain-model.md)*

Capability-to-code mapping. Use this as the authoritative reference for "what owns what."

### {BC-NNN} — {Capability Name}

**Description**: {one sentence from l1-capabilities.md}
**Health**: {Strong / Needs Attention / At Risk}
**Cohesion**: {HIGH / MEDIUM / LOW}
**Coupling**: {HIGH / MEDIUM / LOW} — depends on: {BC-NNN list if any}
**LOC**: {n}

**Primary locations**:
```
{file or module paths — one per line, from domain-model.md or context.json}
```

**L2 sub-capabilities**:
| ID | Sub-Capability | LOC | Location |
|----|---------------|-----|----------|
| BC-{NNN}-{NN} | {name} | {n} | {path} |

{Repeat for every L1 capability}

---

## Ownership Assignments
*Source: [domain-model.md](domain-model.md)*

Based on bounded context analysis. Use as a starting point for team/squad assignments.

| Ownership Area | Capabilities | Suggested Team | Rationale |
|---------------|-------------|----------------|-----------|
| {area name} | {BC-NNN list} | {team name or TBD} | {shared lifecycle, data model, or release cadence} |

{Derive from domain-model.md → Bounded Context Candidates.}

---

## Health Dashboard
*Source: [analysis.md](analysis.md)*

Quick-scan view for sprint planning and tech debt backlog prioritisation.

| Capability | Health | Cohesion | Coupling | LOC | Action |
|-----------|--------|----------|----------|-----|--------|
| BC-{NNN}: {name} | Strong | HIGH | LOW | {n} | None — preserve as-is |
| BC-{NNN}: {name} | Needs Attention | MED | HIGH | {n} | Reduce coupling with BC-{NNN} |
| BC-{NNN}: {name} | At Risk | LOW | HIGH | {n} | Refactor before next feature |

Health signal:
- **Strong**: HIGH cohesion, LOW or MEDIUM coupling
- **Needs Attention**: MEDIUM cohesion OR HIGH coupling
- **At Risk**: LOW cohesion OR very HIGH coupling (across multiple capabilities)

---

## Refactor Targets
*Source: [analysis.md](analysis.md)*

Capabilities where structural problems will slow down feature work. Ordered by risk.

### 1. BC-{NNN} — {name} *(highest priority)*

**Problem**: {specific coupling or cohesion issue — name the other capabilities it depends on and why that's a problem}
**Evidence**: {metric values from analysis.md — coupling score, dependency count, etc.}
**Impact**: {what gets harder if this isn't addressed — e.g., "any change to Payments risks breaking Accounts due to shared transaction schema"}
**Suggested approach**: {specific refactoring technique — e.g., "Extract shared schema types to a kernel module", "Introduce repository interface to break direct DB dependency", "Split BC-NNN-04 into its own module"}
**Estimated scope**: {LOW (<1 week) / MEDIUM (1–2 sprints) / HIGH (3+ sprints)}

{Repeat for each At Risk and high-priority Needs Attention capability}

---

## Orphan Code
*Source: [coverage.md](coverage.md)*

Code with no capability owner. Orphan zones are tech debt indicators — they may be dead code, shared utilities with no clear home, or hidden capability fragments.

**Total orphan**: {percentage} — {LOC count}

### Orphan Hotspots

| Location | LOC | Likely Explanation | Recommended Action |
|----------|-----|-------------------|-------------------|
| {path} | {n} | {dead code / shared util / fragment of BC-NNN / unclear} | {delete / assign to BC-NNN / extract as shared kernel / investigate} |

{Derive from coverage.md. List all orphan zones with > {threshold} LOC.}

---

## Coverage Breakdown
*Source: [coverage.md](coverage.md)*

| Capability | LOC | % of Total | Coverage |
|-----------|-----|------------|----------|
| BC-{NNN}: {name} | {n} | {%} | {% of capability LOC mapped} |
| *(Orphan)* | {n} | {%} | — |
| **Total** | {n} | 100% | {overall %} |

---

## Security Findings for Developers
*Sources: [../security/vulnerabilities/catalog.json](../security/vulnerabilities/catalog.json) · [../security/gaps.json](../security/gaps.json)*

{If docs/security/vulnerabilities/catalog.json exists:}

These findings require code changes. Ordered by severity.

### Confirmed Vulnerabilities

| ID | Severity | Capability | File | Issue | Fix |
|----|----------|-----------|------|-------|-----|
| VULN-{NNN} | CRITICAL/HIGH | BC-{NNN} | {file:line} | {brief description} | {specific fix} |

*(Include only CONFIRMED CRITICAL and HIGH. For full catalog see docs/security/vulnerabilities/catalog.json)*

### Critical Control Gaps

{From docs/security/gaps.json — CRITICAL gaps only:}

| Gap | Capability | Missing Control | Where to Add |
|-----|-----------|----------------|--------------|
| GAP-{NNN} | BC-{NNN} | {control description} | {specific module or layer} |

{If no security assessment: "Security assessment not yet run. Run `/assess` to surface code-level vulnerabilities and control gaps."}

---

## QA Findings for Developers
*Sources: [../qa/qa-signals.json](../qa/qa-signals.json) · [../qa/qa-gaps.json](../qa/qa-gaps.json) · [../qa/capability-qa-contexts.json](../qa/capability-qa-contexts.json)*

{If docs/qa/qa-signals.json exists:}

These findings require code changes (testability refactors or new tests). Ordered by severity.

### Testability Refactors

*(HIGH-severity testability findings — each one blocks unit-level isolation and typically forces integration tests.)*

| ID | Capability | Category | File:Line | Issue | Suggested Fix |
|----|-----------|----------|-----------|-------|---------------|
| QS3-{cat}-{NNN} | BC-{NNN} | {category} | {file:line} | {details} | {hint} |

*(Include all HIGH. For the full list — including MEDIUM and LOW — see docs/qa/qa-signals.json.)*

### Coverage Gaps Worth Code Work

*(Capabilities with `coverage_gap_indicator` of `high` or `moderate` where the fastest win is adding a small number of focused tests in code.)*

| Capability | Gap Indicator | Tests/KLOC | Suggested Test Level | Scenario |
|-----------|---------------|-----------:|---------------------|----------|
| BC-{NNN}: {name} | high/moderate | {x.x or `not-collected`} | unit / integration / e2e | {what scenario is under-covered — derived from QAGAP description} |

### QA Gaps Requiring Code Changes

{From docs/qa/qa-gaps.json — HIGH and CRITICAL, excluding INFO-severity signal-collection gaps:}

| Gap | Capability | Description | Action | Effort |
|-----|-----------|-------------|--------|--------|
| QAGAP-{NNN} | BC-{NNN} | {description} | {recommendation} | LOW/MED/HIGH |

{If no QA assessment: "QA signals not yet scanned. Run `/assess` to surface testability findings and QA gaps (also visible standalone in docs/qa/sdet-report.md when `/report` has run)."}

---

## Dev Readiness Overview
*Sources: [../dev/dev-readiness-scores.json](../dev/dev-readiness-scores.json) · [../dev/dev-blockers.json](../dev/dev-blockers.json)*

{If docs/dev/dev-readiness-scores.json exists:}

Implementation readiness status per capability. For the full breakdown (dependency health, environment setup guide, architecture fitness, estimation anchors) see `docs/dev/dev-readiness-report.md`.

| Capability | Readiness | Blockers | Top Risk Driver |
|-----------|-----------|---------|----------------|
| BC-{NNN}: {name} | READY / NEEDS_ATTENTION / BLOCKED | {N or none} | {dimension name or none} |

{If any CRITICAL or HIGH blockers in dev-blockers.json:}

**Blockers requiring resolution before implementation starts:**

| ID | Severity | Scope | Issue | Resolution |
|----|---------|-------|-------|-----------|
| DEV-BLK-{NNN} | CRITICAL/HIGH | BC-{NNN}/global | {description} | {resolution} |

{If no dev signals: "Dev readiness scan not yet run. Run `/assess` (dev lane) and re-run `/report` to surface implementation blockers, dependency health, and environment setup requirements."}

---

## Sprint Recommendations

{5–7 concrete engineering actions, prioritised. Each should be a ticket-ready task.}

1. **[REFACTOR]** {specific action} — Capability: BC-{NNN} — Scope: {LOW/MED/HIGH} — Rationale: {one sentence}
2. **[SECURITY]** {specific action} — File: {path} — Scope: LOW — Rationale: {one sentence}
3. **[OWNERSHIP]** Assign {orphan path} to BC-{NNN} — Scope: LOW — Rationale: reduces ambiguity in {area}
4. {etc.}

---

## Discovery Artifacts

| Artifact | Use For |
|---------|---------|
| [l1-capabilities.md](l1-capabilities.md) | Authoritative capability list |
| [l2-capabilities.md](l2-capabilities.md) | Operation-level ownership |
| [domain-model.md](domain-model.md) | Entity and bounded context reference |
| [analysis.md](analysis.md) | Raw cohesion/coupling metrics |
| [coverage.md](coverage.md) | Orphan code detail |
| [../security/vulnerabilities/catalog.json](../security/vulnerabilities/catalog.json) | Full security findings *(if available)* |
| [../security/gaps.json](../security/gaps.json) | Control gap detail *(if available)* |
| [../qa/sdet-report.md](../qa/sdet-report.md) | SDET view — test posture, coverage, testability |
| [../qa/qa-signals.json](../qa/qa-signals.json) | Raw QA signals *(if available)* |
| [../qa/qa-gaps.json](../qa/qa-gaps.json) | QA gap detail *(if available)* |
| [../dev/dev-readiness-report.md](../dev/dev-readiness-report.md) | Dev readiness — blockers, setup guide, estimation anchors *(if available)* |
| [../dev/dev-blockers.json](../dev/dev-blockers.json) | Implementation blockers *(if available)* |
| [architect-report.md](architect-report.md) | Decomposition and topology view |
| [stakeholder-report.md](stakeholder-report.md) | Business summary |
```

After writing the file:
- Tell the user: "Dev report generated at docs/discovery/dev-report.md. {N} capabilities mapped, {at_risk_count} at risk, {orphan_pct}% orphan code, {vuln_count} confirmed vulnerabilities surfaced."

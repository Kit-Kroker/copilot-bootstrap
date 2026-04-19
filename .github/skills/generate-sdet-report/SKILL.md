---
name: generate-sdet-report
description: Generate the SDET/QA discovery report — test inventory, coverage posture, testability findings, automation status, defect profile, environment parity, and QA risk rankings. Always emitted (never gated); explicitly lists "not-collected" signals so the team knows what to wire up next.
argument-hint: "[leave blank to generate full report]"
---

# Skill Instructions

**Pre-generated input check:** If `docs/qa/sdet-report.md` already exists, report that it was found and skip to the next step.

The SDET report is ALWAYS emitted. If inputs are missing or all-"not-collected", still generate the report — it will be a frank account of what we don't yet know, with a "Not-Collected Summary" section guiding the team on what signals to collect next.

Read (all optional; emit not-collected markers when absent):
- `docs/qa/qa-signals.json` ← if present
- `docs/qa/capability-qa-contexts.json` ← if present
- `docs/qa/qa-risk-scores.json` ← if present
- `docs/qa/qa-gaps.json` ← if present
- `docs/discovery/l1-capabilities.md` ← required (report scopes to discovered capabilities)
- `docs/discovery/l2-capabilities.md` ← if present
- `docs/discovery/domain-model.md` ← required
- `.project/state/answers.json` (for project name, stack, qa_scope)
- `.discovery/context.json` ← for stack/framework metadata

If `docs/qa/qa-signals.json` is absent entirely, note at the top: "QA signal scan has not been run. This report is a capability scaffold with every field marked not-collected. Run `/assess` (or the scan-qa-signals step) to populate." Then still emit the capability scaffold rather than failing.

## Report Generation

Write for an SDET / QA lead / test architect reviewing the state of the system before planning the test strategy. Be concrete. When a value is `"not-collected"`, render it literally as `not-collected` in the report — this is a first-class honesty mechanism, not a placeholder.

Every section that draws from a specific artifact must include a source line immediately below the section heading, in the form `*Source: [filename](relative-path-from-docs/qa/)*`. The report lives in `docs/qa/`. Links to discovery artifacts use `../discovery/filename`. Multiple sources are separated with ` · `.

## Output

Write to: `docs/qa/sdet-report.md`

```markdown
# {Project Name} — SDET Discovery Report

**Date**: {today}
**System**: {project name from answers.json}
**Stack**: {language/framework/persistence from context.json or "not-collected"}
**Audience**: SDETs, QA leads, test architects, engineering managers

---

## Summary

{3–5 sentences:
- Overall test posture (strong/adequate/weak/unknown counts)
- Biggest QA risk finding (highest qa_composite or largest unknown cluster)
- Top recommendation for the first sprint of QA improvement work
- If many not-collected signals exist: call out that test planning confidence is limited until those are wired up}

---

## QA Posture Overview

*Source: [capability-qa-contexts.json](capability-qa-contexts.json) · [qa-risk-scores.json](qa-risk-scores.json)*

- **Capabilities assessed**: {count or not-collected}
- **QA posture distribution**: {strong} strong / {adequate} adequate / {weak} weak / {unknown} unknown
- **Test frameworks detected**: {comma list or "none detected" or "not-collected"}
- **Total test files**: {n or "not-collected"} — {unit} unit / {integration} integration / {e2e} e2e / {contract} contract / {perf} performance / {unknown} unknown
- **Coverage measured**: {true with lines/branches summary} | {false — thresholds declared but no report} | `not-collected`
- **Testability findings**: {count} ({high_sev} HIGH severity) | `not-collected`
- **CI systems detected**: {names} | `not-collected`
- **Highest QA risk**: BC-{NNN} ({name}) — qa_composite {score} | `not-collected`

---

## Test Inventory by Framework
*Source: [qa-signals.json](qa-signals.json)*

| Framework | Version | Config | Unit | Integration | E2E | Contract | Perf | Unknown | Confidence |
|-----------|---------|--------|------|-------------|-----|----------|------|---------|-----------|
| {name} | {version or `not-collected`} | {config file} | {n} | {n} | {n} | {n} | {n} | {n} | HIGH/MED/LOW |

{If no frameworks detected: render a single row "no frameworks detected" and note the implication — the system has no codified test suite or tests live outside the scanned path.}

---

## Test Pyramid Shape
*Source: [qa-signals.json](qa-signals.json)*

Ratio-based view (use proportional ASCII bars so reviewers can eyeball the shape):

```
Unit         {bar} {n} ({pct}%)
Integration  {bar} {n} ({pct}%)
E2E          {bar} {n} ({pct}%)
Contract     {bar} {n} ({pct}%)
Performance  {bar} {n} ({pct}%)
```

**Shape assessment**: {healthy pyramid / inverted / hourglass / top-heavy / absent / `not-collected`}
**Commentary**: {1–2 sentences on what the shape implies for defect-escape risk and CI time}

---

## Coverage Posture
*Source: [qa-signals.json](qa-signals.json)*

| Tool | Config | Thresholds | Last Measured | Report Path | Confidence |
|------|--------|-----------|---------------|-------------|-----------|
| {tool} | {path} | lines: {n or `not-collected`}, branches: {n or `not-collected`} | lines: {n or `not-collected`} | {path} | HIGH/MED/LOW |

**Proxy coverage per capability** *(when direct measurement isn't available)*:

| Capability | Test files touching | Tests per KLOC | Coverage Gap Indicator |
|-----------|--------------------:|---------------:|----------------------|
| BC-{NNN}: {name} | {n} | {x.x} | none / low / moderate / high / `not-collected` |

---

## Automation Status by Capability
*Source: [capability-qa-contexts.json](capability-qa-contexts.json)*

| Capability | Unit | Integration | E2E | Contract | Posture |
|-----------|:----:|:-----------:|:---:|:--------:|---------|
| BC-{NNN}: {name} | yes/no/`not-collected` | yes/no/`not-collected` | yes/no/`not-collected` | yes/no/`not-collected` | strong/adequate/weak/unknown |

---

## Testability Findings
*Source: [qa-signals.json](qa-signals.json)*

Code-level issues that inflate test difficulty or flakiness risk. Prioritized by severity.

### High-Severity Findings

| ID | Capability | Category | Location | Issue | Suggested Fix |
|----|-----------|----------|----------|-------|---------------|
| QS3-{cat}-{NNN} | BC-{NNN} | {category} | {file:line} | {details} | {one-line hint} |

{If no HIGH findings but MEDIUM exist: include a "Medium-Severity Findings" table. If none at all and the scan ran: state "No testability issues detected in the static scan". If the scan didn't run: state `not-collected` and do not fabricate.}

---

## QA Risk Ranking
*Source: [qa-risk-scores.json](qa-risk-scores.json)*

Ordered by `qa_composite` (descending). Capabilities with `qa_composite_status = "unknown"` listed at the bottom.

| # | Capability | qa_composite | Status | Coverage Gap | Testability | Defect Density | Change Velocity | Drivers |
|---|-----------|-------------:|--------|-------------:|------------:|---------------:|----------------:|---------|
| 1 | BC-{NNN}: {name} | {score} | complete/partial/unknown | {n or `not-collected`} | {n or `not-collected`} | {n or `not-collected`} | {n or `not-collected`} | {dimensions that drove the score} |

**Weights applied**: coverage_gap={w}, testability={w}, defect_density={w}, change_velocity={w} ({default or override})

---

## QA Gaps & Remediation Priorities
*Source: [qa-gaps.json](qa-gaps.json)*

Ordered by severity, then effort (lowest effort first within a severity band).

### Immediate — CRITICAL

| Gap | Capability | Description | Recommendation | Effort |
|-----|-----------|-------------|----------------|--------|
| QAGAP-{NNN} | BC-{NNN} | {description} | {action} | LOW/MED/HIGH |

### Short-term — HIGH

| Gap | Capability | Description | Recommendation | Effort |
|-----|-----------|-------------|----------------|--------|
| QAGAP-{NNN} | BC-{NNN} | {description} | {action} | LOW/MED/HIGH |

### Signal-Missing — INFO

*(Gaps where a key input was `not-collected`. Closing these is a prerequisite to trustworthy QA risk scoring.)*

| Gap | Capability | What's Missing | How to Collect It |
|-----|-----------|----------------|-------------------|
| QAGAP-{NNN} | BC-{NNN} | {dimension} | {specific action} |

---

## CI & Environment Posture
*Source: [qa-signals.json](qa-signals.json) · [capability-qa-contexts.json](capability-qa-contexts.json)*

**CI systems detected**:

| CI | Config file | Test stages | Blocking gates | Branch protection |
|----|-------------|-------------|----------------|-------------------|
| {name} | {path} | {stage list} | {list or `not-collected`} | yes/no/`not-collected` |

**Environment artifacts**:

| Type | File | Environments | Parity indicators |
|------|------|--------------|-------------------|
| {type} | {path} | {env list or `not-collected`} | {bullets or `not-collected`} |

**Defect profile**: {source or `not-collected`} — {density summary or `not-collected`}
**Change velocity**: {measured: true/false} — {hotspot summary or `not-collected`}

---

## Not-Collected Summary

*This section is always present. It lists every signal that could not be determined from static evidence, so the team can prioritize wiring those signals up.*

| Field | Why not collected | How to collect it |
|-------|-------------------|-------------------|
| coverage.last_measured | No coverage report committed to repo | Enable coverage reporter in CI and commit badge/summary, or connect Codecov/Coveralls |
| defect_profile.density | No defect source configured in `qa_scope.defect_sources` | Set `qa_scope.defect_sources` in answers.json (e.g., `["github_issues"]` or `["jira"]`) and re-run |
| change_velocity.commits_last_90_days | git log not accessible during scan | Ensure the working tree is a git checkout when running `/assess` |
| {...one row per entry in qa-signals.json `summary.not_collected_fields` and per missing-dimension entry in qa-risk-scores.json...} | | |

{If the list is empty — rare but possible — state: "All QA signals were collectable. The SDET report reflects the full measurable posture of the system."}

---

## Recommended Test Strategy (Next 1–2 Sprints)

{5–8 concrete SDET actions, ticket-ready. Each must name the capability, the action, and the effort band.}

1. **[COVERAGE]** {specific action} — Capability: BC-{NNN} — Effort: {LOW/MED/HIGH} — Rationale: {one sentence tied to a gap or driver}
2. **[TESTABILITY]** Refactor {file or pattern} to inject {seam} — Capability: BC-{NNN} — Effort: MED — Rationale: unlocks unit-level isolation for the {x} downstream tests
3. **[AUTOMATION]** Add {level} tests for {scenario} — Capability: BC-{NNN} — Effort: {LOW/MED/HIGH}
4. **[CI]** {specific action, e.g., make coverage threshold blocking in PR pipeline} — Effort: LOW
5. **[SIGNAL]** Wire up {defect source / coverage reporter / env parity check} so future QA risk scoring can include {dimension} — Effort: LOW — Rationale: closes QAGAP-{NNN}
6. {...}

---

## Discovery Artifacts

| Artifact | Use For |
|---------|---------|
| [qa-signals.json](qa-signals.json) | Raw QA scan signals (inventory, coverage, testability, CI) |
| [capability-qa-contexts.json](capability-qa-contexts.json) | Per-capability QA posture and automation status |
| [qa-risk-scores.json](qa-risk-scores.json) | Per-capability QA risk scores and drivers |
| [qa-gaps.json](qa-gaps.json) | QA gaps with remediation recommendations |
| [../discovery/l1-capabilities.md](../discovery/l1-capabilities.md) | Authoritative capability list |
| [../discovery/domain-model.md](../discovery/domain-model.md) | Entity and bounded context reference |
| [../risk/unified-risk-map.json](../risk/unified-risk-map.json) | Unified security+QA composite *(if `/assess` has run)* |
| [../discovery/architect-report.md](../discovery/architect-report.md) | Architecture view with QA+security overlays |
| [../discovery/dev-report.md](../discovery/dev-report.md) | Dev-team view with QA findings |
```

After writing the file:
- Update `.project/state/workflow.json`: set `step` to `generate_qa_contexts`, `status` to `in_progress` (if the broader QA pipeline runs this step, otherwise leave as is when called standalone from /report)
- Tell the user: "SDET report generated at docs/qa/sdet-report.md. {N} capabilities scoped, {posture_summary}, {not_collected_count} fields marked not-collected. {rec_count} sprint recommendations."

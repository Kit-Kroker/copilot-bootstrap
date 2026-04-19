---
name: generate-qa-contexts
description: Generate AI-ready QA context packages and test-strategy prompts per capability for downstream tooling (Cursor, Copilot, Claude Code). Mirrors generate-security-contexts but for test automation. Propagates "not-collected" markers honestly. Use this when workflow step is "generate_qa_contexts" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/qa/generate/qa-prompts.md` already exists, report that it was found and skip to the next step.

Read (required unless noted):
- `docs/discovery/domain-model.md`
- `docs/discovery/l1-capabilities.md`
- `docs/qa/qa-signals.json` ← if absent, proceed with capability scaffold only
- `docs/qa/capability-qa-contexts.json` ← if absent, proceed with capability scaffold only
- `docs/qa/qa-risk-scores.json` ← if absent, proceed with capability scaffold only
- `docs/qa/qa-gaps.json` ← if absent, proceed with capability scaffold only
- `.project/state/answers.json` (qa_scope)

If QA artifacts are absent, still generate scaffolds — they will be mostly `not-collected` but give the team a starting point for wiring up signals.

## Process

### GQ1 — Generate Capability-Scoped QA Context Packages

For each capability (prioritize by qa_composite descending; capabilities with `"unknown"` qa_composite come after numeric scores but are still generated), create a self-contained context file that an AI tool can use to write or review tests for this capability.

Write to: `docs/qa/generate/capability-contexts/BC-{NNN}-qa-context.md`

```markdown
# BC-{NNN}: {Capability Name} — QA Context

**QA Composite**: {score or "unknown"} ({status})
**QA Posture**: {strong | adequate | weak | unknown}
**Drivers**: {dimensions that drove the score, or "not-collected"}

## Code Scope

Files and directories to test:
- `{path}` — {description}
- `{path}` — {description}

Key entry points that need test coverage:
- `{HTTP method} {endpoint}` — {what it does}
- `{job name}` — {what it does}

Key entities exercised by this capability:
- {entity name} — fields: {comma list}

## Current Automation Status

| Level | Present | Count | Notes |
|-------|:-------:|------:|-------|
| Unit | yes/no/`not-collected` | {n} | {framework} |
| Integration | yes/no/`not-collected` | {n} | {framework} |
| E2E | yes/no/`not-collected` | {n} | {framework} |
| Contract | yes/no/`not-collected` | {n} | {framework} |
| Performance | yes/no/`not-collected` | {n} | {framework} |

**Coverage**: {measured summary or `not-collected`} (proxy tests_per_kloc: {x.x or `not-collected`})
**Coverage gap indicator**: {none / low / moderate / high / `not-collected`}

## Testability Considerations

{For each testability finding on this capability:}
- **{QS3-...}** ({severity}): {details} — *Suggested fix*: {one-line hint}

{If no findings but scan ran: "No testability issues detected for this capability in the static scan."}
{If scan didn't run: "Testability findings: `not-collected` — run scan-qa-signals to populate."}

## QA Gaps for This Capability

{From qa-gaps.json, filter to this capability:}
- **{QAGAP-NNN}** ({severity}): {description} — *Action*: {recommendation} (effort: {effort})

## Test Strategy Guidance

Recommended order of test-suite investment for this capability, based on its risk profile and current posture:

1. {Specific test-level / scenario, driven by the top gap}
2. {Specific test-level / scenario, driven by the next gap}
3. {Signal-collection task if `qa_composite_status` is "unknown" or "partial"}

## AI Working Instructions

When writing tests for this capability:
1. Prefer {level of test} for {reason based on drivers}
2. Mock only at system boundaries — {list boundaries from domain-model External fields}
3. Test data fixtures live at: {path or `not-collected`}
4. Flaky-test patterns to avoid: {list based on testability findings — timing, randomness, singletons}
5. Contracts to honor: {list contracts / API schemas if detected, else `not-collected`}

Do not assume values marked `not-collected` are zero — they are unknown. If a test-strategy decision depends on one of these, flag it in the PR rather than guessing.
```

### GQ2 — Generate QA / Test-Strategy Prompts

Generate targeted prompts for AI-assisted test authoring and QA remediation. Each prompt must:
- Reference a specific capability by ID and name
- Reference specific files and line numbers where relevant
- Reference the specific gap (QAGAP-NNN) or driver (coverage_gap / testability / etc.) being addressed
- Not be generic — no "write more tests" prompts

Organize by priority:
1. CRITICAL qa_composite remediation
2. HIGH qa_composite remediation
3. Testability refactors (HIGH severity findings)
4. Signal-collection tasks (wire up missing signals so next /assess is trustworthy)
5. CI quality-gate improvements

Prompt format:
```
## {Priority}: {Short Title}

**Capability**: BC-{NNN} {name}
**Addresses**: {QAGAP-NNN | QS3-...}
**Severity**: {CRITICAL | HIGH | MEDIUM | INFO}

{2-3 sentence prompt with specific files, capabilities, and driver context. Concrete test scenarios, not abstractions.}
```

Write to: `docs/qa/generate/qa-prompts.md`

```markdown
# QA Remediation & Test-Strategy Prompts

Generated {date} | {N} prompts | Ordered by priority

## Usage

These prompts are scoped to specific capabilities and files. Use the capability QA context file in `docs/qa/generate/capability-contexts/` to give the AI tool the full QA context before running the prompt.

---

## CRITICAL Priority

{prompts for CRITICAL qa_composite capabilities and gaps}

---

## HIGH Priority

{prompts for HIGH qa_composite capabilities and gaps}

---

## Testability Refactors

{prompts targeting HIGH-severity testability findings so that unit-level isolation becomes possible}

---

## Signal Collection

*(Closes INFO-severity QAGAPs where inputs were `not-collected`. Must run before next `/assess` to get trustworthy risk scores.)*

{prompts describing how to wire up coverage reporters, defect sources, parity checks, etc.}

---

## CI Quality Gates

{prompts for CI changes — making coverage thresholds blocking, adding required status checks, adding contract-test stages}
```

### GQ3 — Generate QA-Focused Specification Seeds

For capabilities with:
- `qa_composite ≥ 0.6` (numeric), OR
- `qa_composite_status == "unknown"` AND `criticality` in security context is `high`, OR
- Listed as "MISSING" or "Partial" in blueprint comparison (if present)

Generate a QA-flavored specification seed that complements the security spec seed.

Write to: `docs/qa/generate/spec-seeds/BC-{NNN}-qa-spec-seed.md`

```markdown
# BC-{NNN}: {Capability Name} — QA Specification Seed

**Purpose**: Starting point for test-strategy planning or test-suite modernization
**QA Composite**: {score or "unknown"} ({status})
**Drivers**: {dimensions}

## Testable Behavior Surface

{From domain-model.md: 2-3 sentences on what externally observable behavior must be preserved}

### L2 Operations Requiring Coverage

{List each L2 with its key operations — each must have at least one test}

### Invariants to Protect

{List any invariants (ownership, auth, data integrity) derivable from the domain model and security context, if present}

### External Boundaries to Stub or Contract-Test

{List trust boundaries / external services from domain model and, if available, security context}

## Test Requirements

### Must Preserve (existing tests to keep)
- {list current test suites that pass for this capability, so we don't regress}

### Must Add (coverage gaps to close)
- {list specific test scenarios tied to QAGAP-NNN items}

### Must Enable (testability refactors)
- {list refactors that unblock unit testing — e.g., inject Clock, extract interface}

### Must Measure (signals to wire up)
- {list `not-collected` dimensions that need collection — e.g., "branch coverage in CI", "defect density from Jira"}

## Recommended Test Pyramid Shape

{For this capability, recommended distribution of unit/integration/e2e/contract, driven by criticality + external surface}
```

After generating all files:
- Update `.project/state/workflow.json`: set `step` to `qa_complete`, `status` to `completed`
- Tell the user: "QA context packages generated for {N} capabilities. {prompts} targeted test/QA prompts created ({critical} CRITICAL, {high} HIGH, {info} signal-collection). {seeds} QA spec seeds generated for high-risk / unknown-posture capabilities."

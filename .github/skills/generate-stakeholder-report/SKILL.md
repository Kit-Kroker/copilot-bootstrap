---
name: generate-stakeholder-report
description: Generate a non-technical stakeholder report from brownfield discovery outputs. Synthesizes capabilities, health signals, industry alignment, and modernization posture into a single document readable by executives, product managers, and business analysts.
argument-hint: "[leave blank to generate full report]"
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/stakeholder-report.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/domain-model.md` ← required
- `docs/discovery/blueprint-comparison.md` ← required
- `docs/discovery/analysis.md` ← required (for health signals)
- `docs/discovery/coverage.md` (for coverage percentage)
- `.discovery/context.json` (for system metadata)
- `.project/state/answers.json` (for project name, domain, stakeholder context)

## Report Generation

Write for a non-technical audience — executives, product managers, business analysts, and engineering managers. No jargon, no file paths, no code snippets. Replace technical terms with business equivalents:

| Technical | Business-friendly |
|-----------|------------------|
| L1 capability | business capability |
| L2 sub-capability | process / operation |
| Cohesion / coupling | how well-defined / how entangled |
| LOC | code volume |
| BIAN-aligned | industry standard |
| Orphan code | unclaimed code |
| BC-NNN | {capability name} (use name, not ID) |

## Output

Write to: `docs/discovery/stakeholder-report.md`

```markdown
# {Project Name} — Capability Discovery Report

**Date**: {today}
**System**: {project name from answers.json}
**Domain**: {domain from answers.json}
**Prepared for**: Stakeholder review

---

## Executive Summary

{3–5 sentences covering:
- What the system was analysed for and what method was used (automated capability extraction)
- Total number of business capabilities discovered
- Most significant finding (e.g., strongest capability, biggest gap, or main modernisation signal)
- Top recommendation in plain language}

---

## What This System Does

{1–2 paragraphs describing the system's business purpose in plain language. Derive from domain-model.md → System Overview. No technical terms. Answer: what problem does this system solve, who uses it, and what are its core business outcomes.}

### Core Business Capabilities

List all L1 capabilities. Use the business name only. Add a one-sentence plain-language description for each, derived from l1-capabilities.md → Capability Details. Group by business domain (customer-facing, product, operational, platform) if the grouping is natural.

| # | Capability | What It Does | Health Signal |
|---|-----------|--------------|---------------|
| 1 | {name} | {one sentence, plain language} | {Strong / Needs Attention / At Risk} |

Health signal mapping (derive from analysis.md cohesion/coupling per capability):
- **Strong**: HIGH cohesion, LOW or MEDIUM coupling — well-defined, easy to own
- **Needs Attention**: MEDIUM cohesion OR HIGH coupling — works but changes are harder
- **At Risk**: LOW cohesion OR very HIGH coupling across multiple capabilities — fragile, changes likely to cause side effects

---

## System Health Overview

{2–3 sentences: overall assessment of the system's structural health. Translate coverage percentage and orphan code into business risk. Example: "88% of the codebase is mapped to business capabilities, leaving 12% as unclaimed code with no clear ownership — a moderate technical debt signal."}

### Capability Health Breakdown

| Health Signal | Count | Capabilities |
|--------------|-------|-------------|
| Strong | {n} | {comma-separated names} |
| Needs Attention | {n} | {comma-separated names} |
| At Risk | {n} | {comma-separated names} |

### Code Coverage

- **Mapped to capabilities**: {coverage percentage from coverage.md}
- **Unclaimed code**: {orphan percentage} — {plain-language interpretation: low/medium/high concern}

---

## Industry Alignment

{2–3 sentences: how this system compares to {framework name} industry standards for {domain}. Summarise the overall alignment score in plain language. Example: "The system covers 14 of 18 expected capabilities for a digital banking platform. 3 are handled by external vendors. 1 is a genuine gap worth investigating."}

### Alignment Summary

| Status | Count | What It Means |
|--------|-------|--------------|
| Industry-aligned | {n} | Capability matches what industry peers typically build |
| Organisation-specific | {n} | Custom business logic unique to this organisation |
| Handled externally | {n} | Delegated to a third-party system or vendor |
| Potential gap | {n} | Expected capability with no code presence — needs investigation |

### Capabilities Unique to This Organisation

{From blueprint-comparison.md → Organisation-Specific. List each with a plain-language note on whether it is a differentiator or legacy custom logic.}

| Capability | Note |
|-----------|------|
| {name} | {differentiator / legacy custom / unclear — recommend review} |

### Gaps to Investigate

{From blueprint-comparison.md → Missing from Code, where explanation is "Genuine gap". List only genuine gaps — exclude external and out-of-scope.}

{If none: "No genuine capability gaps were identified. All expected industry capabilities are either present, handled by external systems, or outside the scope of this system."}

| Missing Capability | Why It Matters | Recommended Action |
|-------------------|---------------|-------------------|
| {name} | {business impact in plain language} | {investigate with {team} / plan for roadmap / accept} |

---

## Key Findings

### Strengths

{3–5 bullet points: concrete positive findings derived from discovery. Examples:
- Which capabilities have the strongest code health and industry alignment
- Where the codebase shows clear ownership boundaries
- Any well-structured patterns that should be preserved in future work}

### Areas Requiring Attention

{3–5 bullet points: concrete concerns derived from discovery. Examples:
- Which capabilities show high coupling (fragility risk)
- Where unclaimed code is concentrated
- Any missing controls or integration patterns
Keep each finding actionable: name the capability and describe the business risk.}

---

## Modernisation Positioning

Based on discovery, each capability has been positioned for future roadmap planning. Use this as input for modernisation or migration conversations — not as a final decision.

| Capability | Posture | Rationale |
|-----------|---------|-----------|
| {name} | **Retain** | Strong health, full industry alignment — no changes needed |
| {name} | **Extend** | Good foundation, missing some operations expected by industry |
| {name} | **Refactor** | High coupling or fragmented ownership — restructuring would reduce risk |
| {name} | **Evaluate** | Organisation-specific capability — needs a business decision on long-term value |
| {name} | **Replace** | Weak health, low alignment — consider rebuild when capacity allows |

Posture definitions:
- **Retain** — Keep as-is
- **Extend** — Add missing functionality
- **Refactor** — Improve structure without rebuilding
- **Evaluate** — Needs a business decision before committing resources
- **Replace** — Rebuild when strategic opportunity arises

---

## Proposed Team Ownership

Based on the domain model's bounded context analysis, the system naturally groups into {N} ownership areas. This is a starting-point recommendation — adjust based on team size, skill, and organisational structure.

| Ownership Area | Capabilities Included | Notes |
|---------------|----------------------|-------|
| {area name} | {comma-separated capability names} | {brief rationale — shared data, common lifecycle, etc.} |

{Derive from domain-model.md → Bounded Context Candidates. Translate technical boundary reasoning into business rationale.}

---

## Next Steps

{3–5 concrete recommended actions derived from the findings. Examples:
- "Investigate {gap capability} — confirm whether it is handled by an external system or a genuine gap before the next planning cycle."
- "Prioritise refactoring {at-risk capability} — high coupling with {other capability} makes changes in either area risky."
- "Run a team topology workshop using the proposed ownership areas as a starting structure."
Keep each action concrete: who should do it, what the decision or output is.}

---

## About This Report

This report was generated automatically using code-level capability extraction. All findings are derived from the actual codebase — no assumptions, no surveys. The source of truth is the code. Industry blueprint comparison adds context for modernisation planning but does not override what the code contains.

**Discovery artifacts** (for technical teams): `docs/discovery/`
**Domain model** (for architecture teams): `docs/discovery/domain-model.md`
```

After writing the file:
- Tell the user: "Stakeholder report generated at docs/discovery/stakeholder-report.md. {N} capabilities covered, {aligned} industry-aligned, {at_risk} at risk. Share with stakeholders as a single self-contained document."

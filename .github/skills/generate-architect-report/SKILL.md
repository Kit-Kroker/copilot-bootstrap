---
name: generate-architect-report
description: Generate an architect-focused discovery report from brownfield discovery outputs. Synthesises bounded context analysis, coupling/cohesion detail, decomposition options, and dependency topology into a document for solutions and enterprise architects.
argument-hint: "[leave blank to generate full report]"
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/architect-report.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/discovery/domain-model.md` ← required
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required (if present)
- `docs/discovery/blueprint-comparison.md` ← required
- `docs/discovery/analysis.md` ← required
- `docs/discovery/coverage.md` (for orphan/unmapped code)
- `.discovery/context.json` (for system metadata)
- `.project/state/answers.json` (for project name, domain, tech stack)
- `docs/security/domain-model-secured.md` (if present — enrich with risk overlays)

## Report Generation

Write for solutions architects and enterprise architects. Assume fluency with DDD, bounded contexts, coupling metrics, and decomposition patterns. Be precise — use technical terms, IDs, and actual metric values. No hand-waving.

## Output

Write to: `docs/discovery/architect-report.md`

```markdown
# {Project Name} — Architecture Discovery Report

**Date**: {today}
**System**: {project name from answers.json}
**Domain**: {domain from answers.json}
**Audience**: Solutions architects, enterprise architects

---

## Executive Summary

{3–5 sentences covering:
- Purpose of the analysis and method (automated capability extraction + blueprint comparison)
- Total capabilities, bounded context candidates, and cross-capability dependencies
- Dominant architectural pattern observed (monolith, modular monolith, distributed, hybrid)
- Top architectural concern (highest-coupling hotspot, worst decomposition candidate, or biggest gap)}

---

## System Overview

{Derive from domain-model.md → System Overview. Include:
- Technology stack (languages, frameworks, persistence layers)
- Dominant architectural style (layered, hexagonal, event-driven, CRUD, etc.)
- Approximate codebase size and composition from context.json
- Any architectural patterns visible in the code (e.g., CQRS, outbox, saga, repository pattern)}

---

## Capability Topology

### L1 Capabilities

| ID | Capability | LOC | Cohesion | Coupling | Boundaries | L2 Count |
|----|-----------|-----|----------|----------|------------|----------|
| BC-{NNN} | {name} | {n} | HIGH/MED/LOW | HIGH/MED/LOW | {module/package paths} | {n} |

*(Sorted by coupling DESC — highest coupling first, as these are the decomposition risk areas)*

### Coupling Analysis

{From analysis.md. For each capability with HIGH or VERY HIGH coupling:}

#### BC-{NNN} — {name}

**Coupling**: {level} — depends on: {list of BC-NNN IDs with dependency type}
**Cohesion**: {level} — {brief rationale from analysis}
**Primary concern**: {what this coupling means architecturally — shared data model, transitive calls, circular dependency, etc.}
**Decomposition risk**: HIGH / MEDIUM / LOW — {reason}

---

## Bounded Context Analysis

{From domain-model.md → Bounded Context Candidates. For each candidate:}

### {Context Name}

**Capabilities included**: {BC-NNN list}
**Cohesion signal**: {strong / partial / weak — derived from coupling between members vs. coupling to outside}
**Integration pattern**: {how this context communicates with others — synchronous calls, domain events, shared DB, shared schema, etc.}
**Recommended boundary type**: {well-defined / needs refinement / forced — explain}

#### Cross-Context Dependencies

| From | To | Type | Strength | Notes |
|------|----|------|----------|-------|
| {BC-NNN} | {BC-NNN} | {call / event / data / schema} | {tight / loose} | {what specifically couples them} |

---

## Decomposition Options

Ranked by feasibility given the current coupling topology. Use these as starting-point options — not prescriptions.

### Option 1 — {Name, e.g. "Modular Monolith with Enforced Boundaries"}

**Approach**: {1–2 sentences describing the decomposition strategy}
**Capabilities extracted**: {BC-NNN list}
**Capabilities retained as monolith**: {BC-NNN list}
**Key prerequisite**: {what must change before this is viable — e.g., decouple shared DB access in BC-003 and BC-007}
**Risk**: LOW / MEDIUM / HIGH — {why}

### Option 2 — {Name, e.g. "Extract Core Domain Services"}

**Approach**: {1–2 sentences}
**Capabilities extracted**: {BC-NNN list}
**Key prerequisite**: {prerequisite}
**Risk**: LOW / MEDIUM / HIGH — {why}

{Add a third option only if meaningfully different from the first two}

---

## Modernisation Positioning

| Capability | Posture | Cohesion | Coupling | Rationale |
|-----------|---------|----------|----------|-----------|
| BC-{NNN}: {name} | **Retain** | HIGH | LOW | Strong health, stable boundaries |
| BC-{NNN}: {name} | **Extend** | MED | LOW | Good base, missing L2 operations expected by blueprint |
| BC-{NNN}: {name} | **Refactor** | LOW/MED | HIGH | Tangled dependencies — extract before any feature work |
| BC-{NNN}: {name} | **Evaluate** | — | — | Organisation-specific — needs strategic review |
| BC-{NNN}: {name} | **Replace** | LOW | HIGH | Low cohesion + high coupling — rebuild cheapest path |

---

## Industry Blueprint Gaps

{From blueprint-comparison.md. Architect-relevant framing — focus on which gaps imply integration work vs. net-new capability vs. vendor decision.}

| Missing Capability | Gap Type | Implication |
|-------------------|----------|-------------|
| {name} | {net-new / vendor / integration / out-of-scope} | {architectural implication — e.g., "requires new bounded context", "needs integration adapter", "evaluate vendor vs. build"} |

---

## Code Coverage & Orphan Zones

{From coverage.md}

- **Mapped to capabilities**: {percentage}
- **Orphan code**: {percentage} — {LOC count}

### Orphan Code Hotspots

{List top orphan locations from coverage.md — module/package paths with LOC. Flag any that overlap with high-coupling capabilities.}

| Location | LOC | Adjacent Capability | Risk |
|----------|-----|---------------------|------|
| {path} | {n} | BC-{NNN} | {ownership ambiguity / dead code / hidden coupling} |

---

## Security Risk Overlay

{If docs/security/domain-model-secured.md exists: include a condensed per-capability risk summary for architectural planning.}

| Capability | Risk Score | Top Concern | Architectural Implication |
|-----------|------------|-------------|--------------------------|
| BC-{NNN}: {name} | {score} | {top threat or vuln} | {e.g., "trust boundary required at API edge", "shared auth logic must be extracted"} |

{If docs/security/domain-model-secured.md does not exist: "Security assessment not yet run. Run `/assess` to add security risk overlays."}

---

## Recommended Next Steps

{4–6 concrete, architect-targeted actions. Examples:
- "Decouple BC-003 (Payments) from BC-007 (Accounts) — shared schema is the binding constraint; introduce an anti-corruption layer or extract shared types to a kernel."
- "Run a team topology workshop using the 4 bounded context candidates as the starting structure."
- "Prioritise extracting {high-coupling capability} before any feature roadmap work — current coupling level makes parallel team delivery unsafe."
- "Verify {gap capability} against vendor landscape — if not handled externally, it requires a new bounded context before next major release."}

---

## Discovery Artifacts

| Artifact | Path | Contents |
|---------|------|----------|
| L1 Capabilities | docs/discovery/l1-capabilities.md | Capability inventory with metrics |
| L2 Capabilities | docs/discovery/l2-capabilities.md | Sub-capability detail |
| Domain Model | docs/discovery/domain-model.md | Code-derived entities, bounded contexts |
| Coupling Analysis | docs/discovery/analysis.md | Cohesion/coupling per capability |
| Blueprint Comparison | docs/discovery/blueprint-comparison.md | Industry alignment |
| Coverage Report | docs/discovery/coverage.md | Orphan code analysis |
| Stakeholder Report | docs/discovery/stakeholder-report.md | Non-technical summary |
| Dev Report | docs/discovery/dev-report.md | Engineering team guide |
```

After writing the file:
- Tell the user: "Architect report generated at docs/discovery/architect-report.md. {N} capabilities, {context_count} bounded context candidates, {high_coupling_count} high-coupling hotspots identified."

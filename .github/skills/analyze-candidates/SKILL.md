---
name: analyze-candidates
description: Deep analysis of each capability candidate — cohesion, coupling, boundary clarity — with action determination (confirm/split/merge/de-scope/flag). Use this when workflow step is "analyze_candidates" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/analysis.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/discovery/candidates.md` ← required
- `.project/state/answers.json` (specifically `codebase_setup`)
- The existing codebase at the configured path (for deep code analysis)

## Analysis Process

For each candidate from `candidates.md`, perform:

### A2.1 — Deep Candidate Analysis

Assess three dimensions:

1. **Cohesion** — Does the candidate have a single, coherent business responsibility?
   - HIGH: All code within the candidate serves one business purpose
   - MEDIUM: Mostly coherent, with some tangential functionality
   - LOW: Mixed concerns, multiple unrelated operations

2. **Coupling** — How many other candidates does it depend on?
   - LOW coupling (good): 0-1 dependencies on other candidates
   - MEDIUM coupling: 2-3 dependencies
   - HIGH coupling (concerning): 4+ dependencies

3. **Boundary Clarity** — Does it have clean interfaces?
   - CLEAR: Well-defined API/interface, minimal internal exposure
   - PARTIAL: Some clean boundaries, some shared state or circular dependencies
   - UNCLEAR: Deeply entangled with other candidates, no clear separation

### A2.2 — Action Determination

Force each candidate into exactly one action:

- **CONFIRM** — Candidate is a valid L1 business capability. High cohesion, clear boundaries.
- **SPLIT** — Candidate contains multiple distinct business capabilities. Define what to split into.
- **MERGE** — Candidate is a sub-feature of another capability, not independent. Specify which capability to merge into and why.
- **DE-SCOPE** — Not a business capability. It's infrastructure, cross-cutting concern, test harness, or delivery channel. Explain what it actually is.
- **FLAG** — Cannot determine from code alone. Needs architect or domain expert input. State the specific question.

**Decision heuristics:**
- A delivery channel (mobile app, web portal) is NOT a capability — it's how capabilities are accessed
- Infrastructure (logging, config, auth middleware) is NOT a capability — it's cross-cutting
- If it has its own microservice but is a parameter variation of another capability (e.g. "scheduled payments" = payments + frequency), MERGE it
- **If deployment boundaries and business boundaries disagree, trust the business lens.** Systems deploy services based on technical constraints; business capabilities are defined by business meaning. A service boundary is not a capability boundary.

**Warning — a half-right output is more dangerous than a wrong one.** A completely wrong model gets challenged in the first review. A model that correctly identifies half the capabilities and misclassifies the rest reads professionally, looks credible, and gets nodded through unless someone in the room knows the domain. When in doubt between CONFIRM and FLAG, prefer FLAG. Explicit ambiguity is more useful than false confidence.

### Oversized Candidate Rule

If a candidate exceeds 20% of the total codebase (by LOC), it almost certainly contains multiple capabilities regardless of how cohesive it appears at the surface level. Apply this rule:

- **If LOC > 30% of codebase**: Force SPLIT. A single capability does not account for a third of a system. Investigate internal module boundaries, sub-packages, or distinct entry point groups to identify the split points.
- **If LOC 20-30% of codebase**: Strongly prefer SPLIT unless the candidate is genuinely a single monolithic domain (rare). Document why it should remain unified if you CONFIRM it.
- **If a delivery channel (mobile app, web portal) is this large**: DE-SCOPE it. Redistribute its business logic to the actual domain capabilities it serves.

The banking prototype example: a "Mobile Banking Channel" package at 87K LOC (43% of codebase) is not a capability — it's a delivery channel that wraps the real capabilities. De-scope it and ensure the business logic it contains is attributed to the correct domain capabilities.

**Parameter variation test**: If Candidate A and Candidate B share the same core entities, the same fundamental operation, and differ primarily by a configuration parameter (frequency, channel, product type), they are one capability. The distinguishing parameter becomes a dimension within the capability, not a separate capability.

Example: "Payments - Domestic" and "Payments - Scheduling" share the same payment entities and the same transfer logic. Scheduling adds a frequency parameter and a cron trigger. MERGE "Payments - Scheduling" into "Payments - Domestic" as an L2 sub-capability. The system may deploy them as separate services — deployment boundaries do not define business boundaries.

Concrete test: Ask "would a product owner describe these as separate products/features, or as variations of the same product?" If the answer is variations → MERGE.

### Cross-Validation Check

Before finalizing actions, perform a consistency check across all candidates:

1. **No orphaned merges.** If Candidate X is merged into Candidate Y, verify that Y is CONFIRMED (not itself merged or de-scoped). Merge chains (A → B → C) indicate the analysis needs rethinking.

2. **Split consistency.** If Candidate X is split into X1 and X2, verify that both X1 and X2 would independently pass the CONFIRM criteria (high cohesion, clear boundaries). A split that produces one strong capability and one weak fragment is wrong — the fragment should be merged elsewhere.

3. **Coverage sanity check.** After all actions, estimate whether confirmed + split capabilities account for the majority of business code. If confirmed capabilities only cover 50% of the codebase, either too many candidates were de-scoped or there are missing candidates. Flag this for the coverage step.

4. **Duplicate detection.** Check whether two confirmed candidates are actually the same capability discovered through different signal paths. If BC-X from package analysis and BC-Y from entry point analysis describe the same business domain, merge them.

### A2.3 — Consolidate Actions

Generate `docs/discovery/analysis.md` using this structure:

```markdown
# Candidate Analysis

## Summary

- **Total candidates analyzed**: {count}
- **CONFIRM**: {count} — valid L1 capabilities
- **SPLIT**: {count} — will become {N} capabilities
- **MERGE**: {count} — absorbed into existing capabilities
- **DE-SCOPE**: {count} — not business capabilities
- **FLAG**: {count} — need human review

## Confirmed Capabilities

| # | Candidate | Cohesion | Coupling | Boundary | Action | Notes |
|---|-----------|----------|----------|----------|--------|-------|
| 1 | {name} | HIGH | LOW | CLEAR | CONFIRM | {rationale} |

## Split Decisions

| Original Candidate | Split Into | Rationale |
|--------------------|-----------|-----------|
| {name} | {cap1}, {cap2} | {why splitting is correct} |

## Merge Decisions

| Candidate | Merge Into | Rationale |
|-----------|-----------|-----------|
| {name} | {target capability} | {why it's a sub-feature, not independent} |

## De-Scoped Items

| Candidate | Classification | Rationale |
|-----------|---------------|-----------|
| {name} | Infrastructure / Cross-cutting / Delivery channel / Test harness | {why it's not a business capability} |

## Flagged for Review

| Candidate | Question for Architect |
|-----------|----------------------|
| {name} | {specific question that needs human input} |

## Detailed Analysis

### {Candidate Name}

**Code Footprint**: {N} files, ~{N} LOC, {%} of codebase
**Cohesion**: {HIGH/MEDIUM/LOW} — {evidence}
**Coupling**: {LOW/MEDIUM/HIGH} — depends on: {list with specific file/class references}
**Boundary**: {CLEAR/PARTIAL/UNCLEAR} — {evidence with specific interface/API references}
**Action**: {CONFIRM/SPLIT/MERGE/DE-SCOPE/FLAG}
**Rationale**: {detailed justification with code references}
**Key Entry Points**: {list of controllers/handlers/consumers that belong to this candidate}
**Key Entities**: {list of entities/tables this candidate manages}

{Repeat for each candidate}
```

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `verify_coverage`, `status` to `in_progress`
- Tell the user: "{confirmed} capabilities confirmed, {split} to split, {merged} to merge, {descoped} de-scoped, {flagged} flagged for review."

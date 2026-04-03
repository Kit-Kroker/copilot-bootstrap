---
name: compare-blueprint
description: Compare code-derived capabilities against industry reference frameworks (BIAN, TM Forum, APQC). Identifies aligned, org-specific, and missing capabilities. Use this when workflow step is "blueprint_comparison" (brownfield).
---

# Skill Instructions

**Pre-generated input check:** If `docs/discovery/blueprint-comparison.md` already exists, report that it was found and skip to the next step.

Read:
- `docs/discovery/l1-capabilities.md` ← required
- `docs/discovery/l2-capabilities.md` ← required
- `docs/discovery/domain-model.md` ← required
- `.project/state/answers.json` (specifically `project_info.domain`)

## Industry Reference Selection

Based on the project domain, select the appropriate industry reference:

| Domain | Reference Framework |
|--------|-------------------|
| Banking, finance, payments | BIAN (Banking Industry Architecture Network) |
| Telecom, communications | TM Forum (Frameworx) |
| Insurance | ACORD |
| Healthcare | HL7 / FHIR capability model |
| Retail, e-commerce | ARTS (Association for Retail Technology Standards) |
| Cross-industry / other | APQC Process Classification Framework |

If the domain doesn't match a specific framework, use APQC as the default.

## Comparison Process

### A7.1 — Map Code Capabilities to Industry Reference

For each L1 capability from the code:
- Find the closest matching industry reference capability
- Assess alignment: exact match, partial overlap, or no match

### A7.2 — Identify Gaps

For each expected industry capability NOT found in the code:
- Is it handled by an external system?
- Is it a genuine gap in the codebase?
- Is it out of scope for this system?

**The missing category is the most useful output of this step.** It drives targeted questions — not assumptions. A missing fraud detection capability changes the conversation: it tells the team to ask "is this handled externally?" before concluding it's absent. This is different from validation — the code remains the source of truth. The comparison adds context for modernization planning.

### A7.3 — Classify Results

Categorize each capability:
- **ALIGNED** — Code capability maps to an expected industry capability
- **ORG-SPECIFIC** — Code capability exists but has no industry equivalent (custom business logic)
- **MISSING** — Expected industry capability has no code-level presence

## Output

Generate `docs/discovery/blueprint-comparison.md`:

```markdown
# Industry Blueprint Comparison

## Reference Framework

- **Domain**: {domain}
- **Framework**: {selected framework name}
- **Framework Version**: {if applicable}

## Summary

- **Code-derived L1 capabilities**: {count}
- **Aligned with industry reference**: {count}
- **Organization-specific (no industry match)**: {count}
- **Missing from code (expected by industry)**: {count}

## Alignment Matrix

### Aligned Capabilities

| Code Capability | Industry Reference | Alignment | Notes |
|----------------|-------------------|-----------|-------|
| BC-001: {name} | {industry cap name} | Full / Partial | {details on partial alignment if applicable} |

### Organization-Specific Capabilities

| Code Capability | Notes |
|----------------|-------|
| BC-{NNN}: {name} | {why this is unique to this organization — custom business logic, competitive differentiator, etc.} |

### Missing from Code

| Industry Reference Capability | Likely Explanation | Impact | Recommended Action |
|------------------------------|-------------------|--------|-------------------|
| {industry cap name} | External system / Gap / Out of scope | {HIGH/MEDIUM/LOW} | Investigate / Accept / Plan for future |

## Detailed Comparison

### {Industry Reference Category}

| Industry Capability | Code Match | Status | Evidence |
|--------------------|-----------|--------|----------|
| {cap name} | BC-{NNN} | ALIGNED | {code evidence} |
| {cap name} | — | MISSING | {explanation} |

{Repeat for each industry category}

## Key Findings

### Strengths
- {Where the codebase has strong industry alignment}

### Gaps to Investigate
- {Missing capabilities that need clarification — handled externally or genuine gap?}

### Modernization Opportunities
- {Where industry best practices suggest improvements}
```

**Important:** This is NOT validation — the code remains the source of truth. The comparison adds context for modernization planning. Missing capabilities drive targeted questions, not assumptions.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `prd`, `status` to `in_progress`
- Tell the user: "Blueprint comparison complete. {aligned} aligned, {org_specific} org-specific, {missing} missing. Discovery pipeline finished — all 7 artifacts in docs/discovery/. Next: generate PRD from discovered capabilities."

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

### Custom or Unknown Domains

If the project domain doesn't match any listed framework, or if the user has provided a custom reference:

1. **Check `.project/state/answers.json` for a custom reference.** If `project_info.reference_framework` is set, use it instead of the default mapping.

2. **If no framework matches and none is provided**, use APQC Process Classification Framework as the default, but note its limitations:
   - APQC is generic — it covers cross-industry processes but lacks domain-specific depth
   - The comparison will identify broad alignment but may miss domain-specific gaps
   - Recommend the user provide a custom reference for more meaningful comparison

3. **If the user provides their own reference** (as a document in `codebase_setup.reports`), parse it as the comparison target. Expected format: a list of expected capabilities with descriptions. The comparison process (A7.1–A7.3) remains the same.

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

### A7.2 — Alignment Assessment Criteria

| Alignment Level | Definition | Example |
|----------------|-----------|---------|
| **Full** | Code capability covers the same scope as the industry reference. All major operations present. | Code "Payments - Domestic" aligns fully with BIAN "Payment Execution" |
| **Partial — Subset** | Code capability covers part of the industry reference. Some operations missing. | Code "Account Management" covers account CRUD but not account migration (part of BIAN "Account Management") |
| **Partial — Superset** | Code capability covers more than the industry reference. Additional org-specific operations. | Code "Customer Onboarding" includes gamification triggers not in BIAN |
| **Partial — Overlap** | Code capability partially overlaps but is organized differently. | Code splits "Lending" into "Instant Loans" and "NOU Loans" while BIAN has a single "Lending" capability |
| **None** | No meaningful overlap. Classify as ORG-SPECIFIC. | Code "Gamification" has no BIAN equivalent |

### Determining Why a Capability Is Missing

For each expected industry capability not found in the code, apply these checks in order:

1. **Check external integrations.** Does the domain model reference an external service that handles this? Example: No fraud detection code, but a Fourthline or Sift integration exists → "Handled by external system: {service name}."

2. **Check infrastructure/cross-cutting.** Was this de-scoped during analysis as infrastructure? Example: "Regulatory Reporting" might have been de-scoped as an operational tool → "De-scoped in analysis as: {classification}. Review whether this is correct."

3. **Check the codebase for traces.** Search for keywords, table names, or config references related to the missing capability. If traces exist but were not surfaced as a candidate → "Traces found but not extracted as capability. Possible gap in signal extraction. Files: {list}."

4. **Check if it's out of scope.** Some industry capabilities apply to specific business models. Example: "Trade Finance" in BIAN doesn't apply to a retail-only digital bank → "Out of scope for this system's business model."

5. **If none of the above apply** → "Genuine gap. No code, no external integration, no traces. Recommended action: Investigate with business stakeholders."

This graduated approach prevents the common mistake of labeling everything missing as a "gap" when most are either handled externally or out of scope.

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

## Modernization Positioning

Based on the alignment analysis, position each capability for modernization planning:

| Capability | Industry Alignment | Code Quality Signal | Modernization Posture |
|-----------|-------------------|--------------------|-----------------------|
| BC-{NNN}: {name} | Full | {from analysis.md: cohesion + coupling} | **Retain** — well-aligned, clean boundaries |
| BC-{NNN}: {name} | Partial — Subset | HIGH cohesion, LOW coupling | **Extend** — add missing operations |
| BC-{NNN}: {name} | Partial — Overlap | LOW cohesion, HIGH coupling | **Refactor** — realign to industry boundaries |
| BC-{NNN}: {name} | ORG-SPECIFIC | MEDIUM cohesion | **Evaluate** — is this a differentiator or technical debt? |

Posture definitions:
- **Retain**: Keep as-is, well-aligned and well-structured
- **Extend**: Good foundation, add missing scope
- **Refactor**: Restructure to align with industry boundaries or improve code quality
- **Replace**: Poor alignment and poor code quality — consider rebuild
- **Evaluate**: Org-specific capability that needs a business decision on its future
```

**Important:** This is NOT validation — the code remains the source of truth. The comparison adds context for modernization planning. Missing capabilities drive targeted questions, not assumptions.

After generating the file:
- Update `.project/state/workflow.json`: set `step` to `prd`, `status` to `in_progress`
- Tell the user: "Blueprint comparison complete. {aligned} aligned, {org_specific} org-specific, {missing} missing. Discovery pipeline finished — all 7 artifacts in docs/discovery/. Next: generate PRD from discovered capabilities."

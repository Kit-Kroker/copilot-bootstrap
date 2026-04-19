---
name: assess
description: Run the EDCR security + QA assessment pipeline. Applies STRIDE threat modeling, vulnerability detection, control mapping, risk scoring, QA signal extraction, QA context attachment, and QA risk analysis. Emits a unified security+QA risk map when both lanes complete. Brownfield only. Run after /discover completes.
tools: ['read', 'edit']
---

Run the EDCR security + QA assessment pipeline.

## Pre-flight

1. Read `project.json`. If it doesn't exist: "project.json not found. Run `/init` first."
2. If `approach` is not `"brownfield"`: "Assessment requires brownfield approach. Current: {approach}."
3. Check `.discovery/context.json` exists. If not: "context.json not found. Run `/scan` first."
4. Check `docs/discovery/l1-capabilities.md` exists. If not: "l1-capabilities.md not found. Run `/discover` first — the discovery pipeline must complete all 7 steps."
5. Check `docs/discovery/domain-model.md` exists. If not: "domain-model.md not found. Run `/discover` first — the discovery pipeline must complete all 7 steps."

## Initialize or resume lock file

Check if `.discovery/assess.lock.json` exists.

**If it does not exist**, create it now:

```json
{
  "version": "2",
  "started_at": "<current UTC timestamp as YYYY-MM-DDTHH:MM:SSZ>",
  "steps": {
    "scan_security":           {"status": "pending", "output": "docs/security/security-signals.json",             "lane": "security"},
    "attach_security_context": {"status": "pending", "output": "docs/security/capability-security-contexts.json", "lane": "security"},
    "threat_model":            {"status": "pending", "output": "docs/security/threats/threat-summary.md",         "lane": "security"},
    "vulnerability_detection": {"status": "pending", "output": "docs/security/vulnerabilities/catalog.json",      "lane": "security"},
    "map_controls":            {"status": "pending", "output": "docs/security/controls/control-map.json",         "lane": "security"},
    "scan_qa":                 {"status": "pending", "output": "docs/qa/qa-signals.json",                         "lane": "qa"},
    "attach_qa_context":       {"status": "pending", "output": "docs/qa/capability-qa-contexts.json",             "lane": "qa"},
    "qa_risk_analysis":        {"status": "pending", "output": "docs/qa/qa-risk-scores.json",                     "lane": "qa"},
    "score_risks":             {"status": "pending", "output": "docs/security/risk-scores.json",                  "lane": "unified"}
  }
}
```

**If the lock file already exists** and version is `"1"` (legacy, security-only), migrate it in place: add the `scan_qa`, `attach_qa_context`, and `qa_risk_analysis` steps with `"status": "pending"` and `"lane": "qa"`, add `"lane": "security"` to existing security steps, add `"lane": "unified"` to `score_risks`, and bump `version` to `"2"`. Then say "Resuming assessment pipeline (started {started_at}, migrated from v1 to v2 to add QA lane)..."

**If the lock file already exists** at version `"2"`, read it and say "Resuming assessment pipeline (started {started_at})..."

## Apply skip-if-exists

For each step whose output file already exists and is non-empty, update its status to `"skipped"` in the lock file before running the pipeline.

## Run the pipeline

Security and QA lanes are independent up until `score_risks`, which consumes both. Run security lane first, then QA lane, then the unified `score_risks` step. (A future enhancement can run the two lanes in parallel; keeping them sequential for now to simplify output messages.)

Do NOT wait for user confirmation before starting.

### Security lane

#### Step 1 — `scan_security`

Use the `scan-security-signals` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `scan_security.status` to `"done"`.

#### Step 2 — `attach_security_context`

Use the `attach-security-context` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `attach_security_context.status` to `"done"`.

#### Step 3 — `threat_model`

Use the `threat-model` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `threat_model.status` to `"done"`.

#### Step 4 — `vulnerability_detection`

Use the `detect-vulnerabilities` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `vulnerability_detection.status` to `"done"`.

#### Step 5 — `map_controls`

Use the `map-controls` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `map_controls.status` to `"done"`.

### QA lane

#### Step 6 — `scan_qa`

Use the `scan-qa-signals` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `scan_qa.status` to `"done"`.

#### Step 7 — `attach_qa_context`

Use the `attach-qa-context` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `attach_qa_context.status` to `"done"`.

#### Step 8 — `qa_risk_analysis`

Use the `analyze-qa-risk` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `qa_risk_analysis.status` to `"done"`.

### Unified scoring

#### Step 9 — `score_risks`

Use the `score-risks` skill. If `docs/qa/qa-risk-scores.json` exists (it should, unless the QA lane was entirely skipped), this skill will also compute the unified security+QA composite and emit `docs/risk/unified-risk-map.json`.

After the skill completes, update `.discovery/assess.lock.json`: set `score_risks.status` to `"done"`.

## Complete

After all 9 steps finish, tell the user:

```
Assessment complete.

  Security lane
    Threat model:           docs/security/threats/
    Vulnerabilities:        docs/security/vulnerabilities/catalog.json
    Control map:            docs/security/controls/control-map.json
    Security risk scores:   docs/security/risk-scores.json
    Cross-capability risks: docs/security/cross-capability-risks.json
    Security gaps:          docs/security/gaps.json

  QA lane
    QA signals:             docs/qa/qa-signals.json
    Capability QA contexts: docs/qa/capability-qa-contexts.json
    QA risk scores:         docs/qa/qa-risk-scores.json
    QA gaps:                docs/qa/qa-gaps.json

  Unified
    Unified risk map:       docs/risk/unified-risk-map.json

Next: run `/report` to produce stakeholder, architect, dev, SDET, and security reports, then `/generate` to produce AI-ready context packages and project configuration.
```

If the QA lane was entirely skipped (e.g., user disabled via `qa_scope` or all outputs pre-existed as empty), replace the QA lane block with:

```
  QA lane                   skipped — no QA signals collected
  Unified                   not generated (requires both lanes)
```

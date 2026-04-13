---
name: assess
description: Run the EDCR security assessment pipeline. Applies STRIDE threat modeling, vulnerability detection, control mapping, and risk scoring across all capabilities. Brownfield only. Run after /discover completes.
tools: ['read', 'edit']
---

Run the EDCR security assessment pipeline.

## Pre-flight

1. Read `project.json`. If it doesn't exist: "project.json not found. Run `/init` first."
2. If `approach` is not `"brownfield"`: "Security assessment requires brownfield approach. Current: {approach}."
3. Check `docs/security/capability-security-contexts.json` exists. If not: "capability-security-contexts.json not found. Run `/discover` first — the discovery pipeline must complete all 7 steps including security context attachment."
4. Check `docs/security/security-signals.json` exists. If not: "security-signals.json not found. Run `/scan` first, then `/discover`."

## Initialize or resume lock file

Check if `.discovery/assess.lock.json` exists.

**If it does not exist**, create it now:

```json
{
  "version": "1",
  "started_at": "<current UTC timestamp as YYYY-MM-DDTHH:MM:SSZ>",
  "steps": {
    "threat_model":           {"status": "pending", "output": "docs/security/threats/threat-summary.md"},
    "vulnerability_detection": {"status": "pending", "output": "docs/security/vulnerabilities/catalog.json"},
    "map_controls":           {"status": "pending", "output": "docs/security/controls/control-map.json"},
    "score_risks":            {"status": "pending", "output": "docs/security/risk-scores.json"}
  }
}
```

**If the lock file already exists**, read it and say "Resuming security assessment pipeline (started {started_at})..."

## Apply skip-if-exists

For each step whose output file already exists and is non-empty, update its status to `"skipped"` in the lock file before running the pipeline.

## Run the pipeline

Run all pending steps in sequence. Do NOT wait for user confirmation before starting.

### Step 1 — `threat_model`

Use the `threat-model` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `threat_model.status` to `"done"`.

### Step 2 — `vulnerability_detection`

Use the `detect-vulnerabilities` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `vulnerability_detection.status` to `"done"`.

### Step 3 — `map_controls`

Use the `map-controls` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `map_controls.status` to `"done"`.

### Step 4 — `score_risks`

Use the `score-risks` skill.

After the skill completes, update `.discovery/assess.lock.json`: set `score_risks.status` to `"done"`.

## Complete

After all 4 steps finish, tell the user:

```
Security assessment complete.

  Threat model:          docs/security/threats/
  Vulnerabilities:       docs/security/vulnerabilities/catalog.json
  Control map:           docs/security/controls/control-map.json
  Risk scores:           docs/security/risk-scores.json
  Cross-capability risks: docs/security/cross-capability-risks.json
  Gaps:                  docs/security/gaps.json

Next: run `/generate` to produce AI-ready security context packages and project configuration.
```

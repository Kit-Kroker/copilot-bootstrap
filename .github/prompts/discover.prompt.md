---
name: discover
description: Initialize the brownfield discovery pipeline and run it automatically. Creates pipeline.lock.json (skipping steps whose outputs already exist), then runs all 7 capability extraction steps in sequence. Run after /scan completes.
tools: ['read', 'edit']
---

Initialize and run the brownfield discovery pipeline.

## Pre-flight

1. Read `project.json`. If it doesn't exist: "project.json not found. Run `/init` first."
2. If `approach` is not `"brownfield"`: "Discovery pipeline requires brownfield approach. Current: {approach}. For greenfield, use `/spec`."
3. Check `.discovery/context.json` exists. If not: "context.json not found. Run `/scan` first."

## Initialize or resume lock file

Check if `.discovery/pipeline.lock.json` exists.

**If it does not exist**, create it now:

```json
{
  "version": "1",
  "started_at": "<current UTC timestamp as YYYY-MM-DDTHH:MM:SSZ>",
  "steps": {
    "seed_candidates":    {"status": "pending", "output": "docs/discovery/candidates.md"},
    "analyze_candidates": {"status": "pending", "output": "docs/discovery/analysis.md"},
    "verify_coverage":    {"status": "pending", "output": "docs/discovery/coverage.md"},
    "lock_l1":            {"status": "pending", "output": "docs/discovery/l1-capabilities.md"},
    "define_l2":          {"status": "pending", "output": "docs/discovery/l2-capabilities.md"},
    "discovery_domain":   {"status": "pending", "output": "docs/discovery/domain-model.md"},
    "blueprint_comparison": {"status": "pending", "output": "docs/discovery/blueprint-comparison.md"}
  }
}
```

**If the lock file already exists**, read it and say "Resuming discovery pipeline (started {started_at})..."

## Apply skip-if-exists

For each step whose output file already exists and is non-empty, update its status to `"skipped"` in the lock file before running the pipeline.

## Run the pipeline

Immediately use the `run-discovery-pipeline` skill to execute all pending steps in sequence.
Do NOT wait for user confirmation before starting.

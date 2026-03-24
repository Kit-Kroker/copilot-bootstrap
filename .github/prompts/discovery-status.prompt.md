---
name: discovery-status
description: Show the brownfield discovery pipeline progress — each of the 7 output files, completion status, and summary statistics.
agent: agent
tools: ['read']
---

Read `.project/state/workflow.json`, `.project/state/answers.json`, and `project.json`.

Verify that `project.json → approach = "brownfield"`. If not, report: "This project is not using the brownfield approach. Discovery status is only available for brownfield projects."

Check which discovery output files exist:
- `docs/discovery/candidates.md` — A1: Seed Candidates
- `docs/discovery/analysis.md` — A2: Analyze Candidates
- `docs/discovery/coverage.md` — A3: Verify Coverage
- `docs/discovery/l1-capabilities.md` — A4: Lock L1
- `docs/discovery/l2-capabilities.md` — A5: Define L2
- `docs/discovery/domain-model.md` — A6: Domain Model
- `docs/discovery/blueprint-comparison.md` — A7: Blueprint Comparison

For each existing file, extract key statistics:
- `candidates.md`: total candidates, HIGH/MEDIUM/LOW counts
- `analysis.md`: confirmed/split/merge/de-scope/flag counts
- `coverage.md`: coverage percentage, orphan count
- `l1-capabilities.md`: total L1 count
- `l2-capabilities.md`: total L2 count
- `blueprint-comparison.md`: aligned/org-specific/missing counts

Print a concise status report:

```
Discovery Pipeline Status
─────────────────────────
Current step:  {step}
Codebase:      {codebase_setup.path}
Language:      {codebase_setup.language}
Architecture:  {codebase_setup.architecture}

Pipeline Progress:
  {✅/❌} A1: Seed Candidates      → candidates.md       {stats if exists}
  {✅/❌} A2: Analyze Candidates   → analysis.md         {stats if exists}
  {✅/❌} A3: Verify Coverage      → coverage.md         {stats if exists}
  {✅/❌} A4: Lock L1              → l1-capabilities.md  {stats if exists}
  {✅/❌} A5: Define L2            → l2-capabilities.md  {stats if exists}
  {✅/❌} A6: Domain Model         → domain-model.md     {stats if exists}
  {✅/❌} A7: Blueprint Comparison → blueprint-comparison.md {stats if exists}

Progress: {completed}/{total} steps complete

Next action:
  {what should happen next based on the current step}
```

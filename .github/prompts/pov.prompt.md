---
name: pov
description: Print the Proof of Value plan and go/no-go criteria. Useful during PoV execution to keep the team aligned on what is being validated and what the thresholds are.
agent: agent
tools: ['read']
---

Read `docs/spec/pov-plan.md`.

If the file does not exist, tell the user:
```
PoV plan has not been generated yet.
Run the ADLC workflow to generate it, or check /adlc-status for progress.
```

If the file exists, print its contents with emphasis on:

1. **PoV Objective** — the assumption being tested
2. **Go/No-Go Gate Criteria** — the exact thresholds
3. **PoV Execution Checklist** — what has been done and what remains

Format the output for quick scanning — use the checklist format and highlight the thresholds.

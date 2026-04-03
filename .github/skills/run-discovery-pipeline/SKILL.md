---
name: run-discovery-pipeline
description: Run the full brownfield discovery pipeline (A1–A7) automatically without manual next commands. Executes all 7 steps in sequence, skipping steps whose output already exists. Use this after /scan when approach is brownfield.
user-invocable: true
---

# Skill Instructions

Run the full brownfield capability extraction pipeline automatically.
Do NOT wait for user confirmation between steps unless a step requires interactive input.

## Pre-flight

1. Verify `project.json → approach = "brownfield"`.
2. Read `.discovery/context.json`. If missing, tell the user to run `/scan` first and stop. Use this file as the source of truth for codebase path, language, architecture, and database presence.
3. Check if `.discovery/pipeline.lock.json` already exists.
   - If it exists, read it and resume from the first non-completed step.
   - If it does not exist, tell the user to run `/discover` first to initialize the pipeline, then stop.
4. Read `.discovery/pipeline.lock.json` to identify which steps are pending.

Say: "Running brownfield discovery..."

## Pipeline Execution

Execute each step listed in the table below, in order, from top to bottom.

For each step:
1. Read `.discovery/pipeline.lock.json`. If the step status is `"completed"` or `"skipped"`, print `"  ✔ {output file} already exists — skipping"` and move to the next step immediately.
2. Mark the step as `"in_progress"` in `.discovery/pipeline.lock.json`.
3. Run the corresponding skill listed in the table.
4. On success:
   - Mark the step as `"completed"` in `.discovery/pipeline.lock.json` with `completed_at` set to the current UTC timestamp.
   - Update `.project/state/workflow.json → step` to the **next** step name (not `prd` yet).
   - Print `"  ✔ {display label}"`.
   - Continue immediately to the next step — do NOT call `bootstrap-next` or wait for user input.
5. On failure:
   - Mark the step as `"failed"` in `.discovery/pipeline.lock.json` with an `error` field describing what went wrong.
   - Print `"  ✗ {display label} — {error summary}"`.
   - STOP. Do not continue to the next step.
   - Tell the user what failed and how to fix it, then re-run this skill to resume.

| Step | Skill | Output | Display Label |
|------|-------|--------|---------------|
| `seed_candidates` | `discover-candidates` | `docs/discovery/candidates.md` | Capability candidates extracted |
| `analyze_candidates` | `analyze-candidates` | `docs/discovery/analysis.md` | Candidates analyzed |
| `verify_coverage` | `verify-coverage` | `docs/discovery/coverage.md` | Coverage verified |
| `lock_l1` | `lock-l1` | `docs/discovery/l1-capabilities.md` | L1 capabilities locked |
| `define_l2` | `define-l2` | `docs/discovery/l2-capabilities.md` | L2 sub-capabilities defined |
| `discovery_domain` | `generate-discovery-domain` | `docs/discovery/domain-model.md` | Domain model built |
| `blueprint_comparison` | `compare-blueprint` | `docs/discovery/blueprint-comparison.md` | Blueprint comparison complete |

## Updating the Lock File

After each state change, edit `.discovery/pipeline.lock.json` directly.

Mark in_progress:
```json
{ "status": "in_progress" }
```

Mark completed:
```json
{ "status": "completed", "output": "docs/discovery/{file}.md", "completed_at": "{ISO timestamp}" }
```

Mark failed:
```json
{ "status": "failed", "output": "docs/discovery/{file}.md", "error": "{error description}" }
```

## Interactive Fallback

If any step reveals ambiguous information that requires user clarification:
- Ask the question directly in the chat
- Wait for the user's response
- Incorporate the answer and continue with the pipeline
- Do NOT abandon the pipeline on interactive prompts

Examples of when to ask:
- A capability candidate spans two domains and the boundary is unclear
- Architecture pattern is ambiguous and affects capability grouping

## After All Steps Complete

1. Update `.project/state/workflow.json`:
   ```json
   { "step": "prd", "status": "in_progress" }
   ```
2. Update `project.json → step` to `"prd"`.
3. Print the completion summary:

```
Discovery pipeline finished.

  ✔ Capability candidates extracted
  ✔ Candidates analyzed
  ✔ Coverage verified
  ✔ L1 capabilities locked
  ✔ L2 sub-capabilities defined
  ✔ Domain model built
  ✔ Blueprint comparison complete

7 artifacts generated in docs/discovery/. Ready for PRD generation.
```

4. Tell the user: "Run `/generate` to produce the project specification documents."

## Rules

- Read pipeline.lock.json before starting to resume from the first non-completed step
- Never re-run a step that is `"completed"` or `"skipped"`
- Stop immediately on failure — log the error, update the lock, do not continue
- Update pipeline.lock.json after every state change (in_progress → completed or failed)
- Do not modify the target codebase — this pipeline is read-only on the analyzed code
- Do not call `bootstrap-next` between steps — this skill manages workflow state directly

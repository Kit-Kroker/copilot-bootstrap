---
name: scan-codebase
description: Run pre-discovery codebase scan to auto-detect stack, tools, and architecture. Produces .discovery/*.json before codebase_setup. Use this as the first step in brownfield bootstrap.
argument-hint: "[codebase_path — optional override; defaults to project.json → codebase_path]"
---

# Skill Instructions

Run the codebase scanner to auto-detect stack, tools, and architecture before asking the user questions.

## When to use

Use this skill at the start of a brownfield bootstrap, before `codebase_setup`.
The scan populates `.discovery/` so `codebase_setup` can skip questions that were auto-detected with high confidence.

## Steps

### 1. Verify codebase path

Read `project.json`. Check that `codebase_path` is set and points to an existing directory.

If `codebase_path` is empty or not set:
- Ask the user: "What is the path to the existing codebase?"
- Save the answer to `project.json → codebase_path`

### 2. Run the scanner

Run:
```
copilot-bootstrap scan
```

Or if the codebase path is being overridden:
```
copilot-bootstrap scan <codebase_path>
```

Wait for the command to complete. It produces:
- `.discovery/fs.json` — filesystem scan
- `.discovery/stack.json` — language, framework, DB
- `.discovery/tools.json` — toolchain
- `.discovery/arch.json` — architecture style
- `.discovery/context.json` — unified context
- `.discovery/confidence.json` — detection confidence scores

### 3. Review the results

Read `.discovery/context.json` and `.discovery/confidence.json`.

Present a summary to the user in this format:

```
Scan complete. Here's what I detected:

Stack:
  Languages:    <languages>
  Frontend:     <frontend or "none">
  Backend:      <backend or "none">
  Database:     <db or "none">
  Architecture: <style>

Tools:
  Package manager: <pm>
  Test runner:     <test_runner>
  Linter:          <linter>
  Container:       <container>

Confidence scores:
  language:     <score>
  frontend:     <score>
  backend:      <score>
  db:           <score>
  architecture: <score>
  entrypoints:  <score>
```

### 4. Handle low-confidence detections

For each field in `confidence.json` with a score between 0.50 and 0.74:
- Show the detected value
- Ask the user to confirm: "I detected `<value>` for `<field>`. Is that correct?"
- If the user corrects it, update the relevant field in `.discovery/context.json`

For each field with a score below 0.50 (or 0.0):
- Ask the user directly: "What is the `<field>` for this project?"
- Update `.discovery/context.json` with the answer

### 5. Persist corrections

After the user confirms or corrects values, save the final context by updating
`.discovery/context.json` and setting the relevant confidence scores to `1.0`
for all user-confirmed fields.

### 6. Handoff to codebase_setup

After the scan and confirmation are complete, the bootstrap flow continues
to `codebase_setup`, which will read `.discovery/context.json` and skip
questions for fields that were already confirmed.

## Confidence threshold reference

| Score | Meaning | Action |
|-------|---------|--------|
| ≥ 0.75 | High confidence | Use as default, do not ask |
| 0.50–0.74 | Medium confidence | Show detected value, ask to confirm |
| < 0.50 | Low confidence | Ask normally |
| 0.0 | Not detected | Ask normally |

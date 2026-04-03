---
name: generate-brownfield-hooks
description: Configure Claude Code hooks in .claude/settings.json for a brownfield project. Generates PostToolUse hooks for the detected linter, formatter, and test runner so they run automatically after code edits.
---

# Skill Instructions

Configure hooks in `.claude/settings.json` based on the detected tools in `.discovery/context.json`.

## Read inputs

- `.discovery/context.json` — tools: linter, formatter, test_runner, package_manager
- `project.json` — name
- `.claude/settings.json` — read current contents if it exists (to merge, not overwrite)

## Hook strategy

Hooks run automatically after Claude edits files. Generate hooks only for tools that are detected (confidence ≥ 0.50 in `.discovery/confidence.json` if present, otherwise use presence in `context.json → tools` as the signal).

### PostToolUse hooks to generate

| Tool | Trigger condition | Command |
|---|---|---|
| Linter | `linter` is not null | Run linter on the edited file |
| Formatter | `formatter` is not null | Run formatter on the edited file |

Do NOT add a test runner hook — tests should be explicit, not automatic.

### Linter commands by tool

| Linter | Command |
|--------|---------|
| `eslint` | `npx eslint --fix {file}` |
| `ruff` | `ruff check --fix {file}` |
| `pylint` | `pylint {file}` |
| `golangci-lint` | `golangci-lint run {file}` |
| `checkstyle` | (skip — requires build integration, flag to user instead) |
| `clippy` | `cargo clippy --fix {file}` |

### Formatter commands by tool

| Formatter | Command |
|-----------|---------|
| `prettier` | `npx prettier --write {file}` |
| `black` | `black {file}` |
| `isort` | `isort {file}` |
| `gofmt` | `gofmt -w {file}` |
| `rustfmt` | `rustfmt {file}` |

## Output: `.claude/settings.json`

Merge the hooks into the existing settings file. If the file doesn't exist, create it.

Structure:
```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "<linter command with {file} replaced by the actual file path variable>"
          }
        ]
      }
    ]
  }
}
```

**Important**: In Claude Code hooks, use `$CLAUDE_FILE_PATHS` as the environment variable for the edited file path, not `{file}`. Example:
```json
{ "type": "command", "command": "npx eslint --fix $CLAUDE_FILE_PATHS" }
```

Only include hooks for tools that are actually detected. If neither linter nor formatter is detected, write an empty hooks object and note it.

## After writing

If hooks were added:
```
  ✔ .claude/settings.json — {N} hooks configured
     - PostToolUse: {linter} on Edit/Write
     - PostToolUse: {formatter} on Edit/Write
```

If no tools detected:
```
  ✔ .claude/settings.json — no linter or formatter detected, hooks skipped
```

If checkstyle was detected:
```
  ⚠  checkstyle detected but skipped — requires build integration. Add manually if needed.
```

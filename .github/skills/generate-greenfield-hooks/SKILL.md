---
name: generate-greenfield-hooks
description: Configure VS Code workspace settings in .vscode/settings.json for a greenfield project. Enables format-on-save and linter integration for the chosen stack so the IDE enforces conventions automatically.
---

# Skill Instructions

Configure `.vscode/settings.json` based on the tools in `.greenfield/context.json`.

## Read inputs

- `.greenfield/context.json` — tools: linter, formatter, test_runner, package_manager, stack
- `project.json` — name
- `.vscode/settings.json` — read current contents if it exists (to merge, not overwrite)

## Settings strategy

Generate only settings for tools that are actually present in `context.json → tools`.

### Format-on-save

If `formatter` is detected, enable:
```json
"editor.formatOnSave": true
```

And set the default formatter per language:

| Formatter | Language IDs | VS Code setting |
|-----------|-------------|-----------------|
| `prettier` | javascript, typescript, json, css, html | `"editor.defaultFormatter": "esbenp.prettier-vscode"` |
| `black` | python | `"editor.defaultFormatter": "ms-python.black-formatter"` |
| `isort` | python | add `"editor.codeActionsOnSave": {"source.organizeImports": "explicit"}` |
| `gofmt` | go | `"editor.defaultFormatter": "golang.go"` (gofmt is built in) |
| `rustfmt` | rust | `"editor.defaultFormatter": "rust-lang.rust-analyzer"` |

### Linter integration

If `linter` is detected:

| Linter | Setting |
|--------|---------|
| `eslint` | `"eslint.enable": true`, `"editor.codeActionsOnSave": {"source.fixAll.eslint": "explicit"}` |
| `ruff` | `"ruff.enable": true`, `"ruff.fixAll": true` |
| `pylint` | `"pylint.enabled": true` |
| `golangci-lint` | `"go.lintTool": "golangci-lint"`, `"go.lintOnSave": "file"` |
| `clippy` | `"rust-analyzer.check.command": "clippy"` |

### Language-specific extras

If `stack.languages[0]` is Python, also add:
```json
"python.languageServer": "Pylance"
```

If `stack.languages[0]` is Go, also add:
```json
"go.formatTool": "goimports"
```

## Output: `.vscode/settings.json`

Merge the generated settings into the existing file. If the file doesn't exist, create it.

Structure (example for a TypeScript/eslint/prettier project):
```json
{
  "editor.formatOnSave": true,
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "eslint.enable": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit"
  }
}
```

Use language-scoped keys (`"[python]"`, `"[typescript]"`, etc.) for formatter and codeAction settings to avoid conflicts with other language settings.

Only include settings for tools that are actually present. If neither linter nor formatter is detected, write a minimal valid JSON object and note it.

## After writing

If settings were added:
```
  ✔ .vscode/settings.json — workspace settings configured
     - format-on-save: {formatter}
     - linter: {linter}
```

If no tools detected:
```
  ✔ .vscode/settings.json — no linter or formatter configured, minimal settings written
```

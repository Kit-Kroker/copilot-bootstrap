---
name: generate-brownfield-prompts
description: Generate project-specific slash command prompts for a brownfield project. Reads discovery outputs to produce .github/prompts/ files for the most common operations on this specific codebase — tailored to its stack, domain, and capability structure.
---

# Skill Instructions

Generate `.github/prompts/` files for the brownfield project. Each prompt is a slash command the team can invoke directly in chat. All prompts must be specific to this codebase — not generic.

## Read inputs

- `.discovery/context.json` — stack, tools, architecture
- `project.json` — name, type, domain
- `docs/discovery/l1-capabilities.md` — capabilities
- `docs/discovery/domain-model.md` — entities and their code locations

## Always generate these prompts

### `status.prompt.md`
Shows the current state of the project's key capabilities — reads discovery outputs and surfaces any gaps or issues.

### `review-code.prompt.md`
Reviews changed code for correctness, test coverage, and adherence to the project's conventions (derived from the detected stack and domain model). Include stack-specific checks:
- For typed languages: check type safety
- For ORM-based projects: check for N+1 queries, missing indexes
- For API projects: check request validation, error response shapes
- For frontend: check component composition, accessibility

### `explain-capability.prompt.md`
Takes a capability name (from L1 list) and explains: what it does, which files implement it, which entities it owns, and how it connects to other capabilities. Reads from `docs/discovery/`.

### `trace-flow.prompt.md`
Takes an entry point (API endpoint, UI action, CLI command) and traces it through the codebase layers — from handler to service to persistence. Uses code locations from `docs/discovery/l2-capabilities.md`.

## Stack-conditional prompts

Generate these only when the matching condition is true:

| Condition | Prompt | Purpose |
|---|---|---|
| db detected | `add-migration.prompt.md` | Guide through writing and applying a schema migration using the detected tool |
| frontend present | `review-component.prompt.md` | Review a UI component for props contract, state management, accessibility |
| test_runner detected | `run-tests.prompt.md` | Run the test suite for a specific capability or file; report failures with context |
| linter detected | `lint-fix.prompt.md` | Run linter on changed files and auto-fix what can be fixed; report what needs manual attention |
| backend = spring-boot or nestjs or django | `add-integration-test.prompt.md` | Add an integration test for a service or controller using the project's testing conventions |

## Capability-derived prompts

For the top 3 HIGH-confidence L1 capabilities (by code coverage from `docs/discovery/analysis.md`), generate one prompt each:

Format: `{capability-slug}.prompt.md`

Content: A prompt that helps a developer work within that capability — what files to read, what patterns to follow, what to check before committing changes.

## Output format per prompt

```markdown
---
name: {prompt-name}
description: {one sentence describing what this prompt does and when to use it}
---

{Instructions written directly to the AI — imperative, specific to the project}

## Read
- {exact files to read}

## Do
{2–5 bullet points of what the AI should do}

## Output
{What the AI should produce or say}
```

## Rules

- Use actual entity names, file paths (from `context.json → paths`), and tool names throughout
- Do not write generic prompts — every prompt must reference something specific about this project
- Maximum 10 prompts total — prefer fewer, high-quality prompts over many vague ones

## After writing

Print:
```
  ✔ .github/prompts/ — {N} prompts generated
     {list each prompt name, prefixed with "     - "}
```

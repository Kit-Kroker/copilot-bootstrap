---
name: generate-greenfield-prompts
description: Generate project-specific slash command prompts for a greenfield project. Reads spec outputs to produce .github/prompts/ files for the most common operations on this specific codebase — tailored to its stack, domain, and capabilities.
---

# Skill Instructions

Generate `.github/prompts/` files for the greenfield project. Each prompt is a slash command the team can invoke directly in chat. All prompts must be specific to this project — not generic.

## Read inputs

- `.greenfield/context.json` — stack, tools, architecture
- `project.json` — name, type, domain
- `docs/analysis/capabilities.md` — capabilities
- `docs/domain/model.md` — entities and their relationships
- `docs/spec/api.md` — API spec (if present)

## Always generate these prompts

### `status.prompt.md`
Shows the current state of the project's implementation — what has been scaffolded, what is still pending, what tests are passing. References the capabilities from `docs/analysis/capabilities.md`.

### `review-code.prompt.md`
Reviews changed code for correctness, test coverage, and adherence to the project's conventions. Include stack-specific checks:
- For typed languages: check type safety
- For ORM-based projects: check for N+1 queries, missing indexes
- For API projects: check request validation, error response shapes
- For frontend: check component composition, accessibility

### `implement-capability.prompt.md`
Takes a capability name (from capabilities list) and implements it end-to-end: what files to create, what patterns to follow, what tests to write. Reads from `docs/analysis/capabilities.md` and `docs/domain/model.md`.

### `scaffold-feature.prompt.md`
Takes a feature description and scaffolds all required layers for this stack (e.g., handler → service → repository for a REST API; component → page → data hook for a web app). References domain model for entity naming conventions.

## Stack-conditional prompts

Generate these only when the matching condition is true:

| Condition | Prompt | Purpose |
|---|---|---|
| db detected | `add-migration.prompt.md` | Guide through writing and applying a schema migration using the detected tool |
| frontend present | `review-component.prompt.md` | Review a UI component for props contract, state management, accessibility |
| test_runner detected | `run-tests.prompt.md` | Run the test suite for a specific capability or file; report failures with context |
| linter detected | `lint-fix.prompt.md` | Run linter on changed files and auto-fix what can be fixed; report what needs manual attention |
| `docs/spec/api.md` present | `implement-endpoint.prompt.md` | Implement a specific API endpoint from the spec: route, handler, service, validation, test |

## Capability-derived prompts

For the top 3 capabilities in `docs/analysis/capabilities.md` (by listed priority or order), generate one prompt each:

Format: `{capability-slug}.prompt.md`

Content: A prompt that helps a developer implement or work within that capability — what files to read, what patterns to follow, what entities are involved.

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

---
name: generate-stack-skills
description: Generate stack-specific procedural skills for a modernization project. Reads the detected stack and discovered domain to produce SKILL.md files under .github/skills/ that tell Copilot exactly how to implement, refactor, and document code in this project's specific technology stack.
argument-hint: "[skill name to generate, or leave blank for all]"
---

# Skill Instructions

Generate `.github/skills/` files for stack-specific modernization tasks. Each skill must contain clear, imperative instructions that tell Copilot to **perform** the work — write the code, apply the refactor, generate the documentation. No analysis-only or describe-only skills.

## Read inputs

- `.discovery/context.json` — stack (languages, backend, frontend, db), tools (linter, formatter, test_runner), paths
- `docs/discovery/l1-capabilities.md` — capability names and code locations
- `docs/discovery/domain-model.md` — entity names, file paths, naming conventions in use
- `.github/copilot-instructions.md` — project-wide conventions already in place (do not duplicate)

## Skills to generate

### Always generate

#### `implement-feature`
Implement a complete feature end-to-end in this stack. The skill must tell Copilot to:
- Read the relevant capability section from `docs/discovery/domain-model.md`
- Write all required layers for this stack (e.g., handler → service → repository for a Go/Gin project; view → serializer → service for Django)
- Apply naming conventions derived from existing code in `context.json → paths.src`
- Write tests using the detected test runner covering the new logic
- Run the linter/formatter on every file written

#### `fix-bug`
Diagnose and fix a reported bug. The skill must tell Copilot to:
- Read the failing test or error message provided as the argument
- Locate the relevant code using `docs/discovery/l2-capabilities.md` as a map
- Apply a minimal targeted fix — do not refactor unrelated code
- Write or update a test that would have caught this bug
- Confirm the fix compiles/parses cleanly and the linter passes

#### `write-docs`
Write technical documentation for a module, function, or capability. The skill must tell Copilot to:
- Read the target file(s) to understand the existing code
- Write documentation in the idiomatic style for the detected language (godoc for Go, docstrings for Python, JSDoc for TypeScript/JavaScript, Javadoc for Java)
- Cover: purpose, parameters, return values, error conditions, and usage example
- Do not change any logic — documentation only

### Stack-conditional skills

**If `stack.languages[0]` = go:**

#### `modernize-go-handler`
Refactor a legacy HTTP handler to idiomatic Go. The skill must tell Copilot to:
- Read the target handler file
- Replace raw `net/http` patterns with the detected router (gin/echo/chi/fiber) conventions
- Extract business logic into a service function; keep the handler thin (parse input → call service → write response)
- Add `context.Context` propagation if missing
- Write a table-driven test using `t.Run` for the refactored handler
- Run `gofmt -s` and `go vet ./...` on the result

**If `stack.languages[0]` = python:**

#### `modernize-python-module`
Refactor a legacy Python module to modern typed Python. The skill must tell Copilot to:
- Read the target module
- Add type annotations to all function signatures using the types already present in the file or project
- Replace bare `except:` with specific exception types
- Replace `dict`/`list` usage in type hints with `dict[K, V]` / `list[T]` (Python 3.10+ style)
- Apply the detected formatter (`black`/`ruff`) conventions to the output
- Update or add docstrings in Google/NumPy/Sphinx style (derive from existing docstrings in the project)

**If `stack.languages[0]` = typescript or javascript:**

#### `modernize-js-module`
Refactor a legacy JavaScript/TypeScript module to modern standards. The skill must tell Copilot to:
- Read the target file
- Convert CommonJS `require` to ES module `import`/`export` if the project uses ESM
- Replace `var` with `const`/`let`; replace `.then()`/`.catch()` chains with `async`/`await`
- Add TypeScript types to untyped function signatures if the project uses TypeScript
- Run `eslint --fix` on the output using the detected ESLint config

**If `stack.languages[0]` = java:**

#### `modernize-java-class`
Refactor a legacy Java class to modern Java and the detected framework. The skill must tell Copilot to:
- Read the target class
- Replace the detected legacy pattern (e.g., Java EE Servlet → Spring Boot `@RestController`, EJB → Spring `@Service`, JPA XML config → annotation-based)
- Use constructor injection instead of field injection (`@Autowired` on fields)
- Replace checked exceptions with runtime exceptions where appropriate for the project style
- Write a unit test using JUnit 5 and Mockito for the refactored class

**If frontend is present (react / vue / angular / svelte):**

#### `modernize-component`
Refactor a legacy frontend component to the current framework conventions. The skill must tell Copilot to:
- Read the target component file
- For React: convert class components to function components with hooks; replace lifecycle methods with `useEffect`
- For Vue: convert Options API to Composition API using `<script setup>`
- For Angular: apply standalone component pattern if the project uses Angular 14+
- Preserve all existing props, events, and slot contracts — do not change the component's external API
- Write a component test using the detected test runner (jest/vitest + testing-library)

**If db is detected:**

#### `add-migration`
Write and apply a database migration. The skill must tell Copilot to:
- Read `docs/discovery/domain-model.md` to identify the affected entity and its table
- Write the migration file in the detected tool's format (alembic, flyway, liquibase, golang-migrate, prisma migrate, knex)
- Include both up and down migrations
- Place the file in the correct directory per the project's existing migration structure (derive path from `context.json → paths`)
- Do not modify any application code — migration only

## Output format per skill

```markdown
---
name: {skill-name}
description: {one sentence: what this skill does and what it produces}
argument-hint: "{what to pass — file path, entity name, error message, etc.}"
---

# Skill Instructions

**Read these files before writing anything:**
- {exact file paths from context.json → paths}
- {discovery docs if relevant}

**Do this:**
{Imperative steps — each step starts with a verb: Read / Write / Replace / Add / Run / Apply. No passive voice.}

1. {action}
2. {action}
3. {action}

**Requirements — apply to every file you write or modify:**
- Language: {from context.json → stack.languages[0]} — follow conventions in `.github/copilot-instructions.md`
- Framework: {from context.json → stack.backend or frontend}
- Test runner: {from context.json → tools.test_runner} — write tests, do not skip
- Formatter: run {formatter} on every file before finishing
- Linter: the output must pass {linter} with zero errors

**Done when:**
- All required files are written or modified
- Tests are written and pass
- Linter reports zero errors on changed files
```

## Rules

- Every skill must start with a **Read** step — Copilot must read existing code before writing
- Every skill must end with a **Done when** checklist so Copilot knows when to stop
- Use actual entity names from `domain-model.md`, actual paths from `context.json`, actual tool names from `tools`
- Do not generate a skill for a tool or language not present in `context.json`
- Do not duplicate skills already generated by `generate-brownfield-skills` (check `.github/skills/` first)
- Maximum 10 skills — prefer fewer high-quality skills over many vague ones

## After writing

Print:
```
  ✔ .github/skills/ — {N} stack skills generated
     {list each skill name on its own line, prefixed with "     - "}
```

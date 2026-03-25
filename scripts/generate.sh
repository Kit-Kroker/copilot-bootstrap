#!/bin/sh
# generate.sh — Generator orchestrator
#
# Reads context from .greenfield/ (greenfield) or .discovery/ (brownfield)
# and produces project-specific Copilot configuration artifacts.
#
# Usage: copilot-bootstrap generate [generator] [--force]
#        copilot-bootstrap generate status

set -e

TEMPLATES_DIR="${COPILOT_BOOTSTRAP_HOME}/templates"

# ── Context directory detection ───────────────────────────────────────────────

CONTEXT_DIR=""
APPROACH=""
if [ -f ".greenfield/context.json" ]; then
  CONTEXT_DIR=".greenfield"
  APPROACH="greenfield"
elif [ -f ".discovery/context.json" ]; then
  CONTEXT_DIR=".discovery"
  APPROACH="brownfield"
fi

CONTEXT_FILE="$CONTEXT_DIR/context.json"
LOCK_FILE="$CONTEXT_DIR/generators.lock.json"
DECISIONS_FILE="$CONTEXT_DIR/decisions.json"
SCOPE_FILE="$CONTEXT_DIR/scope.json"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap generate [generator] [--force]"
  echo ""
  echo "Produces project-specific Copilot configuration from context outputs."
  echo "Reads .greenfield/context.json (greenfield) or .discovery/context.json (brownfield)."
  echo ""
  echo "Generators (run in order):"
  echo "  instructions  → .github/copilot-instructions.md + .github/instructions/"
  echo "  agents        → .github/agents/"
  echo "  skills        → .github/skills/"
  echo "  prompts       → .github/prompts/"
  echo "  mcp           → .vscode/mcp.json"
  echo "  hooks         → .github/hooks/"
  echo "  plugins       → .github/plugins/"
  echo "  docs          → .github/docs/"
  echo ""
  echo "Options:"
  echo "  --force       Re-run even if already completed"
  echo ""
  echo "Subcommands:"
  echo "  status        Show generator progress"
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────────────────────

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

if ! command -v python3 > /dev/null 2>&1; then
  echo "Error: python3 is required."
  exit 1
fi

# ── Subcommand: status ────────────────────────────────────────────────────────

if [ "$1" = "status" ]; then
  if [ -z "$CONTEXT_DIR" ]; then
    echo "No context found. Run 'copilot-bootstrap scan' (brownfield) or"
    echo "'copilot-bootstrap build-context' (greenfield) first."
    exit 1
  fi
  if [ ! -f "$LOCK_FILE" ]; then
    echo "No generator lock found. Run 'copilot-bootstrap generate' first."
    exit 1
  fi
  echo "Generator status ($LOCK_FILE) [$APPROACH]:"
  echo ""
  for gen in instructions agents skills prompts mcp hooks plugins docs; do
    STATUS=$(jq -r --arg g "$gen" '.generators[$g].status // "pending"' "$LOCK_FILE")
    OUTPUTS=$(jq -r --arg g "$gen" '
      .generators[$g].outputs // [] | length
    ' "$LOCK_FILE")
    case "$STATUS" in
      completed) printf "  ✔ %-14s — complete (%s files)\n" "$gen" "$OUTPUTS" ;;
      skipped)   printf "  ✔ %-14s — skipped\n" "$gen" ;;
      in_progress) printf "  … %-14s — in progress\n" "$gen" ;;
      failed)    printf "  ✗ %-14s — failed\n" "$gen" ;;
      *)         printf "  ○ %-14s — pending\n" "$gen" ;;
    esac
  done
  echo ""
  DONE=$(jq '[.generators | to_entries[] | select(.value.status == "completed" or .value.status == "skipped")] | length' "$LOCK_FILE")
  echo "Progress: $DONE/8 generators complete."
  exit 0
fi

# ── Prerequisite checks ───────────────────────────────────────────────────────

if [ -z "$CONTEXT_DIR" ]; then
  echo "Error: no context found."
  echo "For brownfield: run 'copilot-bootstrap scan' first."
  echo "For greenfield: run 'copilot-bootstrap build-context' first."
  exit 1
fi

if [ ! -d "$TEMPLATES_DIR" ]; then
  echo "Error: templates directory not found at $TEMPLATES_DIR"
  echo "Ensure COPILOT_BOOTSTRAP_HOME is set correctly."
  exit 1
fi

# ── Parse arguments ───────────────────────────────────────────────────────────

FORCE="false"
TARGET=""
for arg in "$@"; do
  case "$arg" in
    --force) FORCE="true" ;;
    status) ;;  # handled above
    *) TARGET="$arg" ;;
  esac
done

# ── Setup ─────────────────────────────────────────────────────────────────────

mkdir -p "$CONTEXT_DIR"

NOW=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

init_lock() {
  if [ ! -f "$LOCK_FILE" ]; then
    jq -n --arg ts "$NOW" '{
      "version": "1",
      "started_at": $ts,
      "generators": {
        "instructions": {"status": "pending"},
        "agents":       {"status": "pending"},
        "skills":       {"status": "pending"},
        "prompts":      {"status": "pending"},
        "mcp":          {"status": "pending"},
        "hooks":        {"status": "pending"},
        "plugins":      {"status": "pending"},
        "docs":         {"status": "pending"}
      }
    }' > "$LOCK_FILE"
  fi
}

update_generator() {
  GEN="$1"; STATUS="$2"; shift 2
  if [ "$STATUS" = "completed" ] && [ $# -gt 0 ]; then
    FILES=$(printf '%s\n' "$@" | jq -R . | jq -s .)
    jq --arg g "$GEN" --arg st "$STATUS" --arg ts "$NOW" --argjson files "$FILES" \
      '.generators[$g] = {"status": $st, "completed_at": $ts, "outputs": $files}' \
      "$LOCK_FILE" > /tmp/gen_tmp.json && mv /tmp/gen_tmp.json "$LOCK_FILE"
  else
    jq --arg g "$GEN" --arg st "$STATUS" \
      '.generators[$g].status = $st' \
      "$LOCK_FILE" > /tmp/gen_tmp.json && mv /tmp/gen_tmp.json "$LOCK_FILE"
  fi
}

is_completed() {
  GEN="$1"
  STATUS=$(jq -r --arg g "$GEN" '.generators[$g].status // "pending"' "$LOCK_FILE")
  [ "$STATUS" = "completed" ] || [ "$STATUS" = "skipped" ]
}

# ── Context extraction ────────────────────────────────────────────────────────

extract_context() {
  LANGUAGE=$(jq -r '.stack.languages[0] // "unknown"' "$CONTEXT_FILE")
  LANGUAGES=$(jq -r '[.stack.languages[]?] | join(", ")' "$CONTEXT_FILE")
  FRONTEND=$(jq -r '.stack.frontend // "none"' "$CONTEXT_FILE")
  BACKEND=$(jq -r '.stack.backend // "none"' "$CONTEXT_FILE")
  DB=$(jq -r '.stack.db // "none"' "$CONTEXT_FILE")
  PKG_MANAGER=$(jq -r '.tools.package_manager // "none"' "$CONTEXT_FILE")
  LINTER=$(jq -r '.tools.linter // "none"' "$CONTEXT_FILE")
  FORMATTER=$(jq -r '.tools.formatter // "none"' "$CONTEXT_FILE")
  TEST_RUNNER=$(jq -r '.tools.test_runner // "none"' "$CONTEXT_FILE")
  BUNDLER=$(jq -r '.tools.bundler // "none"' "$CONTEXT_FILE")
  CONTAINER=$(jq -r '.tools.container // "none"' "$CONTEXT_FILE")
  ORCHESTRATOR=$(jq -r '.tools.orchestrator // "none"' "$CONTEXT_FILE")
  ARCH_STYLE=$(jq -r '.arch.style // "unknown"' "$CONTEXT_FILE")
  SRC_PATH=$(jq -r '.paths.src // "src/"' "$CONTEXT_FILE")
  TESTS_PATH=$(jq -r '.paths.tests // "tests/"' "$CONTEXT_FILE")

  # Project name: prefer context.json → project.name, fallback to project.json
  PROJECT_NAME=$(jq -r '.project.name // ""' "$CONTEXT_FILE" 2>/dev/null)
  if [ -z "$PROJECT_NAME" ] || [ "$PROJECT_NAME" = "null" ]; then
    PROJECT_NAME="project"
    if [ -f "project.json" ]; then
      N=$(jq -r '.name // ""' "project.json" 2>/dev/null)
      [ -n "$N" ] && PROJECT_NAME="$N"
    fi
  fi

  # Greenfield-specific: decisions.json rationale
  STACK_RATIONALE=""
  ARCH_RATIONALE=""
  DEFAULTS_APPLIED=""
  COMPLEXITY=""
  if [ "$APPROACH" = "greenfield" ]; then
    if [ -f "$DECISIONS_FILE" ]; then
      LANG_REASON=$(jq -r '.stack_rationale.language.reason // ""' "$DECISIONS_FILE")
      ARCH_REASON=$(jq -r '.arch_rationale.style.reason // ""' "$DECISIONS_FILE")
      DEFAULTS_APPLIED=$(jq -r '.defaults_applied // [] | join(", ")' "$DECISIONS_FILE")
      STACK_RATIONALE="$LANG_REASON"
      ARCH_RATIONALE="$ARCH_REASON"
    fi
    if [ -f "$SCOPE_FILE" ]; then
      COMPLEXITY=$(jq -r '.complexity // "unknown"' "$SCOPE_FILE")
    fi
  fi

  export LANGUAGE LANGUAGES FRONTEND BACKEND DB PKG_MANAGER LINTER FORMATTER \
         TEST_RUNNER BUNDLER CONTAINER ORCHESTRATOR ARCH_STYLE \
         SRC_PATH TESTS_PATH PROJECT_NAME APPROACH \
         STACK_RATIONALE ARCH_RATIONALE DEFAULTS_APPLIED COMPLEXITY
}

# ── Template renderer ─────────────────────────────────────────────────────────

render_template() {
  TMPL="$1"
  OUTPUT="$2"
  if [ ! -f "$TMPL" ]; then
    return 1
  fi
  mkdir -p "$(dirname "$OUTPUT")"
  python3 - "$TMPL" "$OUTPUT" <<'PYEOF'
import sys, os, re
tmpl, out = sys.argv[1], sys.argv[2]
with open(tmpl) as f:
    content = f.read()
def replace_var(m):
    return os.environ.get(m.group(1), m.group(0))
content = re.sub(r'\{\{([A-Z_0-9]+)\}\}', replace_var, content)
os.makedirs(os.path.dirname(out) if os.path.dirname(out) else '.', exist_ok=True)
with open(out, 'w') as f:
    f.write(content)
PYEOF
}

# ── Generator: instructions ───────────────────────────────────────────────────

generate_instructions() {
  OUTPUTS=""
  mkdir -p .github/instructions

  # Project-wide instructions
  TMPL="$TEMPLATES_DIR/instructions/copilot-instructions.md.tmpl"
  OUT=".github/copilot-instructions.md"
  if render_template "$TMPL" "$OUT"; then
    OUTPUTS="$OUTPUTS $OUT"
  fi

  # Language-specific instructions
  for lang in $(jq -r '.stack.languages[]?' "$CONTEXT_FILE"); do
    TMPL="$TEMPLATES_DIR/instructions/language-${lang}.instructions.md.tmpl"
    OUT=".github/instructions/${lang}.instructions.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  done

  # Frontend framework instructions
  if [ "$FRONTEND" != "none" ] && [ "$FRONTEND" != "null" ]; then
    TMPL="$TEMPLATES_DIR/instructions/framework-${FRONTEND}.instructions.md.tmpl"
    OUT=".github/instructions/${FRONTEND}.instructions.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # Backend framework instructions
  if [ "$BACKEND" != "none" ] && [ "$BACKEND" != "null" ]; then
    TMPL="$TEMPLATES_DIR/instructions/framework-${BACKEND}.instructions.md.tmpl"
    OUT=".github/instructions/${BACKEND}.instructions.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # Architecture instructions
  if [ "$ARCH_STYLE" != "unknown" ] && [ "$ARCH_STYLE" != "null" ]; then
    TMPL="$TEMPLATES_DIR/instructions/architecture-${ARCH_STYLE}.instructions.md.tmpl"
    OUT=".github/instructions/architecture.instructions.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # Greenfield-specific: decisions instructions (explains rationale for chosen stack)
  if [ "$APPROACH" = "greenfield" ] && [ -f "$DECISIONS_FILE" ]; then
    OUT=".github/instructions/decisions.instructions.md"
    python3 - "$DECISIONS_FILE" "$OUT" <<'PYEOF'
import sys, os, json

decisions_path, out_path = sys.argv[1], sys.argv[2]
project_name = os.environ.get('PROJECT_NAME', 'project')
language = os.environ.get('LANGUAGE', 'unknown')
frontend = os.environ.get('FRONTEND', 'none')
backend = os.environ.get('BACKEND', 'none')
arch_style = os.environ.get('ARCH_STYLE', 'unknown')
defaults_applied = os.environ.get('DEFAULTS_APPLIED', '')

with open(decisions_path) as f:
    d = json.load(f)

lines = [
    '---',
    'name: stack decisions',
    f'description: Stack rationale and conventions for {project_name}',
    'applyTo: \'**/*\'',
    '---',
    '',
    '# Stack Decisions',
    '',
    f'This file explains why the **{project_name}** stack was chosen.',
    'Copilot should maintain consistency with these decisions.',
    '',
    '## Stack Rationale',
    '',
]

sr = d.get('stack_rationale', {})
for key, val in sr.items():
    if isinstance(val, dict):
        choice = val.get('choice', '')
        source = val.get('source', '')
        reason = val.get('reason', '')
        if choice:
            lines.append(f'- **{key}**: `{choice}` ({source}) — {reason}')

tr = d.get('tools_rationale', {})
if tr:
    lines += ['', '## Toolchain Rationale', '']
    for key, val in tr.items():
        if isinstance(val, dict):
            choice = val.get('choice', '')
            source = val.get('source', '')
            reason = val.get('reason', '')
            if choice:
                lines.append(f'- **{key}**: `{choice}` ({source}) — {reason}')

ar = d.get('arch_rationale', {})
if ar:
    lines += ['', '## Architecture Rationale', '']
    for key, val in ar.items():
        if isinstance(val, dict):
            choice = val.get('choice', '')
            source = val.get('source', '')
            reason = val.get('reason', '')
            if choice:
                lines.append(f'- **{key}**: `{choice}` ({source}) — {reason}')

if defaults_applied:
    lines += [
        '',
        '## Smart Defaults Applied',
        '',
        f'The following tools were set automatically based on the chosen stack: {defaults_applied}.',
        'These can be changed in `.greenfield/context.json` and re-running `copilot-bootstrap generate --force`.',
    ]

lines.append('')
os.makedirs(os.path.dirname(out_path) if os.path.dirname(out_path) else '.', exist_ok=True)
with open(out_path, 'w') as f:
    f.write('\n'.join(lines))
PYEOF
    OUTPUTS="$OUTPUTS $OUT"
  fi

  # shellcheck disable=SC2086
  update_generator "instructions" "completed" $OUTPUTS
}

# ── Generator: agents ─────────────────────────────────────────────────────────

generate_agents() {
  OUTPUTS=""
  mkdir -p .github/agents

  # Always: test + refactor agents
  for agent in test refactor; do
    TMPL="$TEMPLATES_DIR/agents/${agent}.agent.md.tmpl"
    OUT=".github/agents/${agent}.agent.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  done

  # Backend agent if backend detected
  if [ "$BACKEND" != "none" ] && [ "$BACKEND" != "null" ]; then
    TMPL="$TEMPLATES_DIR/agents/backend.agent.md.tmpl"
    OUT=".github/agents/backend.agent.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # Frontend agent if frontend detected
  if [ "$FRONTEND" != "none" ] && [ "$FRONTEND" != "null" ]; then
    TMPL="$TEMPLATES_DIR/agents/frontend.agent.md.tmpl"
    OUT=".github/agents/frontend.agent.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # DevOps agent if container detected
  if [ "$CONTAINER" != "none" ] && [ "$CONTAINER" != "null" ]; then
    TMPL="$TEMPLATES_DIR/agents/devops.agent.md.tmpl"
    OUT=".github/agents/devops.agent.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # Greenfield-specific: scaffold agent
  if [ "$APPROACH" = "greenfield" ]; then
    TMPL="$TEMPLATES_DIR/agents/scaffold.agent.md.tmpl"
    OUT=".github/agents/scaffold.agent.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # shellcheck disable=SC2086
  update_generator "agents" "completed" $OUTPUTS
}

# ── Generator: skills ─────────────────────────────────────────────────────────

generate_skills() {
  OUTPUTS=""

  # Build skill if bundler detected
  if [ "$BUNDLER" != "none" ] && [ "$BUNDLER" != "null" ]; then
    TMPL="$TEMPLATES_DIR/skills/build/SKILL.md.tmpl"
    OUT=".github/skills/build/SKILL.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # Test skill if test runner detected
  if [ "$TEST_RUNNER" != "none" ] && [ "$TEST_RUNNER" != "null" ]; then
    TMPL="$TEMPLATES_DIR/skills/test/SKILL.md.tmpl"
    OUT=".github/skills/test/SKILL.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # Lint skill if linter detected
  if [ "$LINTER" != "none" ] && [ "$LINTER" != "null" ]; then
    TMPL="$TEMPLATES_DIR/skills/lint/SKILL.md.tmpl"
    OUT=".github/skills/lint/SKILL.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # Format skill (always — use formatter if present, else linter)
  TMPL="$TEMPLATES_DIR/skills/format/SKILL.md.tmpl"
  OUT=".github/skills/format/SKILL.md"
  if render_template "$TMPL" "$OUT"; then
    OUTPUTS="$OUTPUTS $OUT"
  fi

  # Deploy skill if container detected
  if [ "$CONTAINER" != "none" ] && [ "$CONTAINER" != "null" ]; then
    TMPL="$TEMPLATES_DIR/skills/deploy/SKILL.md.tmpl"
    OUT=".github/skills/deploy/SKILL.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # shellcheck disable=SC2086
  update_generator "skills" "completed" $OUTPUTS
}

# ── Generator: prompts ────────────────────────────────────────────────────────

generate_prompts() {
  OUTPUTS=""
  mkdir -p .github/prompts

  for prompt in new-feature fix-bug write-tests review-pr; do
    TMPL="$TEMPLATES_DIR/prompts/${prompt}.prompt.md.tmpl"
    OUT=".github/prompts/${prompt}.prompt.md"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  done

  # Greenfield-specific prompts
  if [ "$APPROACH" = "greenfield" ]; then
    for prompt in scaffold-project implement-feature; do
      TMPL="$TEMPLATES_DIR/prompts/${prompt}.prompt.md.tmpl"
      OUT=".github/prompts/${prompt}.prompt.md"
      if render_template "$TMPL" "$OUT"; then
        OUTPUTS="$OUTPUTS $OUT"
      fi
    done
  fi

  # shellcheck disable=SC2086
  update_generator "prompts" "completed" $OUTPUTS
}

# ── Generator: mcp ────────────────────────────────────────────────────────────

generate_mcp() {
  mkdir -p .vscode
  OUT=".vscode/mcp.json"

  # Build servers object dynamically based on detected stack
  SERVERS="{}"

  # Database server
  case "$DB" in
    postgres|postgresql)
      SERVERS=$(echo "$SERVERS" | jq '. + {
        "project-db": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-postgres"],
          "env": { "POSTGRES_CONNECTION_STRING": "${input:dbUrl:PostgreSQL connection string}" }
        }
      }')
      ;;
    mysql)
      SERVERS=$(echo "$SERVERS" | jq '. + {
        "project-db": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-mysql"],
          "env": { "MYSQL_CONNECTION_STRING": "${input:dbUrl:MySQL connection string}" }
        }
      }')
      ;;
    mongodb)
      SERVERS=$(echo "$SERVERS" | jq '. + {
        "project-db": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-mongodb"],
          "env": { "MONGODB_URI": "${input:dbUrl:MongoDB connection URI}" }
        }
      }')
      ;;
    sqlite)
      SERVERS=$(echo "$SERVERS" | jq --arg src "$SRC_PATH" '. + {
        "project-db": {
          "command": "npx",
          "args": ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "${workspaceFolder}/app.db"]
        }
      }')
      ;;
  esac

  # Filesystem server (always useful for codebase access)
  SERVERS=$(echo "$SERVERS" | jq --arg src "$SRC_PATH" '. + {
    "project-fs": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "${workspaceFolder}"]
    }
  }')

  jq -n --argjson servers "$SERVERS" '{"servers": $servers}' > "$OUT"

  update_generator "mcp" "completed" "$OUT"
}

# ── Generator: hooks ──────────────────────────────────────────────────────────

generate_hooks() {
  OUTPUTS=""
  mkdir -p .github/hooks

  # Session start hook (always)
  TMPL="$TEMPLATES_DIR/hooks/session-start.hook.json.tmpl"
  OUT=".github/hooks/session-start.json"
  if render_template "$TMPL" "$OUT"; then
    OUTPUTS="$OUTPUTS $OUT"
  fi

  # Pre-tool-use hook if linter detected
  if [ "$LINTER" != "none" ] && [ "$LINTER" != "null" ]; then
    TMPL="$TEMPLATES_DIR/hooks/pre-tool-use.hook.json.tmpl"
    OUT=".github/hooks/pre-tool-use.json"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # Post-tool-use hook if test runner detected
  if [ "$TEST_RUNNER" != "none" ] && [ "$TEST_RUNNER" != "null" ]; then
    TMPL="$TEMPLATES_DIR/hooks/post-tool-use.hook.json.tmpl"
    OUT=".github/hooks/post-tool-use.json"
    if render_template "$TMPL" "$OUT"; then
      OUTPUTS="$OUTPUTS $OUT"
    fi
  fi

  # shellcheck disable=SC2086
  update_generator "hooks" "completed" $OUTPUTS
}

# ── Generator: plugins ────────────────────────────────────────────────────────

generate_plugins() {
  mkdir -p .github/plugins
  OUT=".github/plugins/project.plugin.json"

  # Collect generated agents
  AGENTS="[]"
  for f in .github/agents/*.agent.md; do
    [ -f "$f" ] && AGENTS=$(echo "$AGENTS" | jq --arg f "$f" '. + [$f]')
  done

  # Collect generated skills
  SKILLS="[]"
  for d in .github/skills/*/; do
    [ -f "${d}SKILL.md" ] && SKILLS=$(echo "$SKILLS" | jq --arg d "$d" '. + [$d]')
  done

  # Collect generated hooks
  HOOKS="[]"
  for f in .github/hooks/*.json; do
    [ -f "$f" ] && HOOKS=$(echo "$HOOKS" | jq --arg f "$f" '. + [$f]')
  done

  jq -n \
    --arg name "$PROJECT_NAME" \
    --arg lang "$LANGUAGE" \
    --arg backend "$BACKEND" \
    --arg frontend "$FRONTEND" \
    --arg approach "$APPROACH" \
    --argjson agents "$AGENTS" \
    --argjson skills "$SKILLS" \
    --argjson hooks "$HOOKS" \
    '{
      "name": $name,
      "description": ("Project-specific Copilot plugin for " + $name),
      "approach": $approach,
      "stack": {"language": $lang, "backend": $backend, "frontend": $frontend},
      "agents": $agents,
      "skills": $skills,
      "hooks": $hooks,
      "mcp": ".vscode/mcp.json"
    }' > "$OUT"

  update_generator "plugins" "completed" "$OUT"
}

# ── Generator: docs ───────────────────────────────────────────────────────────

generate_docs() {
  OUTPUTS=""
  mkdir -p .github/docs

  # stack.md
  OUT=".github/docs/stack.md"
  CONTEXT_SOURCE="$CONTEXT_FILE"
  if [ "$APPROACH" = "greenfield" ]; then
    STACK_SOURCE="Generated from \`.greenfield/context.json\` (chosen by user + smart defaults)."
  else
    STACK_SOURCE="Detected from \`.discovery/context.json\`."
  fi
  cat > "$OUT" <<STACKEOF
# Project Stack

${STACK_SOURCE}

## Languages

$(jq -r '.stack.languages[]? | "- " + .' "$CONTEXT_FILE")

## Frameworks

- Backend: ${BACKEND}
- Frontend: ${FRONTEND}
- Database: ${DB}

## Tools

- Package manager: ${PKG_MANAGER}
- Test runner: ${TEST_RUNNER}
- Linter: ${LINTER}
- Formatter: ${FORMATTER}
- Bundler: ${BUNDLER}
- Container: ${CONTAINER}
STACKEOF
  OUTPUTS="$OUTPUTS $OUT"

  # architecture.md
  OUT=".github/docs/architecture.md"
  MONOREPO=$(jq -r '.arch.monorepo // false' "$CONTEXT_FILE")
  SERVICES=$(jq -r '.arch.services // 1' "$CONTEXT_FILE")
  if [ "$APPROACH" = "greenfield" ]; then
    ARCH_SOURCE="Chosen from \`.greenfield/context.json\`."
    ARCH_DETAIL=""
    if [ -f "$DECISIONS_FILE" ]; then
      ARCH_DETAIL=$(jq -r '.arch_rationale.style.reason // ""' "$DECISIONS_FILE")
    fi
  else
    ARCH_SOURCE="Detected from \`.discovery/context.json\`."
    ARCH_DETAIL=""
  fi
  cat > "$OUT" <<ARCHEOF
# Architecture

${ARCH_SOURCE}

## Style

**${ARCH_STYLE}**${ARCH_DETAIL:+

${ARCH_DETAIL}}

## Structure

- Monorepo: ${MONOREPO}
- Services: ${SERVICES}
- Source root: \`${SRC_PATH}\`
- Tests root: \`${TESTS_PATH}\`
ARCHEOF
  OUTPUTS="$OUTPUTS $OUT"

  # agents.md
  OUT=".github/docs/agents.md"
  cat > "$OUT" <<AGENTSEOF
# Generated Agents

Generated by \`copilot-bootstrap generate agents\`.

## Available Agents

$(for f in .github/agents/*.agent.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .agent.md)
  desc=$(awk '/^description:/{print; exit}' "$f" | sed 's/description: *//')
  printf "### %s\n\n%s\n\nFile: \`%s\`\n\n" "$name" "$desc" "$f"
done)
AGENTSEOF
  OUTPUTS="$OUTPUTS $OUT"

  # skills.md
  OUT=".github/docs/skills.md"
  cat > "$OUT" <<SKILLSEOF
# Generated Skills

Generated by \`copilot-bootstrap generate skills\`.

## Available Skills

$(for d in .github/skills/*/; do
  [ -f "${d}SKILL.md" ] || continue
  name=$(basename "$d")
  desc=$(awk '/^description:/{print; exit}' "${d}SKILL.md" | sed 's/description: *//')
  printf "### %s\n\n%s\n\nDirectory: \`%s\`\n\n" "$name" "$desc" "$d"
done)
SKILLSEOF
  OUTPUTS="$OUTPUTS $OUT"

  # prompts.md
  OUT=".github/docs/prompts.md"
  cat > "$OUT" <<PROMPTSEOF
# Generated Prompts

Generated by \`copilot-bootstrap generate prompts\`.

Invoke as slash commands in Copilot Chat (e.g., \`/new-feature\`).

## Available Prompts

$(for f in .github/prompts/*.prompt.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .prompt.md)
  desc=$(awk '/^description:/{print; exit}' "$f" | sed 's/description: *//')
  printf "### /%s\n\n%s\n\nFile: \`%s\`\n\n" "$name" "$desc" "$f"
done)
PROMPTSEOF
  OUTPUTS="$OUTPUTS $OUT"

  # Greenfield-specific: getting-started.md
  if [ "$APPROACH" = "greenfield" ]; then
    OUT=".github/docs/getting-started.md"
    cat > "$OUT" <<GETTINGSTARTEDEOF
# Getting Started with ${PROJECT_NAME}

This Copilot configuration was generated by \`copilot-bootstrap generate\`
from your greenfield project specifications.

## Your Generated Configuration

| Artifact | Location | Purpose |
|---|---|---|
| Project instructions | \`.github/copilot-instructions.md\` | Project-wide Copilot behavior |
| Language instructions | \`.github/instructions/${LANGUAGE}.instructions.md\` | Language coding standards |
| Stack decisions | \`.github/instructions/decisions.instructions.md\` | Why this stack was chosen |
| Scaffold agent | \`.github/agents/scaffold.agent.md\` | Guides initial project setup |
| Dev skills | \`.github/skills/\` | Build, test, lint, format commands |
| Prompts | \`.github/prompts/\` | Reusable task prompts |
| MCP config | \`.vscode/mcp.json\` | MCP server connections |

## Next Steps

### 1. Scaffold the project

Use the scaffold prompt to create the initial project structure:

\`\`\`
/scaffold-project
\`\`\`

Or use the scaffold agent directly in Copilot Chat:

\`\`\`
@scaffold Set up the initial ${PROJECT_NAME} project structure from the specs
\`\`\`

### 2. Implement features

Use the implement-feature prompt for each capability:

\`\`\`
/implement-feature
\`\`\`

Reference capabilities from \`docs/analysis/capabilities.md\`.

### 3. Run dev tasks

\`\`\`
#test     — run the test suite
#build    — build the project
#lint     — check for lint issues
#format   — auto-format the codebase
\`\`\`

## Spec Documents

The following documents were generated during the spec pipeline:

- \`docs/analysis/prd.md\` — requirements
- \`docs/analysis/capabilities.md\` — capability map
- \`docs/domain/model.md\` — domain model
- \`docs/domain/rbac.md\` — roles and permissions
- \`docs/spec/api.md\` — API contracts

## Stack Summary

- **Language**: ${LANGUAGE}
- **Frontend**: ${FRONTEND}
- **Backend**: ${BACKEND}
- **Database**: ${DB}
- **Architecture**: ${ARCH_STYLE}
- **Complexity**: ${COMPLEXITY}
GETTINGSTARTEDEOF
    OUTPUTS="$OUTPUTS $OUT"
  fi

  # shellcheck disable=SC2086
  update_generator "docs" "completed" $OUTPUTS
}

# ── Runner ────────────────────────────────────────────────────────────────────

run_generator() {
  GEN="$1"
  if [ "$FORCE" != "true" ] && is_completed "$GEN"; then
    printf "  ✔ %-14s — already complete\n" "$GEN"
    return 0
  fi
  update_generator "$GEN" "in_progress"
  printf "  … %-14s\r" "$GEN"
  if "generate_${GEN}"; then
    printf "  ✔ %-14s\n" "$GEN"
  else
    update_generator "$GEN" "failed"
    printf "  ✗ %-14s — failed\n" "$GEN"
    return 1
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

init_lock
extract_context

echo "Generator mode: $APPROACH ($CONTEXT_FILE)"
echo ""

case "$TARGET" in
  instructions|agents|skills|prompts|mcp|hooks|plugins|docs)
    echo "Running generator: $TARGET"
    echo ""
    run_generator "$TARGET"
    echo ""
    echo "Done."
    ;;
  "")
    STARTED_AT=$(jq -r '.started_at // "now"' "$LOCK_FILE")
    echo "Running generators (started $STARTED_AT)..."
    echo ""
    FAILED=0
    for gen in instructions agents skills prompts mcp hooks plugins docs; do
      run_generator "$gen" || { FAILED=1; break; }
    done
    echo ""
    if [ "$FAILED" -eq 1 ]; then
      echo "Generator failed. Fix the issue and re-run 'copilot-bootstrap generate'."
      exit 1
    fi
    DONE=$(jq '[.generators | to_entries[] | select(.value.status == "completed" or .value.status == "skipped")] | length' "$LOCK_FILE")
    echo "All generators complete ($DONE/8). Copilot configuration written to .github/ and .vscode/."
    if [ "$APPROACH" = "greenfield" ]; then
      echo ""
      echo "See .github/docs/getting-started.md to begin building ${PROJECT_NAME}."
    fi
    ;;
  *)
    echo "Unknown generator: $TARGET"
    echo "Available generators: instructions agents skills prompts mcp hooks plugins docs"
    exit 1
    ;;
esac

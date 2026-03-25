#!/bin/sh
# generate.sh — Generator orchestrator
#
# Reads .discovery/context.json and docs/discovery/*.md to produce
# project-specific Copilot configuration artifacts.
#
# Usage: copilot-bootstrap generate [generator] [--force]
#        copilot-bootstrap generate status

set -e

DISCOVERY_DIR=".discovery"
CONTEXT_FILE="$DISCOVERY_DIR/context.json"
LOCK_FILE="$DISCOVERY_DIR/generators.lock.json"
TEMPLATES_DIR="${COPILOT_BOOTSTRAP_HOME}/templates"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap generate [generator] [--force]"
  echo ""
  echo "Produces project-specific Copilot configuration from discovery outputs."
  echo "Reads .discovery/context.json; must run 'copilot-bootstrap scan' first."
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
  if [ ! -f "$LOCK_FILE" ]; then
    echo "No generator lock found. Run 'copilot-bootstrap generate' first."
    exit 1
  fi
  echo "Generator status ($LOCK_FILE):"
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

if [ ! -f "$CONTEXT_FILE" ]; then
  echo "Error: $CONTEXT_FILE not found."
  echo "Run 'copilot-bootstrap scan' first to generate codebase context."
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

mkdir -p "$DISCOVERY_DIR"

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
  TEST_RUNNER=$(jq -r '.tools.test_runner // "none"' "$CONTEXT_FILE")
  BUNDLER=$(jq -r '.tools.bundler // "none"' "$CONTEXT_FILE")
  CONTAINER=$(jq -r '.tools.container // "none"' "$CONTEXT_FILE")
  ORCHESTRATOR=$(jq -r '.tools.orchestrator // "none"' "$CONTEXT_FILE")
  ARCH_STYLE=$(jq -r '.arch.style // "unknown"' "$CONTEXT_FILE")
  SRC_PATH=$(jq -r '.paths.src // "src/"' "$CONTEXT_FILE")
  TESTS_PATH=$(jq -r '.paths.tests // "tests/"' "$CONTEXT_FILE")
  PROJECT_NAME="project"
  if [ -f "project.json" ]; then
    N=$(jq -r '.name // ""' "project.json" 2>/dev/null)
    [ -n "$N" ] && PROJECT_NAME="$N"
  fi
  export LANGUAGE LANGUAGES FRONTEND BACKEND DB PKG_MANAGER LINTER TEST_RUNNER \
         BUNDLER CONTAINER ORCHESTRATOR ARCH_STYLE SRC_PATH TESTS_PATH PROJECT_NAME
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

  # Format skill (always — use linter as formatter if no dedicated formatter)
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
    --argjson agents "$AGENTS" \
    --argjson skills "$SKILLS" \
    --argjson hooks "$HOOKS" \
    '{
      "name": $name,
      "description": ("Project-specific Copilot plugin for " + $name),
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
  cat > "$OUT" <<STACKEOF
# Project Stack

Detected from \`.discovery/context.json\`.

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
- Bundler: ${BUNDLER}
- Container: ${CONTAINER}
STACKEOF
  OUTPUTS="$OUTPUTS $OUT"

  # architecture.md
  OUT=".github/docs/architecture.md"
  MONOREPO=$(jq -r '.arch.monorepo // false' "$CONTEXT_FILE")
  SERVICES=$(jq -r '.arch.services // 1' "$CONTEXT_FILE")
  cat > "$OUT" <<ARCHEOF
# Architecture

Detected from \`.discovery/context.json\`.

## Style

**${ARCH_STYLE}**

## Structure

- Monorepo: ${MONOREPO}
- Services: ${SERVICES}
- Source root: \`${SRC_PATH}\`
- Tests root: \`${TESTS_PATH}\`

## Entry Points

$(jq -r '.entrypoints[]? | "- **" + .type + "**: `" + .path + "`"' "$CONTEXT_FILE")
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
    ;;
  *)
    echo "Unknown generator: $TARGET"
    echo "Available generators: instructions agents skills prompts mcp hooks plugins docs"
    exit 1
    ;;
esac

#!/bin/sh
# build-context.sh — Build .greenfield/ context files from interview answers
#
# Reads .greenfield/answers.json, applies smart defaults and derivation rules,
# and writes context.json, decisions.json, and scope.json.
#
# Usage: copilot-bootstrap build-context

set -e

GREENFIELD_DIR=".greenfield"
ANSWERS_FILE="$GREENFIELD_DIR/answers.json"
CONTEXT_FILE="$GREENFIELD_DIR/context.json"
DECISIONS_FILE="$GREENFIELD_DIR/decisions.json"
SCOPE_FILE="$GREENFIELD_DIR/scope.json"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap build-context"
  echo ""
  echo "Builds .greenfield/context.json, decisions.json, and scope.json"
  echo "from .greenfield/answers.json."
  echo ""
  echo "Applies:"
  echo "  - Derivation rules (runtime from language, monorepo from service count)"
  echo "  - Smart defaults (toolchain based on stack choice)"
  echo ""
  echo "Prerequisites: .greenfield/answers.json must exist."
  echo "Run 'copilot-bootstrap interview' first."
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────────────────────

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

# ── Prerequisite checks ───────────────────────────────────────────────────────

if [ ! -f "$ANSWERS_FILE" ]; then
  echo "Error: $ANSWERS_FILE not found."
  echo "Run 'copilot-bootstrap interview' to collect project answers first."
  exit 1
fi

mkdir -p "$GREENFIELD_DIR"

# ── Read raw values from answers ─────────────────────────────────────────────

# Support both .tech.languages[] (array) and .tech.language (singular string)
LANG=$(jq -r '
  if .tech.languages and (.tech.languages | length > 0) then .tech.languages[0]
  elif .tech.language and .tech.language != "null" then .tech.language
  else "unknown"
  end | ascii_downcase' "$ANSWERS_FILE")

FRONTEND=$(jq -r '(.tech.frontend // "") | ascii_downcase' "$ANSWERS_FILE")
BACKEND=$(jq -r '(.tech.backend // "") | ascii_downcase' "$ANSWERS_FILE")
DB=$(jq -r '(.tech.db // "") | ascii_downcase' "$ANSWERS_FILE")
PROJECT_TYPE=$(jq -r '(.project_info.type // "web") | ascii_downcase' "$ANSWERS_FILE")
PROJECT_NAME=$(jq -r '.project_info.name // "my-app"' "$ANSWERS_FILE")
PROJECT_DOMAIN=$(jq -r '.project_info.domain // ""' "$ANSWERS_FILE")
COMPLEXITY=$(jq -r '.complexity.level // "startup"' "$ANSWERS_FILE")
AUTONOMY=$(jq -r '(.complexity.autonomy // .complexity.autonomy_level // "semi")' "$ANSWERS_FILE")
ADLC=$(jq -r '.complexity.adlc // false' "$ANSWERS_FILE")

USER_RUNTIME=$(jq -r '(.tech.runtime // "") | ascii_downcase' "$ANSWERS_FILE")
USER_PKG=$(jq -r '(.tech.package_manager // "") | ascii_downcase' "$ANSWERS_FILE")
USER_LINTER=$(jq -r '(.tech.linter // "") | ascii_downcase' "$ANSWERS_FILE")
USER_FORMATTER=$(jq -r '(.tech.formatter // "") | ascii_downcase' "$ANSWERS_FILE")
USER_TEST=$(jq -r '(.tech.test_runner // "") | ascii_downcase' "$ANSWERS_FILE")
USER_BUNDLER=$(jq -r '(.tech.bundler // "") | ascii_downcase' "$ANSWERS_FILE")
USER_CONTAINER=$(jq -r '(.tech.container // "") | ascii_downcase' "$ANSWERS_FILE")
USER_ORCHESTRATOR=$(jq -r '(.tech.orchestrator // "") | ascii_downcase' "$ANSWERS_FILE")

# ── Derivation rules (high-confidence, applied silently) ──────────────────────

# Derive runtime from language
if [ -n "$USER_RUNTIME" ] && [ "$USER_RUNTIME" != "null" ]; then
  RUNTIME="$USER_RUNTIME"
  RUNTIME_SOURCE="user"
  RUNTIME_REASON="User selected"
else
  case "$LANG" in
    typescript|javascript|ts|js) RUNTIME="node" ;;
    python)                       RUNTIME="python" ;;
    go)                           RUNTIME="go" ;;
    java|kotlin)                  RUNTIME="jvm" ;;
    rust)                         RUNTIME="rust" ;;
    *)                            RUNTIME="$LANG" ;;
  esac
  RUNTIME_SOURCE="derived"
  RUNTIME_REASON="Derived from language: $LANG"
fi

# Derive monorepo (always false for greenfield single-service projects)
MONOREPO="false"
MONOREPO_REASON="Single service project — defaults to false"
MONOREPO_SOURCE="derived"

# Derive architecture style from project type
case "$PROJECT_TYPE" in
  cli)   ARCH_STYLE="monolith"; ARCH_REASON="CLI project defaults to monolith" ;;
  api)   ARCH_STYLE="layered";  ARCH_REASON="API service defaults to layered architecture" ;;
  web)   ARCH_STYLE="layered";  ARCH_REASON="Web app defaults to layered architecture" ;;
  *)     ARCH_STYLE="layered";  ARCH_REASON="Defaults to layered for single service" ;;
esac
ARCH_SOURCE="derived"

# ── Smart defaults for toolchain ──────────────────────────────────────────────
# Precedence: user answer > smart default

DEFAULTS_APPLIED=""

# Helper: set a tool value, tracking source
# Usage: set_tool VARNAME FIELD_NAME USER_VAL DEFAULT_VAL DEFAULT_REASON
set_tool() {
  _var="$1"; _field="$2"; _user="$3"; _default="$4"; _reason="$5"
  if [ -n "$_user" ] && [ "$_user" != "null" ]; then
    eval "${_var}=\"${_user}\""
    eval "${_var}_SOURCE=\"user\""
    eval "${_var}_REASON=\"User selected\""
  else
    eval "${_var}=\"${_default}\""
    eval "${_var}_SOURCE=\"default\""
    eval "${_var}_REASON=\"${_reason}\""
    if [ -n "$_default" ]; then
      DEFAULTS_APPLIED="$DEFAULTS_APPLIED $_field"
    fi
  fi
}

# Determine defaults by stack
case "$LANG" in
  typescript|javascript|ts|js)
    _pkg_default="npm";   _pkg_reason="Default for TypeScript/JavaScript"
    _lint_default="eslint"; _lint_reason="Default for TypeScript"
    _fmt_default="prettier"; _fmt_reason="Default for TypeScript"
    case "$FRONTEND" in
      react|vue|svelte|solid|preact)
        _test_default="vitest"; _test_reason="Default for $FRONTEND + Vite"
        _bundler_default="vite"; _bundler_reason="Default bundler for $FRONTEND"
        ;;
      next|nextjs|nuxt)
        _test_default="jest";    _test_reason="Default for $FRONTEND"
        _bundler_default="";     _bundler_reason=""
        ;;
      *)
        _test_default="jest";    _test_reason="Default for TypeScript/Node"
        _bundler_default="";     _bundler_reason=""
        ;;
    esac
    ;;
  python)
    _pkg_default="pip";     _pkg_reason="Default for Python"
    _lint_default="ruff";   _lint_reason="Default for Python"
    _fmt_default="black";   _fmt_reason="Default for Python"
    _test_default="pytest"; _test_reason="Default for Python"
    _bundler_default="";    _bundler_reason=""
    ;;
  go)
    _pkg_default="";              _pkg_reason=""
    _lint_default="golangci-lint"; _lint_reason="Default for Go"
    _fmt_default="gofmt";         _fmt_reason="Default for Go"
    _test_default="go test";      _test_reason="Default for Go"
    _bundler_default="";          _bundler_reason=""
    ;;
  java|kotlin)
    _pkg_default="gradle";      _pkg_reason="Default for Java/Kotlin"
    _lint_default="checkstyle"; _lint_reason="Default for Java"
    _fmt_default="";            _fmt_reason=""
    _test_default="junit";      _test_reason="Default for Java"
    _bundler_default="";        _bundler_reason=""
    ;;
  rust)
    _pkg_default="cargo";       _pkg_reason="Default for Rust"
    _lint_default="clippy";     _lint_reason="Default for Rust"
    _fmt_default="rustfmt";     _fmt_reason="Default for Rust"
    _test_default="cargo test"; _test_reason="Default for Rust"
    _bundler_default="";        _bundler_reason=""
    ;;
  *)
    _pkg_default="";  _pkg_reason=""
    _lint_default=""; _lint_reason=""
    _fmt_default="";  _fmt_reason=""
    _test_default=""; _test_reason=""
    _bundler_default=""; _bundler_reason=""
    ;;
esac

set_tool PKG_MGR     "package_manager" "$USER_PKG"        "$_pkg_default"     "$_pkg_reason"
set_tool LINTER      "linter"          "$USER_LINTER"     "$_lint_default"    "$_lint_reason"
set_tool FORMATTER   "formatter"       "$USER_FORMATTER"  "$_fmt_default"     "$_fmt_reason"
set_tool TEST_RUNNER "test_runner"     "$USER_TEST"       "$_test_default"    "$_test_reason"
set_tool BUNDLER     "bundler"         "$USER_BUNDLER"    "$_bundler_default" "$_bundler_reason"

# Container and orchestrator — no smart default, user-only
CONTAINER="$USER_CONTAINER"
CONTAINER_SOURCE="user"
CONTAINER_REASON="User selected"

ORCHESTRATOR="$USER_ORCHESTRATOR"
ORCHESTRATOR_SOURCE="user"
ORCHESTRATOR_REASON="User selected"

# ── Derive estimated capabilities ─────────────────────────────────────────────

FEATURE_COUNT=$(jq '.features | length' "$ANSWERS_FILE" 2>/dev/null || echo "0")
EST_CAPS=$((FEATURE_COUNT * 3))

# ── Normalize language list for context.json ──────────────────────────────────

LANGUAGES_JSON=$(jq '
  if .tech.languages and (.tech.languages | length > 0) then .tech.languages
  elif .tech.language and .tech.language != "null" then [.tech.language]
  else ["unknown"]
  end' "$ANSWERS_FILE")

# ── Normalize null/empty strings ──────────────────────────────────────────────

null_or_val() {
  if [ -z "$1" ] || [ "$1" = "null" ]; then
    echo "null"
  else
    printf '"%s"' "$1"
  fi
}

# ── Write context.json ────────────────────────────────────────────────────────

jq -n \
  --argjson languages "$LANGUAGES_JSON" \
  --arg frontend "$FRONTEND" \
  --arg backend "$BACKEND" \
  --arg db "$DB" \
  --arg runtime "$RUNTIME" \
  --arg pkg_mgr "$PKG_MGR" \
  --arg linter "$LINTER" \
  --arg formatter "$FORMATTER" \
  --arg test_runner "$TEST_RUNNER" \
  --arg bundler "$BUNDLER" \
  --arg container "$CONTAINER" \
  --arg orchestrator "$ORCHESTRATOR" \
  --arg arch_style "$ARCH_STYLE" \
  --argjson monorepo "$MONOREPO" \
  --arg project_name "$PROJECT_NAME" \
  --arg project_type "$PROJECT_TYPE" \
  --arg project_domain "$PROJECT_DOMAIN" \
  --arg complexity "$COMPLEXITY" \
  '{
    "stack": {
      "languages": $languages,
      "frontend":  (if $frontend  == "" or $frontend  == "null" then null else $frontend  end),
      "backend":   (if $backend   == "" or $backend   == "null" then null else $backend   end),
      "db":        (if $db        == "" or $db        == "null" then null else $db        end),
      "runtime":   (if $runtime   == "" or $runtime   == "null" then null else $runtime   end)
    },
    "tools": {
      "package_manager": (if $pkg_mgr      == "" or $pkg_mgr      == "null" then null else $pkg_mgr      end),
      "linter":          (if $linter        == "" or $linter        == "null" then null else $linter        end),
      "formatter":       (if $formatter     == "" or $formatter     == "null" then null else $formatter     end),
      "test_runner":     (if $test_runner   == "" or $test_runner   == "null" then null else $test_runner   end),
      "bundler":         (if $bundler       == "" or $bundler       == "null" then null else $bundler       end),
      "container":       (if $container     == "" or $container     == "null" then null else $container     end),
      "orchestrator":    (if $orchestrator  == "" or $orchestrator  == "null" then null else $orchestrator  end)
    },
    "arch": {
      "style":    $arch_style,
      "monorepo": $monorepo,
      "services": 1,
      "patterns": []
    },
    "paths": {
      "src":    "src/",
      "tests":  "tests/",
      "docs":   "docs/",
      "config": "."
    },
    "project": {
      "name":       $project_name,
      "type":       $project_type,
      "domain":     (if $project_domain == "" or $project_domain == "null" then null else $project_domain end),
      "complexity": $complexity
    }
  }' > "$CONTEXT_FILE"

echo "  ✔ $CONTEXT_FILE"

# ── Write decisions.json ──────────────────────────────────────────────────────

# Determine stack decision sources
LANG_SOURCE="user"
LANG_REASON="User selected"
FRONTEND_SOURCE="user"; FRONTEND_REASON="User selected"
BACKEND_SOURCE="user";  BACKEND_REASON="User selected"
DB_SOURCE="user";       DB_REASON="User selected"

jq -n \
  --arg lang "$LANG" \
  --arg lang_source "$LANG_SOURCE" \
  --arg lang_reason "$LANG_REASON" \
  --arg frontend "$FRONTEND" \
  --arg frontend_source "$FRONTEND_SOURCE" \
  --arg frontend_reason "$FRONTEND_REASON" \
  --arg backend "$BACKEND" \
  --arg backend_source "$BACKEND_SOURCE" \
  --arg backend_reason "$BACKEND_REASON" \
  --arg db "$DB" \
  --arg db_source "$DB_SOURCE" \
  --arg db_reason "$DB_REASON" \
  --arg runtime "$RUNTIME" \
  --arg runtime_source "$RUNTIME_SOURCE" \
  --arg runtime_reason "$RUNTIME_REASON" \
  --arg pkg_mgr "$PKG_MGR" \
  --arg pkg_source "$PKG_MGR_SOURCE" \
  --arg pkg_reason "$PKG_MGR_REASON" \
  --arg linter "$LINTER" \
  --arg linter_source "$LINTER_SOURCE" \
  --arg linter_reason "$LINTER_REASON" \
  --arg formatter "$FORMATTER" \
  --arg formatter_source "$FORMATTER_SOURCE" \
  --arg formatter_reason "$FORMATTER_REASON" \
  --arg test "$TEST_RUNNER" \
  --arg test_source "$TEST_RUNNER_SOURCE" \
  --arg test_reason "$TEST_RUNNER_REASON" \
  --arg bundler "$BUNDLER" \
  --arg bundler_source "$BUNDLER_SOURCE" \
  --arg bundler_reason "$BUNDLER_REASON" \
  --arg container "$CONTAINER" \
  --arg container_source "$CONTAINER_SOURCE" \
  --arg container_reason "$CONTAINER_REASON" \
  --arg orchestrator "$ORCHESTRATOR" \
  --arg orchestrator_source "$ORCHESTRATOR_SOURCE" \
  --arg orchestrator_reason "$ORCHESTRATOR_REASON" \
  --arg arch_style "$ARCH_STYLE" \
  --arg arch_source "$ARCH_SOURCE" \
  --arg arch_reason "$ARCH_REASON" \
  --argjson monorepo "$MONOREPO" \
  --arg monorepo_source "$MONOREPO_SOURCE" \
  --arg monorepo_reason "$MONOREPO_REASON" \
  --argjson defaults_applied "$(echo "$DEFAULTS_APPLIED" | tr ' ' '\n' | grep -v '^$' | jq -R . | jq -s . 2>/dev/null || echo '[]')" \
  '{
    "stack_rationale": {
      "language": {"choice": $lang,     "source": $lang_source,     "reason": $lang_reason},
      "frontend":  {"choice": $frontend, "source": $frontend_source, "reason": $frontend_reason},
      "backend":   {"choice": $backend,  "source": $backend_source,  "reason": $backend_reason},
      "db":        {"choice": $db,       "source": $db_source,       "reason": $db_reason},
      "runtime":   {"choice": $runtime,  "source": $runtime_source,  "reason": $runtime_reason}
    },
    "tools_rationale": {
      "package_manager": {"choice": $pkg_mgr,      "source": $pkg_source,        "reason": $pkg_reason},
      "linter":          {"choice": $linter,        "source": $linter_source,     "reason": $linter_reason},
      "formatter":       {"choice": $formatter,     "source": $formatter_source,  "reason": $formatter_reason},
      "test_runner":     {"choice": $test,          "source": $test_source,       "reason": $test_reason},
      "bundler":         {"choice": $bundler,       "source": $bundler_source,    "reason": $bundler_reason},
      "container":       {"choice": $container,     "source": $container_source,  "reason": $container_reason},
      "orchestrator":    {"choice": $orchestrator,  "source": $orchestrator_source, "reason": $orchestrator_reason}
    },
    "arch_rationale": {
      "style":    {"choice": $arch_style, "source": $arch_source,     "reason": $arch_reason},
      "monorepo": {"choice": $monorepo,   "source": $monorepo_source, "reason": $monorepo_reason}
    },
    "defaults_applied": $defaults_applied
  }' > "$DECISIONS_FILE"

echo "  ✔ $DECISIONS_FILE"

# ── Write scope.json ──────────────────────────────────────────────────────────

jq -n \
  --argjson features "$(jq '.features // []' "$ANSWERS_FILE")" \
  --argjson users "$(jq '.users // []' "$ANSWERS_FILE")" \
  --arg complexity "$COMPLEXITY" \
  --arg autonomy "$AUTONOMY" \
  --argjson adlc "$ADLC" \
  --argjson est_caps "$EST_CAPS" \
  '{
    "features":              $features,
    "users":                 $users,
    "complexity":            $complexity,
    "autonomy_level":        $autonomy,
    "adlc":                  $adlc,
    "estimated_capabilities": $est_caps
  }' > "$SCOPE_FILE"

echo "  ✔ $SCOPE_FILE"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "Context built from $ANSWERS_FILE"
echo ""

DEFAULTED_LIST=$(echo "$DEFAULTS_APPLIED" | tr ' ' '\n' | grep -v '^$')
DEFAULTED_COUNT=$(echo "$DEFAULTED_LIST" | grep -v '^$' | wc -l | tr -d ' ')
if [ "$DEFAULTED_COUNT" -gt 0 ]; then
  echo "Smart defaults applied ($DEFAULTED_COUNT fields): $(echo "$DEFAULTED_LIST" | tr '\n' ' ')"
fi

echo "Runtime:      $RUNTIME ($RUNTIME_SOURCE)"
echo "Architecture: $ARCH_STYLE ($ARCH_SOURCE)"
echo ""
echo "Run 'copilot-bootstrap spec-pipeline' to generate specification documents."

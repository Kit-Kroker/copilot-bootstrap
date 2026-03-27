#!/bin/sh
# scan.sh — Pre-discovery codebase scanner (Task 2: Context Engine)
# Scans the codebase at project.json → codebase_path and produces:
#   .discovery/fs.json, stack.json, tools.json, arch.json, context.json, confidence.json
#
# Usage: copilot-bootstrap scan [codebase_path]
#   codebase_path: optional override; defaults to project.json → codebase_path

set -e

DISCOVERY_DIR=".discovery"
PROJECT_FILE="project.json"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap scan [codebase_path]"
  echo ""
  echo "Scans the target codebase and writes structured JSON to .discovery/:"
  echo "  fs.json         filesystem scan results"
  echo "  stack.json      detected languages, frameworks, database, runtime"
  echo "  tools.json      detected toolchain"
  echo "  arch.json       detected architecture style"
  echo "  context.json    unified context (input for generators and pipeline)"
  echo "  confidence.json detection confidence scores (0.0–1.0)"
  echo ""
  echo "If codebase_path is not provided, reads project.json → codebase_path."
  echo ""
  echo "Also sets project.json → approach = \"brownfield\" and codebase_path automatically."
  echo "Run 'copilot-bootstrap discover' after scanning."
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────────────────────

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

# ── Resolve codebase path ─────────────────────────────────────────────────────

CODEBASE="${1:-}"

if [ -z "$CODEBASE" ] && [ -f "$PROJECT_FILE" ]; then
  CODEBASE=$(jq -r '.codebase_path // ""' "$PROJECT_FILE")
fi

if [ -z "$CODEBASE" ]; then
  echo "Error: No codebase path provided."
  echo "Either pass it as an argument or set codebase_path in project.json"
  echo "Run 'copilot-bootstrap scan --help' for usage."
  exit 1
fi

if [ ! -d "$CODEBASE" ]; then
  echo "Error: Codebase path does not exist or is not a directory: $CODEBASE"
  exit 1
fi

mkdir -p "$DISCOVERY_DIR"

# ── Portable helpers ──────────────────────────────────────────────────────────

# f <rel_path>  → true if file exists under CODEBASE
f() { [ -f "$CODEBASE/$1" ]; }

# d <rel_path>  → true if dir exists under CODEBASE
d() { [ -d "$CODEBASE/$1" ]; }

# grep_file <pattern> <rel_path>  → true if pattern found in file (case-insensitive)
grep_file() { f "$2" && grep -qi "$1" "$CODEBASE/$2" 2>/dev/null; }

# words_to_json_array "word1 word2 word3" → ["word1","word2","word3"]
words_to_json_array() {
  echo "$1" | tr ' ' '\n' | grep -v '^$' | jq -R . | jq -sc .
}

echo "Scanning: $CODEBASE"

# ════════════════════════════════════════════════════════════════════════════
# 1. Filesystem Scan → .discovery/fs.json
# ════════════════════════════════════════════════════════════════════════════

printf "  [1/5] Scanning filesystem... "

# Total file count (excluding .git and generated dirs)
total_files=$(find "$CODEBASE" -type f \
  -not -path '*/.git/*' \
  -not -path '*/node_modules/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/target/*' \
  -not -path '*/dist/*' \
  -not -path '*/.venv/*' \
  2>/dev/null | wc -l | tr -d ' ')

# Extension counts → JSON object {"ts":120,"py":45,...}
lang_json=$(find "$CODEBASE" -type f \
  -not -path '*/.git/*' \
  -not -path '*/node_modules/*' \
  -not -path '*/__pycache__/*' \
  -not -path '*/target/*' \
  -not -path '*/dist/*' \
  -not -path '*/.venv/*' \
  2>/dev/null \
  | grep '\.' | sed 's/.*\.//' | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -rn | head -20 \
  | awk 'BEGIN{printf "{"} NR>1{printf ","} {printf "\"%s\":%d", $2, $1} END{printf "}"}')
[ -z "$lang_json" ] && lang_json="{}"

# Config files present at root or one level deep
configs=""
for cfg in \
  package.json package-lock.json yarn.lock pnpm-lock.yaml \
  pyproject.toml requirements.txt setup.py setup.cfg Pipfile Pipfile.lock poetry.lock \
  go.mod go.sum \
  Cargo.toml Cargo.lock \
  pom.xml build.gradle build.gradle.kts settings.gradle gradlew \
  Makefile CMakeLists.txt \
  docker-compose.yml docker-compose.yaml Dockerfile .dockerignore \
  tsconfig.json jsconfig.json \
  .eslintrc .eslintrc.js .eslintrc.json .eslintrc.yaml .eslintrc.cjs \
  .prettierrc .prettierrc.js .prettierrc.json prettier.config.js \
  vite.config.js vite.config.ts webpack.config.js webpack.config.ts \
  jest.config.js jest.config.ts vitest.config.ts vitest.config.js \
  pytest.ini .pytest.ini pyproject.toml tox.ini \
  golangci.yml golangci.yaml .golangci.yml \
  .env .env.example .env.template; do
  f "$cfg" && configs="$configs $cfg"
done
configs_json=$(words_to_json_array "$configs")

# Significant directories
dirs=""
for dir in \
  src test tests spec lib cmd pkg internal api app core \
  modules features components pages views controllers services \
  repositories handlers middleware adapters domain infra \
  scripts docs .github .gitlab .circleci \
  frontend backend web client server \
  k8s kubernetes helm charts deploy infra; do
  d "$dir" && dirs="$dirs $dir/"
done
dirs_json=$(words_to_json_array "$dirs")

# CI system
ci="none"
d ".github/workflows" && ci="github-actions"
f ".gitlab-ci.yml" && ci="gitlab-ci"
f "Jenkinsfile" && ci="jenkins"
f ".circleci/config.yml" && ci="circleci"
f "azure-pipelines.yml" && ci="azure-pipelines"
f ".travis.yml" && ci="travis"
f "bitbucket-pipelines.yml" && ci="bitbucket"

jq -n \
  --argjson total_files "$total_files" \
  --argjson languages "$lang_json" \
  --argjson configs "$configs_json" \
  --argjson directories "$dirs_json" \
  --arg ci "$ci" \
  '{
    total_files: $total_files,
    languages:   $languages,
    configs:     $configs,
    directories: $directories,
    ci:          $ci
  }' > "$DISCOVERY_DIR/fs.json"

echo "done"

# ════════════════════════════════════════════════════════════════════════════
# 2. Stack Detection → .discovery/stack.json
# ════════════════════════════════════════════════════════════════════════════

printf "  [2/5] Detecting stack... "

languages=""
frontend="null"
backend="null"
db="null"
runtime="null"

# ── Language detection ────────────────────────────────────────────────────

# Confidence trackers (config=high, ext=medium, weak=low)
lang_conf="none"

if f "package.json"; then
  languages="typescript javascript"
  # Refine: if .ts files present → typescript, else javascript
  ts_count=$(echo "$lang_json" | jq -r '.ts // 0')
  tsx_count=$(echo "$lang_json" | jq -r '.tsx // 0')
  if [ "$ts_count" -gt 0 ] 2>/dev/null || [ "$tsx_count" -gt 0 ] 2>/dev/null; then
    languages="typescript"
  else
    languages="javascript"
  fi
  runtime="node"
  lang_conf="config"
fi

if f "go.mod"; then
  languages="${languages:+$languages }go"
  runtime="go"
  lang_conf="config"
fi

if f "Cargo.toml"; then
  languages="${languages:+$languages }rust"
  runtime="rust"
  lang_conf="config"
fi

if f "pom.xml" || f "build.gradle" || f "build.gradle.kts"; then
  languages="${languages:+$languages }java"
  runtime="jvm"
  lang_conf="config"
fi

if f "pyproject.toml" || f "requirements.txt" || f "setup.py" || f "Pipfile"; then
  languages="${languages:+$languages }python"
  runtime="python"
  lang_conf="config"
fi

if f "mix.exs"; then
  languages="${languages:+$languages }elixir"
  runtime="beam"
  lang_conf="config"
fi

if f "composer.json"; then
  languages="${languages:+$languages }php"
  runtime="php"
  lang_conf="config"
fi

if f "Gemfile"; then
  languages="${languages:+$languages }ruby"
  runtime="ruby"
  lang_conf="config"
fi

# Fallback: infer from extension counts
if [ -z "$languages" ]; then
  py_count=$(echo "$lang_json" | jq -r '.py // 0')
  go_count=$(echo "$lang_json" | jq -r '.go // 0')
  rs_count=$(echo "$lang_json" | jq -r '.rs // 0')
  rb_count=$(echo "$lang_json" | jq -r '.rb // 0')
  cs_count=$(echo "$lang_json" | jq -r '.cs // 0')
  [ "$py_count" -gt 5 ] 2>/dev/null && languages="python" && runtime="python" && lang_conf="ext"
  [ "$go_count" -gt 5 ] 2>/dev/null && languages="go" && runtime="go" && lang_conf="ext"
  [ "$rs_count" -gt 5 ] 2>/dev/null && languages="rust" && runtime="rust" && lang_conf="ext"
  [ "$rb_count" -gt 5 ] 2>/dev/null && languages="ruby" && runtime="ruby" && lang_conf="ext"
  [ "$cs_count" -gt 5 ] 2>/dev/null && languages="csharp" && runtime="dotnet" && lang_conf="ext"
fi

# ── Frontend detection ────────────────────────────────────────────────────

frontend_conf="none"

if f "package.json"; then
  pkg="$CODEBASE/package.json"
  # Check deps and devDeps
  has_dep() { jq -e --arg d "$1" '.dependencies[$d] // .devDependencies[$d] // null | . != null' "$pkg" > /dev/null 2>&1; }
  if has_dep "react" || has_dep "react-dom"; then
    frontend="react"
    frontend_conf="config"
  elif has_dep "vue" || has_dep "@vue/core"; then
    frontend="vue"
    frontend_conf="config"
  elif has_dep "@angular/core"; then
    frontend="angular"
    frontend_conf="config"
  elif has_dep "svelte"; then
    frontend="svelte"
    frontend_conf="config"
  elif has_dep "solid-js"; then
    frontend="solid"
    frontend_conf="config"
  elif has_dep "next"; then
    frontend="next"
    frontend_conf="config"
  elif has_dep "nuxt"; then
    frontend="nuxt"
    frontend_conf="config"
  fi
fi

# Fallback: check for JSX/TSX files
if [ "$frontend" = "null" ] && [ "$frontend_conf" = "none" ]; then
  tsx_count=$(echo "$lang_json" | jq -r '.tsx // 0')
  jsx_count=$(echo "$lang_json" | jq -r '.jsx // 0')
  if [ "${tsx_count:-0}" -gt 5 ] 2>/dev/null || [ "${jsx_count:-0}" -gt 5 ] 2>/dev/null; then
    frontend="react"
    frontend_conf="ext"
  fi
fi

# ── Backend detection ─────────────────────────────────────────────────────

backend_conf="none"

if f "package.json"; then
  pkg="$CODEBASE/package.json"
  has_dep() { jq -e --arg d "$1" '.dependencies[$d] // .devDependencies[$d] // null | . != null' "$pkg" > /dev/null 2>&1; }
  if has_dep "express"; then
    backend="express"
    backend_conf="config"
  elif has_dep "fastify"; then
    backend="fastify"
    backend_conf="config"
  elif has_dep "koa"; then
    backend="koa"
    backend_conf="config"
  elif has_dep "hapi" || has_dep "@hapi/hapi"; then
    backend="hapi"
    backend_conf="config"
  elif has_dep "nestjs" || has_dep "@nestjs/core"; then
    backend="nestjs"
    backend_conf="config"
  elif has_dep "next"; then
    # Next.js can be both frontend and backend
    backend="${backend:-next}"
    backend_conf="config"
  fi
fi

if [ "$backend" = "null" ] && [ "$backend_conf" = "none" ]; then
  if f "pyproject.toml" || f "requirements.txt"; then
    req_file="$CODEBASE/requirements.txt"
    pyproject="$CODEBASE/pyproject.toml"
    grep_file "fastapi" "requirements.txt" || grep_file "fastapi" "pyproject.toml" && backend="fastapi" && backend_conf="config"
    grep_file "django" "requirements.txt" || grep_file "django" "pyproject.toml" && backend="django" && backend_conf="config"
    grep_file "flask" "requirements.txt" || grep_file "flask" "pyproject.toml" && backend="flask" && backend_conf="config"
    grep_file "starlette" "requirements.txt" || grep_file "starlette" "pyproject.toml" && backend="${backend:-starlette}" && backend_conf="config"
  fi
fi

if [ "$backend" = "null" ] && f "go.mod"; then
  grep_file "gin-gonic" "go.mod" && backend="gin" && backend_conf="config"
  grep_file "echo" "go.mod" && backend="${backend:-echo}" && backend_conf="config"
  grep_file "fiber" "go.mod" && backend="${backend:-fiber}" && backend_conf="config"
  grep_file "chi" "go.mod" && backend="${backend:-chi}" && backend_conf="config"
  # Plain Go HTTP
  [ "$backend" = "null" ] && backend="go-net/http" && backend_conf="config"
fi

if [ "$backend" = "null" ] && (f "pom.xml" || f "build.gradle" || f "build.gradle.kts"); then
  grep_file "spring-boot" "pom.xml" || grep_file "spring-boot" "build.gradle" && backend="spring-boot" && backend_conf="config"
  grep_file "quarkus" "pom.xml" || grep_file "quarkus" "build.gradle" && backend="${backend:-quarkus}" && backend_conf="config"
fi

if [ "$backend" = "null" ] && f "Cargo.toml"; then
  grep_file "actix-web" "Cargo.toml" && backend="actix-web" && backend_conf="config"
  grep_file "axum" "Cargo.toml" && backend="${backend:-axum}" && backend_conf="config"
  grep_file "rocket" "Cargo.toml" && backend="${backend:-rocket}" && backend_conf="config"
fi

# ── Database detection ────────────────────────────────────────────────────

db_conf="none"

# From docker-compose
for dc_file in "docker-compose.yml" "docker-compose.yaml"; do
  if f "$dc_file"; then
    grep_file "postgres\|postgresql" "$dc_file" && db="postgres" && db_conf="config"
    grep_file "mysql\|mariadb" "$dc_file" && [ "$db" = "null" ] && db="mysql" && db_conf="config"
    grep_file "mongodb\|mongo:" "$dc_file" && [ "$db" = "null" ] && db="mongodb" && db_conf="config"
    grep_file "redis" "$dc_file" && [ "$db" = "null" ] && db="redis" && db_conf="config"
    grep_file "sqlite" "$dc_file" && [ "$db" = "null" ] && db="sqlite" && db_conf="config"
    break
  fi
done

# From ORM/driver deps in package.json
if [ "$db" = "null" ] && f "package.json"; then
  pkg="$CODEBASE/package.json"
  has_dep() { jq -e --arg d "$1" '.dependencies[$d] // .devDependencies[$d] // null | . != null' "$pkg" > /dev/null 2>&1; }
  has_dep "pg" || has_dep "postgres" || has_dep "@prisma/client" && grep_file "postgres\|postgresql" "prisma/schema.prisma" && db="postgres" && db_conf="config"
  has_dep "mysql" || has_dep "mysql2" && [ "$db" = "null" ] && db="mysql" && db_conf="config"
  has_dep "mongodb" || has_dep "mongoose" && [ "$db" = "null" ] && db="mongodb" && db_conf="config"
  has_dep "sqlite3" || has_dep "better-sqlite3" && [ "$db" = "null" ] && db="sqlite" && db_conf="config"
  has_dep "redis" || has_dep "ioredis" && [ "$db" = "null" ] && db="redis" && db_conf="config"
fi

# From Python deps
if [ "$db" = "null" ]; then
  grep_file "psycopg\|psycopg2\|asyncpg\|sqlalchemy.*postgres" "requirements.txt" && db="postgres" && db_conf="config"
  grep_file "psycopg\|asyncpg\|psycopg2" "pyproject.toml" && [ "$db" = "null" ] && db="postgres" && db_conf="config"
  grep_file "pymongo\|motor" "requirements.txt" && [ "$db" = "null" ] && db="mongodb" && db_conf="config"
  grep_file "pymysql\|aiomysql" "requirements.txt" && [ "$db" = "null" ] && db="mysql" && db_conf="config"
fi

# From Go modules
if [ "$db" = "null" ] && f "go.mod"; then
  grep_file "pgx\|pq\|lib/pq" "go.mod" && db="postgres" && db_conf="config"
  grep_file "go-sql-driver/mysql" "go.mod" && [ "$db" = "null" ] && db="mysql" && db_conf="config"
  grep_file "mongo-driver" "go.mod" && [ "$db" = "null" ] && db="mongodb" && db_conf="config"
fi

# ── Write stack.json ──────────────────────────────────────────────────────

languages_json=$(words_to_json_array "$languages")

jq -n \
  --argjson languages "$languages_json" \
  --arg frontend "$frontend" \
  --arg backend "$backend" \
  --arg db "$db" \
  --arg runtime "$runtime" \
  '{
    languages: $languages,
    frontend:  (if $frontend == "null" then null else $frontend end),
    backend:   (if $backend  == "null" then null else $backend  end),
    db:        (if $db       == "null" then null else $db       end),
    runtime:   (if $runtime  == "null" then null else $runtime  end)
  }' > "$DISCOVERY_DIR/stack.json"

echo "done"

# ════════════════════════════════════════════════════════════════════════════
# 3. Tools Detection → .discovery/tools.json
# ════════════════════════════════════════════════════════════════════════════

printf "  [3/5] Detecting tools... "

pkg_manager="null"
linter="null"
formatter="null"
test_runner="null"
bundler="null"
container="null"
orchestrator="null"

# ── Package manager ───────────────────────────────────────────────────────

f "pnpm-lock.yaml"      && pkg_manager="pnpm"
f "yarn.lock"           && [ "$pkg_manager" = "null" ] && pkg_manager="yarn"
f "package-lock.json"   && [ "$pkg_manager" = "null" ] && pkg_manager="npm"
f "package.json"        && [ "$pkg_manager" = "null" ] && pkg_manager="npm"
f "poetry.lock"         && [ "$pkg_manager" = "null" ] && pkg_manager="poetry"
f "Pipfile.lock"        && [ "$pkg_manager" = "null" ] && pkg_manager="pipenv"
f "pyproject.toml"      && [ "$pkg_manager" = "null" ] && pkg_manager="pip"
f "requirements.txt"    && [ "$pkg_manager" = "null" ] && pkg_manager="pip"
f "go.mod"              && [ "$pkg_manager" = "null" ] && pkg_manager="go"
f "Cargo.toml"          && [ "$pkg_manager" = "null" ] && pkg_manager="cargo"
f "pom.xml"             && [ "$pkg_manager" = "null" ] && pkg_manager="maven"
f "build.gradle"        && [ "$pkg_manager" = "null" ] && pkg_manager="gradle"
f "build.gradle.kts"    && [ "$pkg_manager" = "null" ] && pkg_manager="gradle"
f "Gemfile"             && [ "$pkg_manager" = "null" ] && pkg_manager="bundler"
f "composer.json"       && [ "$pkg_manager" = "null" ] && pkg_manager="composer"

# ── Linter ────────────────────────────────────────────────────────────────

f ".eslintrc"           && linter="eslint"
f ".eslintrc.js"        && linter="eslint"
f ".eslintrc.cjs"       && linter="eslint"
f ".eslintrc.json"      && linter="eslint"
f ".eslintrc.yaml"      && linter="eslint"
f ".eslintrc.yml"       && linter="eslint"
f "eslint.config.js"    && linter="eslint"
f "eslint.config.mjs"   && linter="eslint"
f ".pylintrc"           && [ "$linter" = "null" ] && linter="pylint"
f ".golangci.yml"       && [ "$linter" = "null" ] && linter="golangci-lint"
f ".golangci.yaml"      && [ "$linter" = "null" ] && linter="golangci-lint"
f ".clippy.toml"        && [ "$linter" = "null" ] && linter="clippy"
f ".rubocop.yml"        && [ "$linter" = "null" ] && linter="rubocop"
f "checkstyle.xml"      && [ "$linter" = "null" ] && linter="checkstyle"

# ruff (Python): check pyproject.toml or ruff.toml
f "ruff.toml" && [ "$linter" = "null" ] && linter="ruff"
grep_file "\[tool.ruff\]" "pyproject.toml" && [ "$linter" = "null" ] && linter="ruff"

# ── Formatter ─────────────────────────────────────────────────────────────

f ".prettierrc"         && formatter="prettier"
f ".prettierrc.js"      && formatter="prettier"
f ".prettierrc.json"    && formatter="prettier"
f ".prettierrc.yaml"    && formatter="prettier"
f "prettier.config.js"  && formatter="prettier"
f "prettier.config.mjs" && formatter="prettier"
grep_file "\[tool.black\]" "pyproject.toml" && [ "$formatter" = "null" ] && formatter="black"
f ".black"              && [ "$formatter" = "null" ] && formatter="black"
grep_file "\[tool.isort\]" "pyproject.toml" && [ "$formatter" = "null" ] && formatter="isort"
grep_file "gofmt\|goimports" ".golangci.yml" && [ "$formatter" = "null" ] && formatter="gofmt"
f "rustfmt.toml"        && [ "$formatter" = "null" ] && formatter="rustfmt"
f ".rustfmt.toml"       && [ "$formatter" = "null" ] && formatter="rustfmt"

# ── Test runner ───────────────────────────────────────────────────────────

f "jest.config.js"      && test_runner="jest"
f "jest.config.ts"      && test_runner="jest"
f "jest.config.mjs"     && test_runner="jest"
f "jest.config.cjs"     && test_runner="jest"
f "vitest.config.ts"    && [ "$test_runner" = "null" ] && test_runner="vitest"
f "vitest.config.js"    && [ "$test_runner" = "null" ] && test_runner="vitest"
f "pytest.ini"          && [ "$test_runner" = "null" ] && test_runner="pytest"
f ".pytest.ini"         && [ "$test_runner" = "null" ] && test_runner="pytest"
grep_file "\[tool.pytest" "pyproject.toml" && [ "$test_runner" = "null" ] && test_runner="pytest"
f "go.mod"              && d "$(find "$CODEBASE" -name '*_test.go' 2>/dev/null | head -1 | sed "s|$CODEBASE/||" | sed 's|/[^/]*$||')" && [ "$test_runner" = "null" ] && test_runner="go-test"
f "go.mod"              && [ "$test_runner" = "null" ] && test_runner="go-test"
f "Cargo.toml"          && [ "$test_runner" = "null" ] && test_runner="cargo-test"
f "pom.xml"             && [ "$test_runner" = "null" ] && test_runner="junit"
f "build.gradle"        && [ "$test_runner" = "null" ] && test_runner="junit"
f "Gemfile"             && [ "$test_runner" = "null" ] && test_runner="rspec"
grep_file "mocha" "package.json" && [ "$test_runner" = "null" ] && test_runner="mocha"

# If package.json has jest in devDeps but no config file
if [ "$test_runner" = "null" ] && f "package.json"; then
  pkg="$CODEBASE/package.json"
  has_dep() { jq -e --arg d "$1" '.dependencies[$d] // .devDependencies[$d] // null | . != null' "$pkg" > /dev/null 2>&1; }
  has_dep "jest"   && test_runner="jest"
  has_dep "vitest" && [ "$test_runner" = "null" ] && test_runner="vitest"
  has_dep "mocha"  && [ "$test_runner" = "null" ] && test_runner="mocha"
fi

# ── Bundler ───────────────────────────────────────────────────────────────

f "vite.config.ts"      && bundler="vite"
f "vite.config.js"      && bundler="vite"
f "webpack.config.js"   && [ "$bundler" = "null" ] && bundler="webpack"
f "webpack.config.ts"   && [ "$bundler" = "null" ] && bundler="webpack"
f "esbuild.config.js"   && [ "$bundler" = "null" ] && bundler="esbuild"
f "rollup.config.js"    && [ "$bundler" = "null" ] && bundler="rollup"
f "rollup.config.ts"    && [ "$bundler" = "null" ] && bundler="rollup"
f "parcel.json"         && [ "$bundler" = "null" ] && bundler="parcel"
f ".parcelrc"           && [ "$bundler" = "null" ] && bundler="parcel"
f "turbo.json"          && [ "$bundler" = "null" ] && bundler="turbo"
f "next.config.js"      && [ "$bundler" = "null" ] && bundler="next"
f "next.config.ts"      && [ "$bundler" = "null" ] && bundler="next"
f "next.config.mjs"     && [ "$bundler" = "null" ] && bundler="next"

if [ "$bundler" = "null" ] && f "package.json"; then
  pkg="$CODEBASE/package.json"
  has_dep() { jq -e --arg d "$1" '.dependencies[$d] // .devDependencies[$d] // null | . != null' "$pkg" > /dev/null 2>&1; }
  has_dep "vite"    && bundler="vite"
  has_dep "webpack" && [ "$bundler" = "null" ] && bundler="webpack"
  has_dep "esbuild" && [ "$bundler" = "null" ] && bundler="esbuild"
  has_dep "rollup"  && [ "$bundler" = "null" ] && bundler="rollup"
  has_dep "parcel"  && [ "$bundler" = "null" ] && bundler="parcel"
fi

# ── Container / Orchestrator ──────────────────────────────────────────────

f "Dockerfile"          && container="docker"
d ".docker"             && container="docker"
f "Containerfile"       && [ "$container" = "null" ] && container="podman"

f "docker-compose.yml"  && orchestrator="docker-compose"
f "docker-compose.yaml" && [ "$orchestrator" = "null" ] && orchestrator="docker-compose"
d "k8s"                 && [ "$orchestrator" = "null" ] && orchestrator="kubernetes"
d "kubernetes"          && [ "$orchestrator" = "null" ] && orchestrator="kubernetes"
d "helm"                && [ "$orchestrator" = "null" ] && orchestrator="helm"
d "charts"              && [ "$orchestrator" = "null" ] && orchestrator="helm"

# ── Write tools.json ──────────────────────────────────────────────────────

jq -n \
  --arg pkg_manager  "$pkg_manager" \
  --arg linter       "$linter" \
  --arg formatter    "$formatter" \
  --arg test_runner  "$test_runner" \
  --arg bundler      "$bundler" \
  --arg container    "$container" \
  --arg orchestrator "$orchestrator" \
  '{
    package_manager: (if $pkg_manager  == "null" then null else $pkg_manager  end),
    linter:          (if $linter       == "null" then null else $linter       end),
    formatter:       (if $formatter    == "null" then null else $formatter    end),
    test_runner:     (if $test_runner  == "null" then null else $test_runner  end),
    bundler:         (if $bundler      == "null" then null else $bundler      end),
    container:       (if $container    == "null" then null else $container    end),
    orchestrator:    (if $orchestrator == "null" then null else $orchestrator end)
  }' > "$DISCOVERY_DIR/tools.json"

echo "done"

# ════════════════════════════════════════════════════════════════════════════
# 4. Architecture Detection → .discovery/arch.json
# ════════════════════════════════════════════════════════════════════════════

printf "  [4/5] Detecting architecture... "

arch_style="unknown"
monorepo=false
services=1
patterns=""

# ── Monorepo detection ────────────────────────────────────────────────────

# Multiple package.json at depth > 1
pkg_json_count=$(find "$CODEBASE" -name "package.json" \
  -not -path '*/node_modules/*' \
  -not -path '*/.git/*' \
  2>/dev/null | wc -l | tr -d ' ')

if d "packages" || d "apps" || d "libs" || d "workspaces"; then
  monorepo=true
fi

if [ "${pkg_json_count:-1}" -gt 2 ] 2>/dev/null; then
  monorepo=true
fi

f "nx.json"       && monorepo=true
f "lerna.json"    && monorepo=true
f "turbo.json"    && monorepo=true
f "rush.json"     && monorepo=true
f "pnpm-workspace.yaml" && monorepo=true

# ── Service count (from docker-compose) ──────────────────────────────────

for dc_file in "docker-compose.yml" "docker-compose.yaml"; do
  if f "$dc_file"; then
    # Count services by counting top-level service entries (lines with 2-space indent and colon but no deeper indent)
    # Exclude known infra-only services from count
    app_services=$(grep -v '^\s*#' "$CODEBASE/$dc_file" 2>/dev/null | \
      grep -v 'postgres\|mysql\|redis\|mongo\|rabbitmq\|kafka\|zookeeper\|elasticsearch\|nginx' | \
      grep -c '^\  [a-zA-Z][a-zA-Z0-9_-]*:' 2>/dev/null || echo "1")
    services="${app_services:-1}"
    break
  fi
done

# Monorepo services from apps/ or packages/
if $monorepo; then
  for mdir in "apps" "packages"; do
    if d "$mdir"; then
      mdir_count=$(find "$CODEBASE/$mdir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
      [ "${mdir_count:-0}" -gt "$services" ] 2>/dev/null && services="$mdir_count"
    fi
  done
fi

# Ensure services is a valid integer
services=$(echo "$services" | tr -d ' \n' | grep -o '^[0-9]*' | head -1)
[ -z "$services" ] && services=1

# ── Architecture style ────────────────────────────────────────────────────

if $monorepo; then
  arch_style="monorepo"
elif [ "${services:-1}" -ge 3 ] 2>/dev/null; then
  arch_style="microservices"
else
  # Inspect directory structure for patterns
  if d "src/modules" || d "src/features" || d "app/modules" || d "app/features"; then
    arch_style="modular"
  elif d "src/domain" || d "src/application" || d "src/infrastructure" || d "src/adapters"; then
    arch_style="hexagonal"
  elif (d "src/controllers" || d "src/handlers") && (d "src/services" || d "src/application") && (d "src/repositories" || d "src/data"); then
    arch_style="layered"
  elif d "src/controllers" || d "app/controllers" || d "src/routes"; then
    arch_style="layered"
  elif d "cmd" && d "internal" && d "pkg"; then
    # Go standard layout
    arch_style="layered"
  elif f "pom.xml" || f "build.gradle"; then
    arch_style="layered"  # Java defaults to layered
  elif d "src"; then
    arch_style="layered"  # Single src dir → likely layered
  fi
fi

# ── Patterns detection ────────────────────────────────────────────────────

(d "src/controllers" || d "app/controllers") && patterns="$patterns mvc"
(d "src/repositories" || d "src/repo") && patterns="$patterns repository"
(d "src/services" || d "src/application/services") && patterns="$patterns service-layer"
(d "src/domain" || d "src/core") && patterns="$patterns domain-driven"
(d "src/events" || d "src/handlers/events") && patterns="$patterns event-driven"
d "src/middleware" && patterns="$patterns middleware"

patterns_json=$(words_to_json_array "$patterns")

# ── Write arch.json ───────────────────────────────────────────────────────

jq -n \
  --arg style    "$arch_style" \
  --argjson monorepo  "$monorepo" \
  --argjson services  "$services" \
  --argjson patterns  "$patterns_json" \
  '{
    style:    $style,
    monorepo: $monorepo,
    services: $services,
    patterns: $patterns
  }' > "$DISCOVERY_DIR/arch.json"

echo "done"

# ════════════════════════════════════════════════════════════════════════════
# 5. Build Context + Confidence → context.json, confidence.json
# ════════════════════════════════════════════════════════════════════════════

printf "  [5/5] Building context... "

# ── Determine source and test paths ──────────────────────────────────────

src_path="src/"
d "src"         && src_path="src/"
d "app"         && [ ! -d "$CODEBASE/src" ] && src_path="app/"
d "lib"         && [ ! -d "$CODEBASE/src" ] && [ ! -d "$CODEBASE/app" ] && src_path="lib/"
# Go layout
d "cmd"         && f "go.mod" && src_path="cmd/"

tests_path="tests/"
d "tests"       && tests_path="tests/"
d "test"        && [ ! -d "$CODEBASE/tests" ] && tests_path="test/"
d "spec"        && [ ! -d "$CODEBASE/tests" ] && [ ! -d "$CODEBASE/test" ] && tests_path="spec/"
d "__tests__"   && tests_path="__tests__/"

docs_path="docs/"
d "docs"        && docs_path="docs/"
d "doc"         && [ ! -d "$CODEBASE/docs" ] && docs_path="doc/"

# ── Detect entrypoints ────────────────────────────────────────────────────

entrypoints="[]"

# Node.js — main field in package.json
if f "package.json"; then
  pkg="$CODEBASE/package.json"
  main_file=$(jq -r '.main // ""' "$pkg" 2>/dev/null || echo "")
  if [ -n "$main_file" ] && [ "$main_file" != "null" ]; then
    entrypoints=$(jq -n --arg path "$main_file" '[{"type":"http","path":$path}]')
  fi
  # Check common entry files
  for ep in "src/server.ts" "src/server.js" "src/index.ts" "src/index.js" \
            "src/app.ts" "src/app.js" "server.ts" "server.js" "index.ts" "index.js" \
            "app.ts" "app.js"; do
    if f "$ep"; then
      entrypoints=$(echo "$entrypoints" | jq --arg p "$ep" '. + [{"type":"http","path":$p}]' 2>/dev/null || echo "$entrypoints")
      break
    fi
  done
  # CLI entry
  bin_field=$(jq -r '.bin // "" | if type == "object" then keys[0] else . end' "$pkg" 2>/dev/null || echo "")
  if [ -n "$bin_field" ] && [ "$bin_field" != "null" ] && [ "$bin_field" != "" ]; then
    for ep in "src/cli.ts" "src/cli.js" "bin/cli.js" "bin/index.js"; do
      if f "$ep"; then
        entrypoints=$(echo "$entrypoints" | jq --arg p "$ep" '. + [{"type":"cli","path":$p}]' 2>/dev/null || echo "$entrypoints")
        break
      fi
    done
  fi
fi

# Go — cmd/ subdirs are entrypoints
if f "go.mod" && d "cmd"; then
  for ep_dir in "$CODEBASE/cmd"/*/; do
    [ -d "$ep_dir" ] && ep_name=$(basename "$ep_dir") && \
      entrypoints=$(echo "$entrypoints" | jq --arg p "cmd/$ep_name/" '. + [{"type":"cli","path":$p}]' 2>/dev/null || echo "$entrypoints")
  done
fi

# Python — check for manage.py (Django), app.py, main.py, __main__.py
if f "manage.py"; then
  entrypoints=$(echo "$entrypoints" | jq '. + [{"type":"http","path":"manage.py"}]' 2>/dev/null || echo "$entrypoints")
elif f "app.py"; then
  entrypoints=$(echo "$entrypoints" | jq '. + [{"type":"http","path":"app.py"}]' 2>/dev/null || echo "$entrypoints")
elif f "main.py"; then
  entrypoints=$(echo "$entrypoints" | jq '. + [{"type":"http","path":"main.py"}]' 2>/dev/null || echo "$entrypoints")
fi

# Deduplicate entrypoints
entrypoints=$(echo "$entrypoints" | jq 'unique_by(.path)' 2>/dev/null || echo "$entrypoints")

# ── Confidence scoring ────────────────────────────────────────────────────
# Rules (from task spec):
#   config file signal  → 0.90–0.95
#   extension only      → 0.60–0.75
#   single weak signal  → 0.40–0.55
#   not detected        → 0.0

score_for() {
  case "$1" in
    config) echo "0.92" ;;
    ext)    echo "0.68" ;;
    weak)   echo "0.45" ;;
    none)   echo "0.0"  ;;
    *)      echo "0.0"  ;;
  esac
}

lang_score=$(score_for "$lang_conf")
frontend_score=$(score_for "$frontend_conf")
backend_score=$(score_for "$backend_conf")
db_score=$(score_for "$db_conf")
arch_score="0.60"
# Architecture confidence: higher if we had docker-compose services or strong dir signals
[ "$arch_style" != "unknown" ] && arch_score="0.72"
$monorepo && arch_score="0.88"
[ "${services:-1}" -ge 3 ] 2>/dev/null && arch_score="0.82"

# Entrypoints: moderate confidence unless we found explicit main/bin
ep_count=$(echo "$entrypoints" | jq 'length' 2>/dev/null || echo "0")
entrypoints_score="0.60"
[ "${ep_count:-0}" -gt 0 ] 2>/dev/null && entrypoints_score="0.75"

# ── Write confidence.json ─────────────────────────────────────────────────

jq -n \
  --argjson language     "$lang_score" \
  --argjson frontend     "$frontend_score" \
  --argjson backend      "$backend_score" \
  --argjson db           "$db_score" \
  --argjson architecture "$arch_score" \
  --argjson entrypoints  "$entrypoints_score" \
  '{
    language:     $language,
    frontend:     $frontend,
    backend:      $backend,
    db:           $db,
    architecture: $architecture,
    entrypoints:  $entrypoints
  }' > "$DISCOVERY_DIR/confidence.json"

# ── Write context.json ────────────────────────────────────────────────────

languages_json=$(words_to_json_array "$languages")

jq -n \
  --argjson languages    "$languages_json" \
  --arg     frontend     "$frontend" \
  --arg     backend      "$backend" \
  --arg     db           "$db" \
  --arg     arch_style   "$arch_style" \
  --argjson monorepo     "$monorepo" \
  --argjson services     "$services" \
  --arg     pkg_manager  "$pkg_manager" \
  --arg     linter       "$linter" \
  --arg     test_runner  "$test_runner" \
  --arg     bundler      "$bundler" \
  --arg     container    "$container" \
  --arg     src_path     "$src_path" \
  --arg     tests_path   "$tests_path" \
  --arg     docs_path    "$docs_path" \
  --argjson entrypoints  "$entrypoints" \
  '{
    stack: {
      languages: $languages,
      frontend:  (if $frontend == "null" then null else $frontend end),
      backend:   (if $backend  == "null" then null else $backend  end),
      db:        (if $db       == "null" then null else $db       end)
    },
    tools: {
      package_manager: (if $pkg_manager == "null" then null else $pkg_manager end),
      linter:          (if $linter      == "null" then null else $linter      end),
      test_runner:     (if $test_runner == "null" then null else $test_runner end),
      bundler:         (if $bundler     == "null" then null else $bundler     end),
      container:       (if $container   == "null" then null else $container   end)
    },
    arch: {
      style:    $arch_style,
      monorepo: $monorepo,
      services: $services
    },
    paths: {
      src:    $src_path,
      tests:  $tests_path,
      docs:   $docs_path,
      config: "."
    },
    entrypoints: $entrypoints
  }' > "$DISCOVERY_DIR/context.json"

echo "done"

# ════════════════════════════════════════════════════════════════════════════
# Summary
# ════════════════════════════════════════════════════════════════════════════

echo ""
echo "Results:"
printf "  Languages:    %s\n" "$(jq -r '.stack.languages | join(", ")' "$DISCOVERY_DIR/context.json")"
printf "  Frontend:     %s\n" "$(jq -r '.stack.frontend // "none"' "$DISCOVERY_DIR/context.json")"
printf "  Backend:      %s\n" "$(jq -r '.stack.backend // "none"' "$DISCOVERY_DIR/context.json")"
printf "  Database:     %s\n" "$(jq -r '.stack.db // "none"' "$DISCOVERY_DIR/context.json")"
printf "  Architecture: %s\n" "$(jq -r '.arch.style' "$DISCOVERY_DIR/context.json")"
printf "  Pkg manager:  %s\n" "$(jq -r '.tools.package_manager // "none"' "$DISCOVERY_DIR/context.json")"
echo ""
echo "Confidence:"
jq -r 'to_entries | .[] | "  \(.key): \(.value)"' "$DISCOVERY_DIR/confidence.json"
echo ""

# Warn about low-confidence fields
low_conf=$(jq -r 'to_entries | .[] | select(.value > 0 and .value < 0.75) | .key' "$DISCOVERY_DIR/confidence.json")
if [ -n "$low_conf" ]; then
  echo "Low-confidence fields (< 0.75) — review before proceeding:"
  for field in $low_conf; do
    printf "  %s\n" "$field"
  done
  echo ""
fi

# ── Update project.json ───────────────────────────────────────────────────────

if [ -f "$PROJECT_FILE" ]; then
  jq --arg path "$CODEBASE" \
    '.approach = "brownfield" | .codebase_path = $path' \
    "$PROJECT_FILE" > /tmp/scan_project_tmp.json && mv /tmp/scan_project_tmp.json "$PROJECT_FILE"
fi

WORKFLOW_FILE=".project/state/workflow.json"
if [ -f "$WORKFLOW_FILE" ]; then
  jq '.approach = "brownfield"' \
    "$WORKFLOW_FILE" > /tmp/scan_workflow_tmp.json && mv /tmp/scan_workflow_tmp.json "$WORKFLOW_FILE"
fi

echo "Scan complete. Output written to $DISCOVERY_DIR/"
echo "Run 'copilot-bootstrap discover' to start the brownfield discovery pipeline."

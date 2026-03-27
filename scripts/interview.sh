#!/bin/sh
# interview.sh — Greenfield interactive interview
#
# Asks questions for each incomplete step, saves answers to
# .greenfield/answers.json, and updates steps_completed.
#
# Usage: copilot-bootstrap interview

set -e

GREENFIELD_DIR=".greenfield"
ANSWERS_FILE="$GREENFIELD_DIR/answers.json"
PROJECT_FILE="project.json"

# ── Help ──────────────────────────────────────────────────────────────────────

if [ "$1" = "--help" ]; then
  echo "Usage: copilot-bootstrap interview"
  echo ""
  echo "Runs the interactive greenfield interview to collect project answers."
  echo "Produces .greenfield/answers.json with normalized structured data."
  echo ""
  echo "Interview steps:"
  echo "  1. idea         — project idea and pain points"
  echo "  2. project_info — name, type, domain"
  echo "  3. users        — user roles and descriptions"
  echo "  4. features     — core features with priority"
  echo "  5. tech         — stack choices with smart defaults"
  echo "  6. complexity   — complexity level and autonomy"
  echo ""
  echo "After interview, run: copilot-bootstrap build-context"
  exit 0
fi

# ── Dependency check ──────────────────────────────────────────────────────────

if ! command -v jq > /dev/null 2>&1; then
  echo "Error: jq is required. Install it with: apt install jq / brew install jq"
  exit 1
fi

# ── Setup ─────────────────────────────────────────────────────────────────────

mkdir -p "$GREENFIELD_DIR"

if [ ! -f "$ANSWERS_FILE" ]; then
  jq -n '{"collected_at": null, "steps_completed": []}' > "$ANSWERS_FILE"
fi

# ── Prerequisite check ────────────────────────────────────────────────────────

if [ ! -f "$PROJECT_FILE" ]; then
  echo "Error: project.json not found. Run 'copilot-bootstrap init' first."
  exit 1
fi

APPROACH=$(jq -r '.approach // ""' "$PROJECT_FILE")
if [ "$APPROACH" != "greenfield" ]; then
  jq '.approach = "greenfield"' "$PROJECT_FILE" > /tmp/proj_tmp.json && mv /tmp/proj_tmp.json "$PROJECT_FILE"
fi

# ── Progress display ──────────────────────────────────────────────────────────

STEPS="idea project_info users features tech complexity"
COMPLETED=$(jq -r '.steps_completed // [] | join(" ")' "$ANSWERS_FILE" 2>/dev/null || echo "")
TOTAL_STEPS=6
DONE_COUNT=0

echo "Greenfield interview"
echo ""

for step in $STEPS; do
  case " $COMPLETED " in
    *" $step "*) printf "  ✔ %s\n" "$step"; DONE_COUNT=$((DONE_COUNT + 1)) ;;
    *)           printf "  ○ %s\n" "$step" ;;
  esac
done

echo ""

if [ "$DONE_COUNT" -eq "$TOTAL_STEPS" ]; then
  echo "Interview complete. Run 'copilot-bootstrap build-context' to continue."
  exit 0
fi

REMAINING=$((TOTAL_STEPS - DONE_COUNT))
echo "Progress: $DONE_COUNT/$TOTAL_STEPS steps complete. $REMAINING remaining."
echo ""

# ── Helpers ───────────────────────────────────────────────────────────────────

ask() {
  # ask PROMPT [DEFAULT]
  _prompt="$1"; _default="$2"
  if [ -n "$_default" ]; then
    printf "%s [%s]: " "$_prompt" "$_default" >&2
  else
    printf "%s: " "$_prompt" >&2
  fi
  read -r _answer
  if [ -z "$_answer" ] && [ -n "$_default" ]; then
    _answer="$_default"
  fi
  echo "$_answer"
}

mark_complete() {
  _step="$1"
  COMPLETED=$(jq -r '.steps_completed // [] | join(" ")' "$ANSWERS_FILE")
  case " $COMPLETED " in
    *" $_step "*) ;;  # already there
    *)
      jq --arg s "$_step" '.steps_completed += [$s]' "$ANSWERS_FILE" > /tmp/ans_tmp.json \
        && mv /tmp/ans_tmp.json "$ANSWERS_FILE"
      ;;
  esac
}

merge_field() {
  # merge_field KEY VALUE  — sets .KEY = VALUE in answers.json
  _key="$1"; _val="$2"
  jq --arg k "$_key" --argjson v "$_val" '.[$k] = $v' "$ANSWERS_FILE" > /tmp/ans_tmp.json \
    && mv /tmp/ans_tmp.json "$ANSWERS_FILE"
}

# ── Step: idea ────────────────────────────────────────────────────────────────

case " $COMPLETED " in *" idea "*) ;; *)
  echo "── Step 1/6: Idea ────────────────────────────────────────"
  idea=$(ask "Describe your project idea (what it does, what problem it solves)")
  pain=$(ask "What are the main pain points it addresses")

  jq --arg idea "$idea" --arg pain "$pain" \
    '.idea = {"description": $idea, "pain_points": $pain}' \
    "$ANSWERS_FILE" > /tmp/ans_tmp.json && mv /tmp/ans_tmp.json "$ANSWERS_FILE"
  mark_complete "idea"
  echo ""
  ;;
esac

# ── Step: project_info ────────────────────────────────────────────────────────

case " $COMPLETED " in *" project_info "*) ;; *)
  echo "── Step 2/6: Project Info ────────────────────────────────"
  proj_name=$(ask "Project name (slug, e.g. my-app)")
  echo "Types: web, api, cli, mobile, desktop, library, agent, ai-system"
  proj_type=$(ask "Project type" "web")
  proj_domain=$(ask "Domain (e.g. fintech, productivity, devtools, healthcare)")

  jq --arg name "$proj_name" --arg type "$proj_type" --arg domain "$proj_domain" \
    '.project_info = {"name": $name, "type": $type, "domain": $domain}' \
    "$ANSWERS_FILE" > /tmp/ans_tmp.json && mv /tmp/ans_tmp.json "$ANSWERS_FILE"

  # Sync name/type/domain into project.json
  jq --arg name "$proj_name" --arg type "$proj_type" --arg domain "$proj_domain" \
    '.name = $name | .type = $type | .domain = $domain' \
    "$PROJECT_FILE" > /tmp/proj_tmp.json && mv /tmp/proj_tmp.json "$PROJECT_FILE"

  mark_complete "project_info"
  echo ""
  ;;
esac

# ── Step: users ───────────────────────────────────────────────────────────────

case " $COMPLETED " in *" users "*) ;; *)
  echo "── Step 3/6: Users ──────────────────────────────────────"
  echo "Enter user roles one per line. Press Enter on empty line when done."
  users_json="[]"
  i=1
  while true; do
    role=$(ask "  Role $i (or Enter to finish)")
    [ -z "$role" ] && break
    desc=$(ask "  Description for '$role'")
    users_json=$(echo "$users_json" | jq --arg r "$role" --arg d "$desc" '. += [{"role": $r, "description": $d}]')
    i=$((i + 1))
  done

  jq --argjson users "$users_json" '.users = $users' \
    "$ANSWERS_FILE" > /tmp/ans_tmp.json && mv /tmp/ans_tmp.json "$ANSWERS_FILE"
  mark_complete "users"
  echo ""
  ;;
esac

# ── Step: features ────────────────────────────────────────────────────────────

case " $COMPLETED " in *" features "*) ;; *)
  echo "── Step 4/6: Features ───────────────────────────────────"
  echo "Enter core features one per line. Press Enter on empty line when done."
  features_json="[]"
  i=1
  while true; do
    feat=$(ask "  Feature $i (or Enter to finish)")
    [ -z "$feat" ] && break
    echo "  Priority: high, medium, low"
    prio=$(ask "  Priority for '$feat'" "medium")
    features_json=$(echo "$features_json" | jq --arg f "$feat" --arg p "$prio" '. += [{"name": $f, "priority": $p}]')
    i=$((i + 1))
  done

  jq --argjson features "$features_json" '.features = $features' \
    "$ANSWERS_FILE" > /tmp/ans_tmp.json && mv /tmp/ans_tmp.json "$ANSWERS_FILE"
  mark_complete "features"
  echo ""
  ;;
esac

# ── Step: tech ────────────────────────────────────────────────────────────────

case " $COMPLETED " in *" tech "*) ;; *)
  echo "── Step 5/6: Tech Stack ─────────────────────────────────"
  proj_type=$(jq -r '.project_info.type // "web"' "$ANSWERS_FILE")

  echo "Languages: typescript, javascript, python, go, rust, java, kotlin"
  lang=$(ask "Primary language" "typescript")

  frontend=""
  case "$proj_type" in web|mobile)
    echo "Frontend: react, vue, nextjs, svelte, angular, or leave blank"
    frontend=$(ask "Frontend framework" "react")
    ;;
  esac

  echo "Backend: express, fastapi, django, gin, axum, spring, or leave blank"
  backend=$(ask "Backend framework")

  echo "Database: postgres, mysql, sqlite, mongodb, redis, or leave blank"
  db=$(ask "Database" "postgres")

  pkg_mgr=$(ask "Package manager (leave blank for smart default)")
  test_runner=$(ask "Test runner (leave blank for smart default)")

  jq --arg lang "$lang" --arg frontend "$frontend" --arg backend "$backend" \
     --arg db "$db" --arg pkg "$pkg_mgr" --arg test "$test_runner" \
    '.tech = {
       "languages": (if $lang == "" then [] else [$lang] end),
       "frontend":  (if $frontend  == "" then null else $frontend  end),
       "backend":   (if $backend   == "" then null else $backend   end),
       "db":        (if $db        == "" then null else $db        end),
       "package_manager": (if $pkg  == "" then null else $pkg  end),
       "test_runner":     (if $test == "" then null else $test end)
     }' \
    "$ANSWERS_FILE" > /tmp/ans_tmp.json && mv /tmp/ans_tmp.json "$ANSWERS_FILE"
  mark_complete "tech"
  echo ""
  ;;
esac

# ── Step: complexity ──────────────────────────────────────────────────────────

case " $COMPLETED " in *" complexity "*) ;; *)
  echo "── Step 6/6: Complexity ─────────────────────────────────"
  echo "Levels: startup (MVP), standard (production), enterprise (regulated)"
  level=$(ask "Complexity level" "startup")
  echo "Autonomy: manual (review every step), semi (review key points), auto (minimal review)"
  autonomy=$(ask "Autonomy level" "semi")

  proj_type=$(jq -r '.project_info.type // "web"' "$ANSWERS_FILE")
  adlc="false"
  case "$proj_type" in agent|ai-system) adlc="true" ;; esac

  jq --arg level "$level" --arg autonomy "$autonomy" --argjson adlc "$adlc" \
    '.complexity = {"level": $level, "autonomy": $autonomy, "adlc": $adlc}' \
    "$ANSWERS_FILE" > /tmp/ans_tmp.json && mv /tmp/ans_tmp.json "$ANSWERS_FILE"

  # Sync autonomy_level into project.json
  jq --arg a "$autonomy" '.autonomy_level = $a' \
    "$PROJECT_FILE" > /tmp/proj_tmp.json && mv /tmp/proj_tmp.json "$PROJECT_FILE"

  mark_complete "complexity"
  echo ""
  ;;
esac

# ── Stamp collected_at ────────────────────────────────────────────────────────

jq --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '.collected_at = $ts' \
  "$ANSWERS_FILE" > /tmp/ans_tmp.json && mv /tmp/ans_tmp.json "$ANSWERS_FILE"

# ── Done ──────────────────────────────────────────────────────────────────────

DONE_COUNT=$(jq '.steps_completed | length' "$ANSWERS_FILE")

echo "──────────────────────────────────────────────────────────"
echo "Interview complete ($DONE_COUNT/6 steps). Answers saved to $ANSWERS_FILE"
echo ""
echo "Next: copilot-bootstrap build-context"

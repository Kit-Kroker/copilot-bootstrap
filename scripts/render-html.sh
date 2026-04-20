#!/bin/sh
# render-html.sh — Render markdown reports in docs/ to styled HTML.
#
# Walks a directory for *.md files and emits a sibling *.html for each,
# using pandoc with an embedded stylesheet and rewriting .md cross-links
# to .html so generated reports link to each other correctly.
#
# Usage: copilot-bootstrap render-html [path] [--out DIR] [--clean]

set -e

ROOT="docs"
OUT_DIR=""
CLEAN="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h)
      cat <<'EOF'
Usage: copilot-bootstrap render-html [path] [--out DIR] [--clean]

Walks [path] (default: docs/) for *.md files and writes HTML next to each.

Options:
  --out DIR   Write HTML under DIR, mirroring the input tree, instead of
              placing each .html beside its .md.
  --clean     Delete every .html that has a matching .md, then exit.

Requires: pandoc (install with: apt install pandoc / brew install pandoc)
EOF
      exit 0
      ;;
    --out)
      shift
      OUT_DIR="$1"
      ;;
    --clean)
      CLEAN="true"
      ;;
    *)
      ROOT="$1"
      ;;
  esac
  shift
done

if [ ! -d "$ROOT" ]; then
  echo "Error: no such directory: $ROOT" >&2
  exit 1
fi

# ── Clean mode ────────────────────────────────────────────────────────────────

if [ "$CLEAN" = "true" ]; then
  REMOVED=0
  find "$ROOT" -type f -name "*.md" | while read -r md; do
    html="${md%.md}.html"
    if [ -f "$html" ]; then
      rm -f "$html"
      REMOVED=$((REMOVED + 1))
      echo "  removed $html"
    fi
  done
  echo "Clean complete."
  exit 0
fi

# ── Render mode ───────────────────────────────────────────────────────────────

if ! command -v pandoc > /dev/null 2>&1; then
  echo "Error: pandoc is required. Install with: apt install pandoc / brew install pandoc" >&2
  exit 1
fi

if ! command -v python3 > /dev/null 2>&1; then
  echo "Error: python3 is required." >&2
  exit 1
fi

# Stylesheet embedded via pandoc --include-in-header.
STYLE_FILE=$(mktemp -t cb-render-style.XXXXXX.html)
trap 'rm -f "$STYLE_FILE"' EXIT

cat > "$STYLE_FILE" <<'CSSEOF'
<style>
  :root { color-scheme: light dark; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    max-width: 960px;
    margin: 2rem auto;
    padding: 0 1.25rem;
    line-height: 1.55;
    color: #222;
    background: #fdfdfd;
  }
  @media (prefers-color-scheme: dark) {
    body { color: #ddd; background: #1a1a1a; }
    a { color: #7ab7ff; }
    code, pre { background: #2a2a2a; }
    table th { background: #2a2a2a; }
    table, th, td { border-color: #444; }
    blockquote { border-left-color: #444; color: #aaa; }
  }
  h1, h2, h3, h4 { line-height: 1.25; margin-top: 2rem; }
  h1 { border-bottom: 1px solid #ddd; padding-bottom: 0.3rem; }
  h2 { border-bottom: 1px solid #eee; padding-bottom: 0.2rem; }
  code, pre { font-family: "SF Mono", Menlo, Consolas, monospace; font-size: 0.92em; }
  code { background: #f3f3f3; padding: 0.1em 0.35em; border-radius: 3px; }
  pre { background: #f6f8fa; padding: 0.9rem 1rem; overflow-x: auto; border-radius: 5px; }
  pre code { background: transparent; padding: 0; }
  table { border-collapse: collapse; margin: 1rem 0; width: 100%; font-size: 0.95em; }
  th, td { border: 1px solid #ddd; padding: 0.45rem 0.7rem; text-align: left; vertical-align: top; }
  th { background: #f6f8fa; }
  blockquote { border-left: 4px solid #ddd; color: #666; padding: 0.2rem 1rem; margin: 1rem 0; }
  hr { border: none; border-top: 1px solid #ddd; margin: 2rem 0; }
  a { color: #0366d6; text-decoration: none; }
  a:hover { text-decoration: underline; }
  .source-note { color: #888; font-style: italic; font-size: 0.9em; }
</style>
CSSEOF

# Collect markdown files.
MD_FILES=$(find "$ROOT" -type f -name "*.md" | sort)

if [ -z "$MD_FILES" ]; then
  echo "No markdown files found under $ROOT."
  exit 0
fi

COUNT=0
echo "$MD_FILES" | while IFS= read -r md; do
  [ -z "$md" ] && continue

  if [ -n "$OUT_DIR" ]; then
    rel="${md#$ROOT/}"
    html="$OUT_DIR/${rel%.md}.html"
  else
    html="${md%.md}.html"
  fi

  mkdir -p "$(dirname "$html")"

  # Title from first H1 line, fallback to filename.
  title=$(awk '/^# /{sub(/^# */, ""); print; exit}' "$md")
  [ -z "$title" ] && title=$(basename "$md" .md)

  pandoc \
    --from=gfm \
    --to=html5 \
    --standalone \
    --metadata title="$title" \
    --include-in-header="$STYLE_FILE" \
    --output="$html" \
    "$md"

  # Rewrite relative .md links → .html so the generated site is navigable.
  # Absolute URLs and anchor-only links are left alone.
  python3 - "$html" <<'PYEOF'
import re, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    html = f.read()
def repl(m):
    url = m.group(2)
    if url.startswith(('http://', 'https://', 'mailto:', '#')):
        return m.group(0)
    # split fragment
    frag = ''
    if '#' in url:
        url, frag = url.split('#', 1)
        frag = '#' + frag
    if url.endswith('.md'):
        url = url[:-3] + '.html'
    return f'{m.group(1)}{url}{frag}{m.group(3)}'
html = re.sub(r'(href="|src=")([^"]+)(")', repl, html)
with open(path, 'w', encoding='utf-8') as f:
    f.write(html)
PYEOF

  COUNT=$((COUNT + 1))
  echo "  rendered $md → $html"
done

TOTAL=$(echo "$MD_FILES" | grep -c .)
echo ""
echo "Rendered $TOTAL file(s)."

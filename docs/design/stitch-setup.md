# Google Stitch — Setup Guide

Google Stitch generates high-fidelity HTML + TailwindCSS screens from natural language prompts via its MCP HTTP endpoint.

## How Stitch Fits in the Workflow

```
flows.md  →  [Stitch MCP]  →  docs/design/screens/*.html  →  spec
```

The Designer agent calls Stitch tools after `flows.md` is complete. Generated screens feed into the Spec agent for implementation handoff.

---

## Step 1 — Get an API Key

1. Go to [stitch.withgoogle.com](https://stitch.withgoogle.com) and sign in with your Google account
2. Open your account settings and generate an API key
3. Copy the key — you will need it in Step 2

---

## Step 2 — Set the API Key

Add `STITCH_API_KEY` to your environment. Do not commit this value.

**Option A — `.env` file** (add to `.gitignore`):
```sh
echo "STITCH_API_KEY=your-key-here" >> .env
```

**Option B — shell profile** (`~/.bashrc` / `~/.zshrc`):
```sh
export STITCH_API_KEY=your-key-here
```

**Option C — VS Code `settings.json`** (user settings):
```json
"terminal.integrated.env.linux": {
  "STITCH_API_KEY": "your-key-here"
}
```

---

## Step 3 — MCP Configuration (already included)

The MCP server is pre-configured at `.vscode/mcp.json` using the official Stitch HTTP endpoint — no local server or npm install required:

```json
{
  "servers": {
    "stitch": {
      "url": "https://stitch.googleapis.com/mcp",
      "type": "http",
      "headers": {
        "Accept": "application/json",
        "X-Goog-Api-Key": "${env:STITCH_API_KEY}"
      }
    }
  }
}
```

VS Code reads this file automatically. Restart VS Code after setting `STITCH_API_KEY`.

---

## Step 4 — Verify

Open Copilot Chat and type `#`. You should see `stitch` tools in the list:

| Tool | What it does |
|------|-------------|
| `stitch/create_project` | Create a new Stitch project |
| `stitch/generate_screen_from_text` | Generate a UI screen from a text prompt |
| `stitch/get_screen` | Retrieve a generated screen by ID |
| `stitch/list_projects` | List your Stitch projects |

If the tools do not appear, check: **View → Output → MCP → stitch**

---

## Usage

Stitch runs automatically in the Designer agent after flows are complete.

To run it manually:

```
/generate-stitch-screens              Generate all screens from ia.md
/generate-stitch-screens login        Generate or regenerate one specific screen
```

---

## Outputs

| File | Contents |
|------|----------|
| `docs/design/screens/{screen-name}.html` | HTML + TailwindCSS screen |
| `docs/design/screens/index.md` | Screen inventory with states and notes |

Screens can be opened directly in a browser or exported to Figma via [stitch.withgoogle.com](https://stitch.withgoogle.com).

---

## Graceful Fallback

If the MCP server is not reachable or the API key is missing, the Designer agent logs a note in `docs/design/screens/index.md` and continues without blocking. Run `/generate-stitch-screens` later once setup is complete.

---

## Troubleshooting

**Stitch tools not showing in VS Code**
- Confirm `STITCH_API_KEY` is set: `echo $STITCH_API_KEY`
- Restart VS Code after setting the env var
- Check: **View → Output → MCP → stitch**

**401 Unauthorized**
- The API key is invalid or expired — generate a new one at [stitch.withgoogle.com](https://stitch.withgoogle.com)

**Generation limit reached**
- Use `/generate-stitch-screens {screen-name}` to regenerate only specific screens
- Check your usage at [stitch.withgoogle.com](https://stitch.withgoogle.com)

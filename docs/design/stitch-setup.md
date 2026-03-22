# Google Stitch — Setup Guide

Google Stitch generates high-fidelity HTML + TailwindCSS screens from natural language prompts via the `@google/stitch-sdk` MCP integration.

## How Stitch Fits in the Workflow

```
flows.md  →  [Stitch MCP]  →  docs/design/screens/*.html  →  spec
```

The Designer agent calls Stitch tools after `flows.md` is complete. Generated screens feed into the Spec agent for implementation handoff.

---

## Step 1 — Get an API Key

1. Go to [stitch.withgoogle.com](https://stitch.withgoogle.com) and sign in with your Google account
2. Open your account settings and generate an API key
3. Copy the key — you will need it in Step 3

---

## Step 2 — Install the SDK

```sh
npm install @google/stitch-sdk
```

---

## Step 3 — Set the API Key

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

## Step 4 — Configure the MCP Server in VS Code

The MCP configuration is already included at `.vscode/mcp.json`:

```json
{
  "servers": {
    "stitch": {
      "command": "node",
      "args": ["scripts/stitch-mcp.js"],
      "env": {
        "STITCH_API_KEY": "${env:STITCH_API_KEY}"
      }
    }
  }
}
```

`scripts/stitch-mcp.js` starts the `StitchProxy` MCP server using your API key. VS Code reads this file automatically.

---

## Step 5 — Verify

Restart VS Code, then open Copilot Chat and type `#`. You should see `stitch` tools in the list:

| Tool | What it does |
|------|-------------|
| `stitch/create_project` | Create a new Stitch project |
| `stitch/generate_screen_from_text` | Generate a UI screen from a text prompt |
| `stitch/get_screen` | Retrieve a generated screen by ID |
| `stitch/list_projects` | List your Stitch projects |

If the tools do not appear, check the MCP server output in **View → Output → MCP**.

---

## Usage

Stitch runs automatically in the Designer agent after flows are complete.

To run it manually via slash command:

```
/stitch                        Generate all screens from ia.md
/stitch login screen           Generate or regenerate one specific screen
```

---

## Outputs

| File | Contents |
|------|----------|
| `docs/design/screens/{screen-name}.html` | HTML + TailwindCSS screen output |
| `docs/design/screens/index.md` | Screen inventory with states and notes |

Screens can be:
- Opened directly in a browser for preview
- Exported to Figma via [stitch.withgoogle.com](https://stitch.withgoogle.com) for refinement
- Used directly as implementation reference

---

## Graceful Fallback

If the MCP server is not configured or the API key is missing, the Designer agent logs a warning in `docs/design/screens/index.md` and continues to the spec phase without blocking. Run `/stitch` later once setup is complete.

---

## Troubleshooting

**Stitch tools not showing in VS Code**
- Confirm `STITCH_API_KEY` is set in your environment: `echo $STITCH_API_KEY`
- Check the MCP server log: **View → Output → MCP → stitch**
- Run the script manually to see errors: `STITCH_API_KEY=your-key node scripts/stitch-mcp.js`
- Restart VS Code after changing `.vscode/mcp.json`

**`Error: Cannot find module '@google/stitch-sdk'`**
- Run `npm install @google/stitch-sdk` in the project root

**`StitchProxy is not a constructor`**
- Update the SDK: `npm install @google/stitch-sdk@latest`
- Check the SDK exports match — the API may have changed since this guide was written; refer to [github.com/google-labs-code/stitch-sdk](https://github.com/google-labs-code/stitch-sdk)

**Generation limit reached**
- Use `/stitch {screen-name}` to regenerate only specific screens
- Check your usage at [stitch.withgoogle.com](https://stitch.withgoogle.com)

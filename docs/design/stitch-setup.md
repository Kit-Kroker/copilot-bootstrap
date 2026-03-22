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
3. Copy the key — you will need it in Step 3

---

## Step 2 — Create an OAuth Client ID

VS Code requires a Google OAuth client ID to authenticate with the Stitch MCP endpoint.

1. Go to [console.cloud.google.com](https://console.cloud.google.com) → **APIs & Services → Credentials**
2. Click **Create Credentials → OAuth 2.0 Client ID**
3. Application type: **Desktop app**
4. Name it (e.g. "Stitch MCP") and click **Create**
5. Copy the **Client ID**

---

## Step 3 — Set Environment Variables

Add both values to your environment. Do not commit these.

**Shell profile** (`~/.bashrc` / `~/.zshrc`):
```sh
export STITCH_API_KEY=your-api-key-here
export STITCH_OAUTH_CLIENT_ID=your-client-id-here
```

Or **VS Code `settings.json`** (user settings):
```json
"terminal.integrated.env.linux": {
  "STITCH_API_KEY": "your-api-key-here",
  "STITCH_OAUTH_CLIENT_ID": "your-client-id-here"
}
```

---

## Step 4 — MCP Configuration (already included)

The MCP server is pre-configured at `.vscode/mcp.json`:

```json
{
  "servers": {
    "stitch": {
      "url": "https://stitch.googleapis.com/mcp",
      "type": "http",
      "headers": {
        "Accept": "application/json",
        "X-Goog-Api-Key": "${env:STITCH_API_KEY}"
      },
      "auth": {
        "type": "oauth",
        "clientId": "${env:STITCH_OAUTH_CLIENT_ID}"
      }
    }
  }
}
```

VS Code reads this file automatically. Restart VS Code after setting the env vars.

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

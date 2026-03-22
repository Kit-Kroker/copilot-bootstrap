#!/usr/bin/env node
/**
 * stitch-mcp.js — MCP proxy server for Google Stitch
 *
 * Starts the Stitch MCP proxy so VS Code can connect to it.
 * Requires STITCH_API_KEY environment variable.
 *
 * Usage (via mcp.json — do not run manually):
 *   node scripts/stitch-mcp.js
 */

const apiKey = process.env.STITCH_API_KEY;

if (!apiKey) {
  console.error('Error: STITCH_API_KEY environment variable is not set.');
  console.error('Get your API key at https://stitch.withgoogle.com and add it to your environment.');
  process.exit(1);
}

const { StitchProxy } = require('@google/stitch-sdk');

const proxy = new StitchProxy({ apiKey });
proxy.start();

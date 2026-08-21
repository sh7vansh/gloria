# Gloria

A containerized, persistent Chromium workstation for concurrent human and AI agent use. Humans interact with the live desktop via an in-browser HTML5 interface (noVNC), while AI agents control the same session, profile, and DOM via the Model Context Protocol (MCP).

```
Human  ───▶  noVNC (Port 8080)  ───┐
                                   ├──▶  Shared Chromium  ──▶  Persistent Profile (/data)
AI     ───▶  MCP   (Port 8787)  ───┘
```

---

## Features

- **Shared State**: Humans and AI agents operate on the exact same tabs, cookies, authenticated sessions, and DOM.
- **Instant Web Desktop**: Zero-login HTML5 desktop on `:8080` powered by noVNC, TigerVNC, and Openbox.
- **AI-Ready MCP Server**: First-class MCP endpoint on `:8787/mcp` powered by [Chrome Bridge](https://github.com/sh7vansh/chrome-bridge).
- **Ad Blocking**: Pre-configured with uBlock Origin Lite (Basic mode) for lightweight, prompt-free browsing.
- **Persistent Storage**: Retains cookies, history, local storage, and downloads across restarts via a Docker volume.

---

## Quick Start

```bash
git clone https://github.com/sh7vansh/gloria.git
cd gloria
docker compose up -d
```

### Endpoints

| Interface | URL | Auth | Description |
|---|---|---|---|
| **Web Desktop** | `http://localhost:8080` | None | Live browser GUI for human access |
| **MCP Endpoint** | `http://localhost:8787/mcp` | None | AI agent interface (HTTP/SSE) |
| **Direct VNC** | `localhost:5901` | `gloria` | Native VNC viewer access |

## Remote AI Automation (MCP)

Gloria decouples the AI agent from the browser environment. By hosting Gloria on a remote server, VPS, or homelab, agents gain persistent, 24/7 browser control without consuming local system resources.

### MCP Client Setup

Add Gloria's endpoint to your MCP client configuration (Claude Desktop, Cursor, Antigravity, or custom agents):

```json
{
  "mcpServers": {
    "gloria": {
      "url": "http://<host>:8787/mcp"
    }
  }
}
```
*Use `localhost:8787/mcp` for local development, or your remote server/VPN IP for remote agents.*

### Minimal MCP Proxy

Gloria uses [`mcp-proxy`](https://pypi.org/project/mcp-proxy/) to bridge [Chrome Bridge](https://github.com/sh7vansh/chrome-bridge)'s stdio MCP server over streamable HTTP/SSE on port `8787`. This lightweight proxy forwards tool calls directly to the container's Native Messaging host with zero middleware bloat.

> [!WARNING]
> The MCP endpoint is unauthenticated by default and grants direct control over the live Chromium session and its authenticated state. Run Gloria on a private network, behind a VPN (e.g. Tailscale), or behind an authenticated reverse proxy.

---

## Configuration

Copy `.env.example` to `.env` to override defaults:

| Variable | Default | Description |
|---|---|---|
| `GLORIA_WEB_PORT` | `8080` | Web desktop host port |
| `GLORIA_MCP_PORT` | `8787` | MCP proxy host port |
| `GLORIA_VNC_PORT` | `5901` | Direct VNC host port |
| `GLORIA_SCREEN_WIDTH` | `1920` | Desktop width (px) |
| `GLORIA_SCREEN_HEIGHT` | `1080` | Desktop height (px) |
| `GLORIA_DATA` | `/data` | Persistent data mount path |
| `GLORIA_VNC_PASSWORD` | `gloria` | VNC access password |

---

## Storage Layout

All persistent data is stored in the `gloria-data` Docker volume under `/data`:

```
/data/
├── chromium/profile/     # Browser cookies, logins, and session data
├── downloads/            # Downloads directory (linked to ~/Downloads)
├── desktop/              # Desktop files (linked to ~/Desktop)
└── gloria/logs/          # Process logs (supervisord, chromium, novnc, mcp)
```

---

## License

[MIT](LICENSE)




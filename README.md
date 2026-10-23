# roblox-g

## Connect Claude to Roblox Studio (Windows)

1. Open Roblox Studio and turn on **Studio as MCP server** (Assistant settings).
2. Download and double-click [`setup-roblox-studio-mcp.bat`](setup-roblox-studio-mcp.bat).
   If Windows SmartScreen appears, click **More info → Run anyway**.
3. From then on, double-click **Roblox Claude** on your desktop, open the AETHER
   place when asked, and press Enter. Claude reads the game brief and works through
   the release plan in Studio.

The script installs Claude Code if it's missing, registers Studio's MCP server
(`cmd.exe /c cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat`) with Claude Code for all
projects and with the Claude Desktop app, checks the connection, and creates the **Roblox Claude** desktop icon
(working folder: `Documents\Roblox Claude`, with the Studio tools pre-approved).
Restart Claude Desktop afterwards if you use it.

## Game brief and release plan

`workspace/` holds the files the setup copies into `Documents\Roblox Claude`, the
folder the desktop icon starts Claude in:

- `CLAUDE.md`: AETHER's design, code layout, known pitfalls and working rules.
  Claude reads it automatically, and the setup refreshes it on every run.
- `RELEASE-PLAN.md`: everything left before publishing and promoting. Claude
  checks items off as it goes. It's created once and never overwritten.
- `PROGRESS.md`: Claude's log of finished work. It's created once.

The setup `.bat` embeds copies of these files, so it works as a single download. If
you edit a file in `workspace/`, update the matching section in the `.bat`.

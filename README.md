# roblox-g

## Connect Claude to Roblox Studio (Windows)

1. Open Roblox Studio and turn on **Studio as MCP server** (Assistant settings).
2. Download and double-click [`setup-roblox-studio-mcp.bat`](setup-roblox-studio-mcp.bat).
   If Windows SmartScreen appears, click **More info → Run anyway**.
3. From then on, double-click **Roblox Claude** on your desktop. It opens Studio
   if needed and starts Claude already connected to it.

The script installs Claude Code if it's missing, registers Studio's MCP server
(`cmd.exe /c cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat`) with Claude Code for all
projects and with the Claude Desktop app, checks the connection, and creates the **Roblox Claude** desktop icon
(working folder: `Documents\Roblox Claude`, with the Studio tools pre-approved).
Restart Claude Desktop afterwards if you use it.

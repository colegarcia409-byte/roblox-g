# roblox-g

## Connect Claude to Roblox Studio (Windows)

1. Open Roblox Studio and turn on **Studio as MCP server** (Assistant settings).
2. Download and double-click [`setup-roblox-studio-mcp.bat`](setup-roblox-studio-mcp.bat).
   If Windows SmartScreen appears, click **More info → Run anyway**.

The script installs Claude Code if it's missing, registers Studio's MCP server
(`cmd.exe /c cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat`) with Claude Code for all
projects and with the Claude Desktop app, then checks the connection.
Restart Claude Desktop afterwards.

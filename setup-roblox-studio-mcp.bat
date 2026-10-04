<# :
@echo off
rem ---------------------------------------------------------------------------
rem  One-click setup: connects Claude (Claude Code + Claude Desktop) to
rem  Roblox Studio's built-in MCP server. Double-click this file to run it.
rem  The batch part just launches the PowerShell below this header.
rem ---------------------------------------------------------------------------
setlocal
set "SETUP_SCRIPT=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ([IO.File]::ReadAllText($env:SETUP_SCRIPT))"
echo.
pause
exit /b
#>

$ErrorActionPreference = 'Continue'

$ServerName = 'roblox-studio'
$McpBat     = Join-Path $env:LOCALAPPDATA 'Roblox\mcp.bat'
# Same launch command Studio gives you. %LOCALAPPDATA% stays literal so
# cmd.exe expands it each time the server starts.
$LaunchCmd  = 'cmd.exe'
$LaunchArgs = @('/c', 'cd /d %LOCALAPPDATA%\Roblox && .\mcp.bat')

function Step($msg) { Write-Host ''; Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "    $msg" -ForegroundColor Yellow }

Write-Host 'Roblox Studio -> Claude MCP setup' -ForegroundColor White

# 1. Roblox Studio's MCP server ------------------------------------------------
Step 'Checking for Roblox Studio MCP server'
if (Test-Path $McpBat) {
    Ok "Found $McpBat"
} else {
    Warn "Not found: $McpBat"
    Warn 'Open Roblox Studio > Assistant > settings and turn on "Studio as MCP server",'
    Warn 'then run this file again. Continuing so Claude is ready once you do.'
}

# 2. Claude Code CLI -------------------------------------------------------------
Step 'Checking for Claude Code'
function Find-Claude {
    $cmd = Get-Command claude -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $native = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
    if (Test-Path $native) { return $native }
    return $null
}

$claude = Find-Claude
if (-not $claude) {
    Warn 'Claude Code not found. Installing it (official installer)...'
    powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://claude.ai/install.ps1 | iex"
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'User') + ';' +
                [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $claude = Find-Claude
}

if ($claude) {
    Ok "Using $claude"

    Step "Registering '$ServerName' with Claude Code (all projects)"
    & $claude mcp remove $ServerName -s user 2>&1 | Out-Null
    & $claude mcp add -s user $ServerName $LaunchCmd @LaunchArgs
    if ($LASTEXITCODE -eq 0) { Ok 'Registered.' } else { Warn "claude mcp add exited with code $LASTEXITCODE" }
} else {
    Warn 'Could not install Claude Code automatically. Skipping CLI setup.'
}

# 3. Claude Desktop app ----------------------------------------------------------
Step 'Configuring Claude Desktop'
$configPaths = @(Join-Path $env:APPDATA 'Claude\claude_desktop_config.json')
# Microsoft Store installs keep their config in a virtualized folder.
Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Packages') -Directory -Filter 'Claude_*' -ErrorAction SilentlyContinue |
    ForEach-Object { $configPaths += Join-Path $_.FullName 'LocalCache\Roaming\Claude\claude_desktop_config.json' }

$desktopDone = $false
foreach ($path in $configPaths) {
    $dir = Split-Path $path
    if (-not (Test-Path $dir)) { continue }   # that install doesn't exist
    try {
        $config = $null
        if (Test-Path $path) {
            $raw = [IO.File]::ReadAllText($path)
            if ($raw.Trim()) { $config = $raw | ConvertFrom-Json -ErrorAction Stop }
            Copy-Item $path "$path.bak" -Force
        }
        if (-not $config) { $config = New-Object psobject }
        if (-not $config.PSObject.Properties['mcpServers']) {
            $config | Add-Member -NotePropertyName mcpServers -NotePropertyValue (New-Object psobject)
        }
        $entry = [pscustomobject]@{ command = $LaunchCmd; args = $LaunchArgs }
        $config.mcpServers | Add-Member -NotePropertyName $ServerName -NotePropertyValue $entry -Force
        [IO.File]::WriteAllText($path, ($config | ConvertTo-Json -Depth 32), (New-Object Text.UTF8Encoding $false))
        Ok "Updated $path"
        $desktopDone = $true
    } catch {
        Warn "Could not update ${path}: $($_.Exception.Message)"
    }
}
if (-not $desktopDone) { Warn 'Claude Desktop not found. Skipped (Claude Code is enough).' }

# 4. Verify ----------------------------------------------------------------------
if ($claude) {
    Step 'Checking the connection (Roblox Studio must be open)'
    & $claude mcp list
}

Write-Host ''
Write-Host 'Done.' -ForegroundColor Green
Write-Host "  - If '$ServerName' shows as connected above, you're all set."
Write-Host '  - If it failed: open Roblox Studio (with "Studio as MCP server" on) and run this again.'
Write-Host '  - Claude Desktop: fully quit it (system tray > Quit) and reopen to load the server.'

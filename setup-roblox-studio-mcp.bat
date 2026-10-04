<# :
@echo off
rem ---------------------------------------------------------------------------
rem  One-click setup: connects Claude to Roblox Studio's built-in MCP server and
rem  puts a "Roblox Claude" icon on your desktop. Double-click this file once.
rem  After that, just double-click the desktop icon.
rem  The batch part only launches the PowerShell below this header.
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
$AppDir     = Join-Path $env:LOCALAPPDATA 'RobloxClaude'
$WorkDir    = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Roblox Claude'

function Step($msg) { Write-Host ''; Write-Host "==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "    $msg" -ForegroundColor Yellow }

Write-Host 'Roblox Studio -> Claude setup' -ForegroundColor White

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

# 4. "Roblox Claude" desktop icon -----------------------------------------------
Step 'Creating the "Roblox Claude" desktop icon'
New-Item -ItemType Directory -Force -Path $AppDir, (Join-Path $WorkDir '.claude') | Out-Null

# Let Claude use the Studio tools in this folder without asking every time.
$settingsPath = Join-Path $WorkDir '.claude\settings.json'
if (-not (Test-Path $settingsPath)) {
    [IO.File]::WriteAllText($settingsPath,
        "{`n  `"permissions`": {`n    `"allow`": [`"mcp__$ServerName`"]`n  }`n}`n",
        (New-Object Text.UTF8Encoding $false))
}

# The launcher: opens Studio if needed, then starts Claude already pointed at it.
$launcher = @'
$host.UI.RawUI.WindowTitle = 'Roblox Claude'
$WorkDir = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Roblox Claude'

if (-not (Get-Process RobloxStudioBeta -ErrorAction SilentlyContinue)) {
    Write-Host 'Starting Roblox Studio...' -ForegroundColor Cyan
    $exe = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Roblox\Versions') -Recurse -Filter RobloxStudioBeta.exe -ErrorAction SilentlyContinue |
           Sort-Object LastWriteTime -Descending | Select-Object -First 1
    try {
        if ($exe) { Start-Process $exe.FullName } else { Start-Process 'roblox-studio:' }
        Start-Sleep -Seconds 15
    } catch {
        Write-Host 'Could not start Roblox Studio. Open it yourself, then press Enter.' -ForegroundColor Yellow
        Read-Host | Out-Null
    }
}

$claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claude) { $claude = Join-Path $env:USERPROFILE '.local\bin\claude.exe' }

Set-Location $WorkDir
& $claude 'You are connected to my open Roblox Studio through the roblox-studio MCP tools. Check the connection by telling me what is in Workspace, then ask me what I want to build.'
'@
$launcherPath = Join-Path $AppDir 'start.ps1'
[IO.File]::WriteAllText($launcherPath, $launcher, (New-Object Text.UTF8Encoding $true))

$shortcutPath = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Roblox Claude.lnk'
try {
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut($shortcutPath)
    $lnk.TargetPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
    $lnk.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$launcherPath`""
    $lnk.WorkingDirectory = $WorkDir
    $studioExe = Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Roblox\Versions') -Recurse -Filter RobloxStudioBeta.exe -ErrorAction SilentlyContinue |
                 Select-Object -First 1
    if ($studioExe) { $lnk.IconLocation = "$($studioExe.FullName),0" }
    $lnk.Save()
    Ok "Created $shortcutPath"
} catch {
    Warn "Could not create the desktop icon: $($_.Exception.Message)"
}

# 5. Verify + launch -------------------------------------------------------------
if ($claude) {
    Step 'Checking the connection'
    & $claude mcp list
}

Write-Host ''
Write-Host 'All set!' -ForegroundColor Green
Write-Host '  From now on: double-click "Roblox Claude" on your desktop.'
Write-Host '  It opens Roblox Studio (if needed) and starts Claude connected to it.'
if (Test-Path $shortcutPath) {
    Write-Host ''
    Write-Host 'Opening Roblox Claude now...' -ForegroundColor Cyan
    Start-Process $shortcutPath
}

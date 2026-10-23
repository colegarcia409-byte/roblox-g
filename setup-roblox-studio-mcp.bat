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

# Game brief + release plan, so Claude picks up where the last session stopped.
# CLAUDE.md is always refreshed; the plan and progress log are only created once
# because Claude checks items off in them as it works.
$utf8 = New-Object Text.UTF8Encoding $false
$brief = @'
# AETHER — Claude project brief

You are working on **AETHER**, Cole's Roblox tactical FPS (CS:GO / Call of Duty style).
The game lives in the Roblox Studio place that is open on this PC. You reach it
through the `roblox-studio` MCP tools (`execute_luau`, `multi_edit`, `script_read`,
`start_stop_play`, `screen_capture`, `inspect_instance`, `insert_asset`, `search_asset`, …).

**Goal:** finish the game so it is ready to publish and promote. Work through
`RELEASE-PLAN.md` top to bottom.

## How to work (Cole's standing instructions)

- **Do not stop to write progress reports.** Keep building, testing and fixing until
  every item in `RELEASE-PLAN.md` is checked off. Cole has said: "why did you stop.
  continue make it look even better looks sloppy like you arent even trying."
- Quality bar: "do your best work, be confident in the final product, make no
  mistakes", "make this a masterpiece". Polished, clean, nothing floating, nothing
  clipping, no dead ends.
- **Improve, don't delete.** Don't remove Cole's existing work unless it's broken
  and you're replacing it with something better.
- **Verify everything yourself**: playtest (`start_stop_play`), take
  `screen_capture`s, measure with `execute_luau`. Never assume a change worked.
- Only ask Cole something when you truly can't proceed (things only he can do are
  marked **[COLE]** in the plan). Ask, then keep working on other items.
- After each finished section, check its boxes in `RELEASE-PLAN.md`, add a line to
  `PROGRESS.md`, and remind Cole to **save the place (Ctrl+S)** — you can't save it.
- If another AI session is also editing the place, don't touch what it's working on.

## First thing every session

The notes below are from 13 Sept 2026 and the place may have changed since.
**Inspect the place before editing**: list ServerScriptService,
StarterPlayerScripts, ReplicatedStorage and Workspace, and read the scripts you're
about to change. Then read `PROGRESS.md` to see what's already done.

## Game design (as decided with Cole)

- **Mode: Search & Destroy.** In-game warmup of 60 s with instant respawn (or until
  the server is full), then first to **13** round wins. No respawn mid-round. Win a
  round by eliminating the other team, or by planting the bomb and defending it for
  60 s → map "explodes" → everything resets for the next round. A solo player is
  still dropped into a match for testing.
- **Map: AETHER.** Futuristic, flying cars, some wrecked. Mix of clean utopian
  (rich district) and cyberpunk (poor district). Golden hour / dusk. Lighting "not
  too bright, not too dark — beautiful". The hover bus can be entered and shot out
  of. Smooth flow, no dead ends.
- **First person**: realistic CS:GO/COD-style arms and hands, customizable gloves.
  All guns, knives and utilities with correct orientation, animations (including
  mag-out/mag-in reloads) and sounds. Scroll wheel cycles weapons and utilities.
- **Menu**: COD-style loadout/armory. Home screen hero is a military workbench
  with the player's equipped primary, sidearm and knife lying on it. Top bar shows
  name, rank and credits.
- **Progression**: COD-style weapon levelling. Every gun has the same **20
  level-up camos** (camo designs come later; placeholders are fine), plus unlockable
  upgrades/attachments. Click a gun in the armory → detail page → upgrade/equip.
- **Cases**: casino-style spinning wheel lasting about 5 s (easing, tick sounds,
  rarity flash).
- **Market**: sell skins. Sell → popup for **minimum bid** and **buy-now price**.
  Listings last **24 h**; if unsold the item returns and can be listed again.

## Known code layout (Sept 2026)

- `StarterPlayer.StarterPlayerScripts.CombatMenu`: the whole menu (~1700 lines).
  Helpers `make`, `label`, `skin`, `shadow`, `stripeField`, `chip`, `button`,
  `card`, `frameModel`, `createWeaponViewport`, `createWorkbench`, `layOnBench`,
  `renderArmory*Tab`, `showHome`, `nav`.
- `ReplicatedStorage.WeaponConfig`: 31 weapons (class, slot, viewmodel data,
  spread/recoil), plus `Gloves` and `DefaultGloves`.
- `ReplicatedStorage.WeaponMasteryConfig`: XP per hit/kill/throw. Only 6 thresholds
  and about 3 rewards per weapon so far, so it **needs 20 levels and camos**.
- `ServerScriptService.RoundService`: S&D loop (WARMUP 60, ROUND 115, BOMB_FUSE 60,
  PLANT 3, DEFUSE 5, SCORE_TO_WIN 13, INTERMISSION 6).
- `StarterPlayerScripts.BombController`: hold-E plant/defuse UI.
- `ServerScriptService.MatchmakingService`: `getMap()` prefers
  `Workspace.ActiveMap_AETHER` / `Map_AETHER`.
- Also: `CaseService`, `CaseConfig`, `SkinConfig`, `ShopService`,
  `MarketplaceService` (the game's own market script), `ClassLoadoutService`,
  `LoadoutService`, `HUDController`, `DummyService`, `CSController`,
  `WeaponController`, `WeaponService`.
- Blender exports: `C:\Users\Cole Garcia\Downloads\AETHER_Assets\`. You can't import
  meshes yourself. Export FBX (1 Blender unit = 1 stud, `axis_forward='-Z'`,
  `axis_up='Y'`, `bake_space_transform=True`), then ask Cole to import with the 3D
  Importer.

## Hard-won lessons (don't repeat these bugs)

- `Model:PivotTo` / `:ScaleTo` silently fail on models with nested sub-Models.
  Transform every BasePart directly.
- `UIGradient` on a ViewportFrame multiplies the 3D image to near-black. Use a plain
  background colour.
- Use `ZIndexBehavior = Sibling` on ScreenGuis; `Global` hid the nav column.
- `multi_edit` only works in Edit mode, so stop play first.
- `Lighting.Technology` can't be set from scripts. Good values found:
  Brightness ≈ 0.8, ExposureCompensation ≈ −1.2. No DepthOfField.
- Don't clone a map template over the live map (that caused z-fighting and reverted
  edits).
- When sweeping for "floating" parts, start probes inside the part (coplanar probes
  gave 808 false positives). Filter sweeps to the right folder so you don't delete
  your own trim.
- In Blender, `join()` adopts the first object's transform, so run
  `transform_apply(rotation=True)`.
- `StarterPlayer.CameraMode = Classic` broke first-person lock. Keep the
  `lockFirstPerson()` guard.
- MeshPart limit is 10,000 tris. Use Box/Hull collision on props and Precise only
  where needed.
'@
[IO.File]::WriteAllText((Join-Path $WorkDir 'CLAUDE.md'), $brief, $utf8)
$plan = @'
# AETHER — Release plan

Work top to bottom. Check items off (`[x]`) as you finish and verify them.
**[COLE]** items need Cole (Creator Hub, imports, money decisions). Ask once, then
keep going with other items.

## 1. Finish the menu (where work stopped on 13 Sept)
- [ ] Home slot cards: add a `compact` mode to `createWeaponViewport` (no ◀ ▶ buttons, no "DRAG TO ROTATE", brighter background) so the guns are clearly visible
- [ ] Armory tab redesign, COD loadout style: weapon rows/cards with level + XP bar, then click → weapon detail page (big preview, stats, Equip, upgrades, camo grid)
- [ ] Weapon levelling: extend `WeaponMasteryConfig` to 20 levels for every weapon with a shared ladder of 20 placeholder camos, plus attachment/upgrade unlocks
- [ ] Camos apply to the menu preview and the in-game viewmodel
- [ ] Case opening: casino-style horizontal spinning wheel, ~5 s with easing, tick sounds, rarity colours, win flash and reveal
- [ ] Market sell flow: Sell → popup (minimum bid, buy-now price) → 24 h listing → unsold items come back and can be relisted; bidding, buy-now and expiry all handled on the server
- [ ] Whole-menu polish pass: readable contrast, consistent spacing, hover/click feedback, transitions, no overlapping or clipped text at 1366×768, 1920×1080 and phone sizes

## 2. Gameplay completeness
- [ ] All 31 weapons + knives + utilities: right-side-up, correct grip, arms connected to body (no floating/skinny arms), fire/ADS/reload (mag out → mag in) animations, sounds, muzzle flash, impacts
- [ ] Scroll wheel and number keys cycle weapons and utilities
- [ ] Customizable gloves selectable in the menu and visible in first person
- [ ] Full S&D loop verified with 2+ players (Test → Clients and Servers): warmup → rounds → plant/defuse → explosion reset → team swap at half (12 rounds) → match end at 13 → back to menu with rewards
- [ ] Spectate teammates after death; kill feed; round/score HUD; scoreboard (Tab)
- [ ] Bots/dummies fill empty slots so a solo or small lobby still plays
- [ ] Settings menu: mouse sensitivity, ADS sensitivity, FOV, volume, crosshair style; saved per player

## 3. Map (AETHER)
- [ ] Walk every route: no dead ends, no fall-through floors, no stuck spots, no floating props/lights/nameplates
- [ ] Rich vs poor district art pass finished; golden-hour lighting final check
- [ ] Dead space around the map edges cleaned up; invisible walls / kill-plane where needed
- [ ] Bomb sites A and B clearly marked; spawns balanced for both teams
- [ ] Blender assets: hover cars (detailed), wrecks, props. Ask **[COLE]** to import each FBX

## 4. Saving & economy (must be solid before release)
- [ ] One DataStore profile per player: credits, XP/rank, weapon levels, camos, skins, loadout, gloves, settings
- [ ] Session locking, retries with backoff, autosave every ~60 s, save on leave and on `game:BindToClose`
- [ ] Data versioning/migration so future updates don't wipe players
- [ ] Market listings persisted with server-side 24 h expiry that still runs while the seller is offline; no item duplication (atomic transfer, test with two clients)
- [ ] Credits and case rewards are granted only by the server

## 5. Security / anti-exploit
- [ ] Server validates every shot (fire rate, ammo, line of sight, distance, raycast from server-known position)
- [ ] Every RemoteEvent/RemoteFunction: type-check arguments, rate-limit, never trust client prices/rewards/damage
- [ ] Movement sanity checks (speed/teleport) that don't false-flag lag
- [ ] No admin/debug remotes left in the game

## 6. Monetization & policy
- [ ] **[COLE]** Decide what's sold for Robux (cases? credits? battle pass? VIP game pass?)
- [ ] Developer Products / Game Passes wired with `ProcessReceipt` that is idempotent and saves before returning `PurchaseGranted`
- [ ] Paid random items (cases bought with Robux): show drop odds in the UI before purchase (Roblox rule) and hide or disable them where `PolicyService:GetPolicyInfoForPlayerAsync` says `ArePaidRandomItemsRestricted`
- [ ] Skin trading/market: respect `IsPaidItemTradingAllowed` from PolicyService
- [ ] No real-money or off-platform trading references anywhere

## 7. Devices & performance
- [ ] Mobile: on-screen fire/aim/reload/crouch/jump buttons, weapon switch, readable UI
- [ ] Gamepad: aim/fire on triggers, menu navigable with a controller
- [ ] Performance: 60 fps on a mid-range PC, playable on phones; check the MicroProfiler, reduce part/light counts, StreamingEnabled if it helps
- [ ] Loading screen while the map and assets load

## 8. New-player experience
- [ ] First-join tutorial/tooltips: controls, how S&D works, how to plant/defuse
- [ ] Clear Play/Deploy button; matchmaking puts a solo player into a match quickly
- [ ] Analytics funnel events (join → tutorial → first match → first case) via AnalyticsService

## 9. Final QA pass
- [ ] 4-player local server test of a full match, with no errors in Output (client or server)
- [ ] Rejoin test: everything saved and restored
- [ ] Mobile emulator test (phone + tablet)
- [ ] Remove debug prints, test-only code and placeholder text

## 10. Publish & promote **[COLE]**
- [ ] File → Publish to Roblox; Game Settings → Security: enable Studio Access to API Services (for DataStores)
- [ ] Complete the Maturity & Compliance questionnaire (it has violence/weapons; required before public release)
- [ ] Icon 512×512, 3+ thumbnails 1920×1080, short video trailer. Claude can stage beauty shots in Studio for screenshots
- [ ] Title, description (features + controls), genre: Shooter / FPS, devices: PC + mobile + console
- [ ] Server size (e.g. 10 = 5v5), private servers on/off
- [ ] Make the game Public; test a live server from the website
- [ ] Promotion: Sponsored Ads, short clips for TikTok/YouTube Shorts, a Discord/community group, update log
'@
$planPath = Join-Path $WorkDir 'RELEASE-PLAN.md'
if (-not (Test-Path $planPath)) { [IO.File]::WriteAllText($planPath, $plan, $utf8) }
$progress = @'
# AETHER — Progress log

Newest first. One line per finished piece of work, plus anything Cole needs to do.

- 2026-09-13: Earlier session done: S&D round system, bomb plant/defuse, first-person camera fix, lighting retune, stairwell fall-through fix, enterable hover bus, menu shell overhaul, workbench home screen, 31/31 weapon previews framed correctly.
'@
$progressPath = Join-Path $WorkDir 'PROGRESS.md'
if (-not (Test-Path $progressPath)) { [IO.File]::WriteAllText($progressPath, $progress, $utf8) }
Ok "Game brief and release plan are in $WorkDir"

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
    } catch {
        Write-Host 'Could not start Roblox Studio. Open it yourself.' -ForegroundColor Yellow
    }
    Write-Host ''
    Write-Host 'Open your AETHER place in Roblox Studio, then press Enter here.' -ForegroundColor Yellow
    Read-Host | Out-Null
}

$claude = (Get-Command claude -ErrorAction SilentlyContinue).Source
if (-not $claude) { $claude = Join-Path $env:USERPROFILE '.local\bin\claude.exe' }

Set-Location $WorkDir
& $claude 'Read CLAUDE.md, RELEASE-PLAN.md and PROGRESS.md. Inspect my open AETHER place in Roblox Studio, then continue the release plan from the first unchecked item. Keep building, playtesting and fixing until every item is done. Do not stop to report; only pause for items marked [COLE].'
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
Write-Host '  It opens Roblox Studio (if needed) and starts Claude working through'
Write-Host '  the AETHER release plan in Documents\Roblox Claude\RELEASE-PLAN.md.'
if (Test-Path $shortcutPath) {
    Write-Host ''
    Write-Host 'Opening Roblox Claude now...' -ForegroundColor Cyan
    Start-Process $shortcutPath
}

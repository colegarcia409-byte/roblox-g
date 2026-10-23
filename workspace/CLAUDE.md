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

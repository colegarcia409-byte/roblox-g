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

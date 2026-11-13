# Steam release checklist

## Costs (yours to pay)

| Item | Cost |
|---|---|
| Steam Direct fee, per game | US$100 one-time (recoupable after US$1,000 in revenue) |
| Steam revenue share | 30% of sales |
| Google Play developer account (later) | US$25 one-time |
| Apple Developer Program (later) | US$99 per year |
| Art and music | The real budget item. Get quotes before committing. |

Check current fees and tax requirements on Steamworks before paying; they change.

## 1. Steamworks setup

1. Create a Steamworks account, complete the tax and bank forms, pay the Steam Direct fee.
2. Create the app. Note the **App ID**.
3. Store page: capsule images, 5+ screenshots (press **F12** in game, or use `--shot`), a trailer, short and long descriptions. Tags: Cozy, Relaxing, Desktop Companion, Utilities, Pixel Graphics, Casual.
4. Publish the page as "Coming soon" at least a few months before launch to collect wishlists.

## 2. Wire up Steam in the project

1. In Godot: AssetLib > search **GodotSteam GDExtension 4.4+** > install. Restart the editor.
2. Create `steam_appid.txt` next to `project.godot` containing only your App ID (it is git-ignored). Use `480` to test before you have one.
3. Run the game with Steam open. `scripts/autoload/steam_service.gd` detects the plug-in and initialises.
4. In Steamworks, create achievements with these API names:
   `FIRST_FOCUS`, `FOCUS_10_HOURS`, `STREAK_7`, `NIGHT_OWL`, `DECORATOR`.
5. Add the GodotSteam library files to the export (the plug-in documents this) and ship `steam_api64.dll` beside the exe.

## 3. Cloud saves

Steamworks > Cloud > Steam Auto-Cloud. No code needed.

- Root: `WinAppDataRoaming`
- Subdirectory: `Godot/app_userdata/Midnighty Room`
- Pattern: `save.json`

Consider setting `application/config/use_custom_user_dir` in Project Settings before launch so the path is `%APPDATA%/Midnighty Room` instead; change the Auto-Cloud path to match. Do this before players have saves.

## 4. Build and upload

1. Export the Windows build (see README).
2. On Windows, set the exe icon and version info with rcedit (Editor Settings > Export > Windows > rcedit) and turn `application/modify_resources` back on in the preset.
3. Upload with SteamPipe (`steamcmd` and an app build script) to a beta branch first.
4. Install from Steam on a clean machine and test: launch, save, cloud sync between two PCs, achievements, mini window, fullscreen, quit.

## 5. Before pressing release

- [ ] Self-test passes: `godot --headless --path . -- --selftest`
- [ ] Final art and music in place, all licences in writing
- [ ] Demo live, ideally through a Steam Next Fest
- [ ] Localised store page and in-game text
- [ ] Steam Deck check (it runs; the UI is mouse-driven)
- [ ] Privacy: the game collects nothing and makes no network calls of its own
- [ ] Price set per region, launch discount decided
- [ ] Steam review of store page and build passed (allow a week)

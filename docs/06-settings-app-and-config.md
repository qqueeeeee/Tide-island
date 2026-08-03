# 6. The settings app and `userconfig.json`

Two separate programs share one JSON file:

```
Tide-island-app  ──writes──►  ~/.config/tide-island/userconfig.json  ──watched/read──►  tide-island (shell)
```

The shell **never writes** the file; the app **never reads the shell's live state**. The only
coupling is the JSON schema, so any new setting must be added in both places or it silently
does nothing.

## 6.1 Launching it

- **SUPER + ,** (registered by the shell, see [07](07-keybinds-and-ipc.md))
- the gear toggle in the island's Control Center (`IosControlCenterLayer` →
  `settingsRequested` → `shell.qml`'s settings `Process`)
- `tide-island-config-app` on the command line
- the `tide-island-config.desktop` entry

## 6.2 Structure

| File | Role |
| --- | --- |
| `main.cpp` | QApplication + QML engine, registers `Backend` |
| `backend.hpp` / `backend.cpp` | all file I/O, wallpaper picking, editor launching, keybind writing |
| `ConfigStore.qml` | the single QML-side model: **defaults + current values + save** |
| `Main.qml` | window chrome, dark-glass sidebar, page switching |
| `AppTheme.qml` | colours/radii/typography for the app itself (not the shell) |
| `IslandPreview.qml` | live mock capsule so sliders show an effect immediately |
| `Page*.qml` | one page per section (below) |
| `Ui*.qml` | the widget kit: `UiCard`, `UiSlider`, `UiNumberField`, `UiSwitch`, `UiSegment`, `UiTextField`, `UiButton`, `ShortcutField` |
| `RES/` | icons and fonts | 
| `tests/` | CTest cases including `wallpaper_apply` |

### Pages

| Page | Contains |
| --- | --- |
| `PageIsland.qml` | island height (exact px **and** scale), top margin, corner radius, background opacity, bottom gap, reserve-space, click actions |
| `PageStatusBar.qml` | the whole `statusBar*` surface from [04](04-status-bar.md) — layout, typography, background plate, item toggles, workspace dots, plus **Reset Layout** / **Reset Style** |
| `PageAppearance.qml` | fonts (text/hero/icon families), global opacity-ish styling |
| `PageWallpaper.qml` | library path picker (native `FolderDialog`), backend/transition options, copy-to-path, pywal toggle, custom command |
| `PageCapture.qml` | screenshot/recording tool paths and options |
| `PageShortcuts.qml` | keybind list, **Open config file** (launches `$EDITOR`/`$VISUAL`/xdg-open), **Copy**, **Save** |
| `PageAbout.qml` | version/build info |

## 6.3 `ConfigStore.qml` — the contract

Every setting exists here **twice**: as a default and as a live property bound into the UI.
`save()` serialises the whole object back to `userconfig.json` through `Backend`.

Adding a setting = five edits:

1. `backend/UserConfigBackend.h` — a read-only `Q_PROPERTY`
2. `backend/UserConfigBackend.cpp` — parse it in `loadFromJson` with `jsonBoundedInt` /
   `jsonBool` / `jsonString` (clamp ranges here, not in QML)
3. the consuming QML (`StatusBarLayer.qml`, `NucleusIslandWindow.qml`, a layer, …)
4. `Tide-island-app/ConfigStore.qml` — default + property + include it in the saved JSON
5. `Tide-island-app/Page*.qml` — a `UiSlider` / `UiNumberField` / `UiSwitch` bound to it

Then rebuild (step 1–2 are C++). Full worked example in [09](09-recipes.md).

**Keep the key name identical in all five places** — the JSON key is the only glue.

## 6.4 `Backend` (the app's C++ side)

Handles:

- read/write of `~/.config/tide-island/userconfig.json` (atomic write, creates the dir)
- launching an external editor for the config, and clipboard copy
- the wallpaper folder picker (`FolderDialog`), directory listing and thumbnailing
- writing keybinds

### The keybind double-fire trap

The app can register keybinds *and* you probably have the same bindings in
`hyprland.conf`. When both exist, `SUPER + Space` fires twice and the launcher opens and
instantly closes. The shell has a **280 ms debounce guard** (`shell.qml`) to absorb this, but
the correct fix is to define each binding in **exactly one** place. If a panel flickers, that
is the first thing to check.

## 6.5 Testing the app

`Tide-island-app/tests/` is wired into CTest. The `wallpaper_apply` case loads
`Tide-island-app/Wallpaper.qml`-era assets — if you rename or move a page file, expect this
test to fail with a `FileNotFoundError` until the test is updated too. Run with
`ctest --test-dir build --output-on-failure -R wallpaper`.

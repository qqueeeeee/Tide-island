# 1. Architecture

## The three programs

| Program | Source | What it is |
| --- | --- | --- |
| `tide-island` | `tide-island-launcher` (installed as `/usr/bin/tide-island`) | Shell script. Sets `QML_IMPORT_PATH`, single-instance guards, on niri installs keybinds, then `exec quickshell -p <shell.qml>`. |
| the shell | `shell.qml` + `qml/**` | The actual island + bar. QML/JS running inside Quickshell. |
| `tide-island-config-app` | `Tide-island-app/**` | Separate Qt/QML desktop app that edits the config JSON and installs keybinds. |

Plus one helper binary, `lyricsmpris` (`lyricsmpris/`), spawned by `SysBackend` to fetch
lyrics over D-Bus/network, and one C++ QML plugin, `IslandBackend` (`backend/`), imported
by the shell as `import IslandBackend`.

They only communicate through two channels:

- **`~/.config/tide-island/userconfig.json`** — settings app writes, shell reads live
  (`UserConfigBackend` watches the file with a `QFileSystemWatcher`, so edits apply
  without a restart).
- **Quickshell IPC** — `qs -c tide-island ipc call <target> <method>`; keybinds and the
  settings app both drive the shell this way. See [07](07-keybinds-and-ipc.md).

## Process / object tree at runtime

`shell.qml` is a `Scope` (not a window). It contains:

1. `settingsApp` — a `Process` used to spawn the settings app on demand
   (`shell.qml:24-41`, `launchSettings(page)` pgreps first so you never get two).
2. A **duplicate-keybind guard**: `lastCallStamps` + `accept(key)` + `once(key, cb)`
   (`shell.qml:49-64`). Any IPC call routed through `once()` is ignored if the same key
   fired **less than 280 ms** ago. This exists because users usually have the same bind in
   both `hyprland.conf` and the app-managed snippet, so every press arrives twice.
3. **Shared data sources**, exactly one instance each, shared by all monitors:
   `HudSource`, `ClipboardSource`, `WorkspaceSource`, `NotifySource`, `WallpaperSource`
   (`shell.qml:248-269`) and `CaptureController` (`shell.qml:14`).
4. **Five `IpcHandler`s**: `island`, `tide` (legacy names), `overview`, `settings`,
   `capture`.
5. Two `Variants` blocks (`shell.qml:271-300`) that create, per entry of
   `Quickshell.screens`:
   - `qml/nucleus/NucleusIslandWindow.qml` — the capsule
   - `qml/nucleus/NucleusStatusBarWindow.qml` — the bar

`forEachIsland(cb)` (`shell.qml:67-73`) is how IPC reaches every screen's island instance.

## Why the bar is a separate window

Earlier versions drew the bar inside the island's surface. When the capsule grew, the
whole layer-shell surface grew and the bar text visibly slid down with it. The bar is now
its own `PanelWindow` with `exclusionMode: ExclusionMode.Ignore` (the island already
reserves the strip), and it computes the "resting island" rectangle from config/tokens
instead of from the live capsule (`NucleusStatusBarWindow.qml:28-38`). It therefore
*cannot* move when the island animates. `revealProgress: 1` and `islandBusy: false` are
hardcoded when it feeds `StatusBarLayer` — leftovers from the old shared-surface design.

## Layer-shell details you will care about

Both windows are Wayland layer-shell surfaces:

- Island: `WlrLayershell.layer = Overlay`, `namespace = "tide-island-nucleus"`,
  `keyboardFocus = Exclusive` only while a keyboard panel is open, else `None`
  (`NucleusIslandWindow.qml:175-181`). Its `exclusiveZone` is
  `topMargin + restingHeight + islandBottomGap` when `islandReserveSpace` is on, else 0.
- Input is masked: only the capsule rectangle (+2 px) accepts clicks
  (`NucleusIslandWindow.qml:184-189`); the bar only accepts clicks on its left and right
  clusters (`NucleusStatusBarWindow.qml:50-65`). Everything else is click-through, which is
  why you can click your windows underneath.
- `implicitHeight` of the island window is sized for the **tallest possible panel**
  (`workspacesExpanded` + 28 px slack, `NucleusIslandWindow.qml:172-174`). If you add a
  taller panel than 336 px you must bump this or it will be clipped.

## Data flow of one interaction

Pressing `SUPER+V`:

```
hyprland bind -> qs ipc call island clipboard
  -> shell.qml IpcHandler "island".clipboard()
  -> shellRoot.once("clipboard", ...)          # 280ms de-dupe
  -> island.toggleClipboard()  (each screen)
  -> openPanel("clipboard") -> panelActivity = "clipboard"
  -> activity becomes "clipboard", expanded = true (keyboard panels always expand)
  -> targetSize = IslandTokens.clipboardExpanded (460x268)  -> spring animates capsule
  -> Loader for ClipboardExpandedLayer becomes active
  -> armPanel(item): retrigger reveal animation + forceActiveFocus()
  -> layer calls ClipboardSource.refresh() -> `cliphist list` -> rows render
```

Read [02](02-island-runtime.md) next — that state machine is the heart of the project.

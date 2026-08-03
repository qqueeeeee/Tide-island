# 10. Live code vs legacy code

This repo contains **two generations** of the shell. Only the second one runs. Editing a
legacy file changes nothing, and several legacy files share names with live ones, which is the
single easiest way to waste an afternoon here.

Ground truth is always the same trace: `shell.qml` → what it instantiates → what those files
import. Nothing reachable from that trace is dead; nothing outside it is alive.

## 10.1 Live files

### Entry point
- `shell.qml` — the only file quickshell loads. Instantiates `CaptureController`,
  `MediaSource`, `HudSource`, `ClipboardSource`, `NotifySource`, `WorkspaceSource`,
  `WallpaperSource`, the settings `Process`, the `IpcHandler`, and a `Variants` of
  `NucleusIslandWindow` + `NucleusStatusBarWindow` per screen.

### `qml/nucleus/` — **all of it is live**
Windows: `NucleusIslandWindow.qml`, `NucleusStatusBarWindow.qml`.
Value tables: `IslandTokens.qml`, `IslandMotion.qml`.
Choreography: `IslandContentReveal.qml`.
Widgets: `IslandCircleButton.qml`, `IslandActionPill.qml`, `IslandCapsuleSlider.qml`,
`IslandSearchField.qml`, `AlbumArt.qml`.
Sources: `MediaSource.qml`, `HudSource.qml`, `ClipboardSource.qml`, `NotifySource.qml`,
`WorkspaceSource.qml`, `WallpaperSource.qml`.
Layers: `IdleLayer.qml`, `ClockPeekLayer.qml`, `MediaCompactLayer.qml`,
`MediaExpandedLayer.qml`, `RecordingCompactLayer.qml`, `CaptureRecordingLayer.qml`,
`ShotCompactLayer.qml`, `CaptureShotLayer.qml`, `ControlCompactLayer.qml`,
`IosControlCenterLayer.qml`, `NotifyBannerLayer.qml`, `NotificationCardLayer.qml`,
`NotifyCompactLayer.qml`, `NotifyExpandedLayer.qml`, `LauncherCompactLayer.qml`,
`LauncherExpandedLayer.qml`, `ClipboardCompactLayer.qml`, `ClipboardExpandedLayer.qml`,
`WallpaperCompactLayer.qml`, `WallpaperExpandedLayer.qml`, `WorkspacesCompactLayer.qml`,
`WorkspacesExpandedLayer.qml`, `VolumeHudLayer.qml`.

### `qml/bar/` — live except one file
`StatusBarLayer.qml`, `BarWorkspaceDots.qml`, `BarActiveWindow.qml`, `BarStatusCluster.qml`,
`BarBatteryIndicator.qml`, `BarLabel.qml`, `BarHyprlandWorkspaceModel.qml`.
**`StatusBarWindow.qml` is dead** — replaced by `qml/nucleus/NucleusStatusBarWindow.qml`.

### `qml/common/` — two of four
Live: `CaptureController.qml` (grim/grimblast/slurp/wf-recorder + satty),
`HyprlandDispatch.qml` (workspace focus from the bar), `ApplicationSearch.js` (imported by
`LauncherExpandedLayer`).
Dead: `WallpaperThumbnailCache.qml`.

### `qml/island/` — exactly one file
**`IslandClock.qml` only** (used by `NucleusStatusBarWindow`). Every other file in that
directory is legacy.

### C++ / app
All of `backend/`, `lyricsmpris/`, `Tide-island-app/`, `tests/`, `CMakeLists.txt`,
`install.sh`, `PKGBUILD`, `tide-island.service`, `tide-island-launcher`,
`tide-island.desktop`, `tide-island.install` are live. Inside `backend/`,
`StyleTokensBackend` is compiled and exposed but effectively unused by the nucleus UI, which
styles from `IslandTokens.qml`.

## 10.2 Dead files — never loaded

| Path | Was |
| --- | --- |
| `DynamicIslandWindow.qml` (repo root) | the previous island window; the ancestor of `NucleusIslandWindow.qml` |
| `qml/island/**` except `IslandClock.qml` | the entire first-generation island: `IslandIdleLayer`, `IslandOrbLayer`, `IslandUsageRing`, `IslandDualCompact`, `LiveDualLayer`, `LiveMediaLayer`, `LiveTimerLayer`, `TimerExpandedLayer`, `BluetoothExpandedLayer`, `ExpandedPlayerLayer`, `ApplicationLauncherLayer`, `WallpaperPickerLayer`, `WorkspaceLayer`, `NotificationLayer`, `NotificationHistory`, `OsdLayer`, `ClockLayer`, the `Swipe*` layers (`SwipeLyricsLayer`, `SwipeCavaBars`, `SwipeDatePreviewLayer`, `SwipeCustomInfoLayer`), the trackers (`HyprlandWorkspaceTracker`, `CompositorWorkspaceTracker`, `BluetoothConnectionTracker`, `HyprlandWindowIntegration`, `IslandSystemState`, `IslandMprisController`), and old widgets (`IslandActionButton`, `IslandAudioWave`, `PlayerControlButton`, `FavoriteStar`, `SplitIconLayer`, `RecordingIndicator`, `IslandRootGestureArea`, `IslandIdleConfig`) |
| `qml/workspace/**` | `HyprlandData`, `WorkspaceOverviewLayer`, `WorkspaceOverviewScene`, `WorkspaceOverviewWindow` — the old full-screen overview, replaced by `WorkspacesExpandedLayer` inside the capsule |
| `qml/controlcenter/**` | `ControlCenterLayer`, `ControlSliderCard`, `MatteSurface`, `NotificationCenterLayer` — replaced by `IosControlCenterLayer` + `NotifyExpandedLayer` in `qml/nucleus/` |
| `qml/connectivity/**` | `ConnectivityDetailPanel`, `ConnectivityDetailShell`, `BluetoothDeviceRow` — the full Wi-Fi/BT picker UI |
| `qml/bar/StatusBarWindow.qml` | first status-bar window |
| `qml/common/WallpaperThumbnailCache.qml` | thumbnail cache for the old wallpaper picker |

### Name collisions to watch for

These filenames exist in **both** `qml/island/` (dead) and `qml/nucleus/` (live). Always check
the directory before editing:

`IosControlCenterLayer.qml`, `IslandTokens.qml`, `IslandMotion.qml`,
`IslandContentReveal.qml`, `IslandCircleButton.qml`, `IslandActionPill.qml`,
`IslandCapsuleSlider.qml`, `CaptureRecordingLayer.qml`, `CaptureShotLayer.qml`.

If a change "does nothing", 90 % of the time you edited the `qml/island/` copy.

## 10.3 Useful legacy code

Dead does not mean worthless — these are working implementations you can port into a nucleus
layer instead of writing from scratch:

- `qml/connectivity/ConnectivityDetailPanel.qml` + `BluetoothDeviceRow.qml` — a complete
  Wi-Fi network list and Bluetooth device list driven by `WifiController.networks` and the
  BlueZ agent. This is what you'd lift to build a real Wi-Fi picker panel in the island.
- `qml/island/SwipeLyricsLayer.qml` — consumes `SysBackend.lyricsCurrentLyric`; the only
  existing UI for the `lyricsmpris` helper.
- `qml/island/SwipeCavaBars.qml` — audio visualiser off `SystemServices.cavaLevels`.
- `qml/island/IslandUsageRing.qml` + `IslandOrbLayer.qml` — the CPU/RAM ring idle treatment.
- `qml/workspace/WorkspaceOverviewScene.qml` — full-screen workspace overview with live
  window thumbnails.
- `qml/island/TimerExpandedLayer.qml` — the timer Live Activity layout (tokens
  `timerCompact`/`timerExpanded` still exist in `IslandTokens.qml`, unused).

## 10.4 Can I delete the legacy tree?

Yes, functionally — nothing reachable from `shell.qml` imports it. Before doing so:

1. `rg -l 'ClockLayer|WorkspaceOverviewWindow|ControlCenterLayer' shell.qml qml/nucleus qml/bar`
   should return nothing.
2. Check `CMakeLists.txt`'s install globs for `qml/**` — removing directories is fine, but
   confirm no explicit file list references them.
3. Keep `qml/island/IslandClock.qml` and `qml/common/CaptureController.qml` +
   `HyprlandDispatch.qml` + `ApplicationSearch.js`.
4. `ctest --test-dir build --output-on-failure` afterwards.

Recommended: keep it until the items in §10.3 have been ported, then delete in one commit.

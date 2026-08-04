# Tide Island — Developer Guide

Everything you need to modify this project yourself lives in [`docs/`](docs/).
This file is only the map.

| Read this when you want to… | Doc |
| --- | --- |
| Understand how the whole thing fits together | [docs/01-architecture.md](docs/01-architecture.md) |
| Change the capsule: size, states, timings, gestures | [docs/02-island-runtime.md](docs/02-island-runtime.md) |
| Change what a panel looks like (media, launcher, clipboard, notifications, control centre, wallpaper, workspaces, capture, HUD) | [docs/03-layers-and-sources.md](docs/03-layers-and-sources.md) |
| Change the top bar (height, fonts, icons, workspace dots, background plate) | [docs/04-status-bar.md](docs/04-status-bar.md) |
| Touch C++: battery, wifi, bluetooth, volume, brightness, compositor, cava, TLP | [docs/05-backends.md](docs/05-backends.md) |
| Add a setting, or work on the settings app | [docs/06-settings-app-and-config.md](docs/06-settings-app-and-config.md) |
| Add/change a keybind or IPC command | [docs/07-keybinds-and-ipc.md](docs/07-keybinds-and-ipc.md) |
| Build, install, run tests, debug | [docs/08-build-install-test.md](docs/08-build-install-test.md) |
| Copy-paste recipes for common changes | [docs/09-recipes.md](docs/09-recipes.md) |
| Know which files are dead code (a lot of them are) | [docs/10-live-vs-legacy.md](docs/10-live-vs-legacy.md) |
| Look up every config key the settings app writes | [docs/11-settings-reference.md](docs/11-settings-reference.md) |

## 60-second orientation

```
tide-island (launcher script)  ->  quickshell -p shell.qml
                                        |
   shared data sources (one instance, all screens)
   MediaSource HudSource ClipboardSource NotifySource
   WorkspaceSource WallpaperSource CaptureController
                                        |
        +-------------------------------+------------------------------+
        |                                                              |
  NucleusIslandWindow (per screen)                    NucleusStatusBarWindow (per screen)
  the capsule: state machine + ~20 content layers      the transparent top bar
                                        |
   IslandBackend (C++ QML plugin): UserConfig, SysBackend, SystemServices,
   CompositorBackend, WifiController, BluetoothPairingAgent, StyleTokens
                                        |
   ~/.config/tide-island/userconfig.json  <-- written by tide-island-config-app
```

Two rules that will save you hours:

1. **Only `qml/nucleus/`, `qml/bar/`, `qml/common/{CaptureController,HyprlandDispatch}.qml` and
   `qml/island/IslandClock.qml` are alive.** `DynamicIslandWindow.qml`, all the rest of
   `qml/island/`, `qml/workspace/`, `qml/controlcenter/`, `qml/connectivity/` and
   `qml/bar/StatusBarWindow.qml` are the previous generation and are never loaded.
   See [docs/10-live-vs-legacy.md](docs/10-live-vs-legacy.md). Two files share the name
   `IosControlCenterLayer.qml` — the live one is in `qml/nucleus/`.
2. **Sizes are data, not layout code.** Every capsule size lives in
   `qml/nucleus/IslandTokens.qml`; every motion constant lives in
   `qml/nucleus/IslandMotion.qml`. Change a number there and the springs pick it up.

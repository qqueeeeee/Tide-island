# 5. C++ backends (`backend/`)

All of `backend/*.cpp` compiles into **one** QML plugin module named `IslandBackend`
(`CMakeLists.txt:160-182`), installed to `lib/qt6/qml/IslandBackend`. QML uses it with
`import IslandBackend` (`shell.qml:5`). Every class here is a **singleton** — there is one
instance per shell process, shared by all screens.

Touching any of these means a real rebuild (`cmake --build build`), not just a shell reload.

## 5.1 `UserConfigBackend` → QML name `UserConfig`

`backend/UserConfigBackend.h`, `QML_NAMED_ELEMENT(UserConfig)`, `QML_SINGLETON`.

The shell's **read** path for `~/.config/tide-island/userconfig.json`. ~90 read-only
`Q_PROPERTY`s (`:14-119`), grouped: wallpaper (:16-32), fonts (:33-37), TLP (:38-39),
island geometry/behaviour (:43-70), status bar (:72-116), capture (:112-119). Parsing lives
in `loadFromJson` (`UserConfigBackend.cpp`, status-bar block at :771-813) using the helpers
`jsonBoundedInt`, `jsonBool`, `jsonString`.

A `QFileSystemWatcher` on the file means the shell live-updates the moment the settings app
writes — that is why nearly everything is bindable without a restart. `Q_INVOKABLE reload()`
forces a re-read; `mouseButton`/`mouseButtonsMask` convert QML mouse-button variants for the
click-action settings.

Note the asymmetry: **the shell never writes this file.** Writing is
`Tide-island-app`'s `Backend` class ([06](06-settings-app-and-config.md)).

## 5.2 `SysBackend`

`QML_ELEMENT QML_SINGLETON`. Properties: `batteryCapacity`, `batteryStatus`,
`lyricsCurrentLyric`, `lyricsIsSynced`, `lyricsBackendStatus` (:22-26). Invokable
`setLyricsClientActive(clientId, active)` (:37). Signals `brightnessChanged`,
`volumeChanged`, `bluetoothChanged` (:40-48).

System interfaces: reads `/sys/class/power_supply` (`SysBackend.cpp:132`) and
`/sys/class/backlight` (:436) directly, watches battery through a udev monitor, listens to
UPower `PropertiesChanged` on the system bus (:153, :282), subscribes to `pactl` for volume
(:332), and spawns/supervises the bundled `lyricsmpris` helper (:503, located by
`findLyricsBackendExecutable()`).

Change sysfs discovery in `detectPowerSupplyPaths` / `detectBacklightPath` /
`updateBatterySysfs`. QML consumer: the bar's battery indicator.

## 5.3 `SystemServices`

`QML_ELEMENT QML_SINGLETON` — the "do things" backend and the busiest one.

Properties: `screenRecordingActive`, `cavaLevels` (`QVariantList`).

Invokables cover:

- brightness — `requestBrightness()`, `setBrightness(v)`
- volume — `requestVolume()`, `setVolume(v)`
- system stats — `requestSystemStats()` (CPU/RAM)
- TLP power profiles — `requestTlpState()`, `setTlpMode()`, `cancelTlpApply()`, honouring
  `tlpPermissionMode` (polkit / sudo / zenity password flows)
- Hyprland — `requestHyprlandSnapshot(subject)` → `hyprctl <subject> -j` (`.cpp:709`)
- wallpaper thumbnails
- cava — `setCavaClientActive()` spawns/stops the `cava` process (`.cpp:1128`)
- `ensureUserConfigAvailable()`, `requestScreenRecordingSnapshot()` — both called once from
  `shell.qml:242-246`

Monitors (each an external process watched over D-Bus): notification daemon,
PipeWire/portal screen-cast detection, recording portal
(`startNotificationMonitor`/`startPipeWireMonitor`/`startRecordingPortalMonitor`,
`.cpp:369-421`). Results come back as signals — `brightnessSnapshotReady`,
`volumeSnapshotReady`, `tlpStateReady`, `hyprlandSnapshotReady`, `notificationReceived`
(wired at `shell.qml:76-81`) — so QML must be written asynchronously: call `request*`, then
handle the `*Ready` signal.

Consumers: `qml/nucleus/HudSource.qml`, `qml/nucleus/IosControlCenterLayer.qml`,
`qml/common/CaptureController.qml`.

## 5.4 `CompositorBackend`

`QML_ELEMENT QML_SINGLETON`. Properties `compositor` (`"hyprland"` / `"niri"`),
`focusedOutputName`, `revision` (bumped on any change so QML can rebind cheaply).
Invokables `activeWorkspaceIndexForOutput(name)`, `isOutputFocused(name)`.

Detection order: `TIDE_ISLAND_COMPOSITOR` env → `XDG_CURRENT_DESKTOP` → presence of
`NIRI_SOCKET`. On niri (and when built with `TIDE_ISLAND_WITH_NIRI`, default ON) it opens a
`QLocalSocket` to niri's IPC socket and parses `WorkspacesChanged` / `WorkspaceActivated`
JSON events. Behaviour is covered by `tests/compositor_backend_tests.cpp`.

To support another compositor: extend `detectCompositor()` plus the event-stream block, and
add a workspace model the way `BarHyprlandWorkspaceModel.qml` does for Hyprland.

## 5.5 `WifiController` + `WifiNetworkModel`

`WifiController` is `QML_ELEMENT QML_SINGLETON QML_UNCREATABLE`. Properties: `backendName`,
`supported`, `readOnly`, `available`, `enabled`, `busy`, `scanning`, `currentSsid`,
`statusText`, `infoMessage`, `errorMessage`, `unsupportedReason`, and `networks` (a
`QAbstractItemModel*`). Invokables: `refreshState`, `refreshNetworks(rescan)`,
`setEnabled(bool)`, `disconnectCurrent()`, `connectToNetwork(ssid, password)`,
`clearMessages()`.

It speaks to **both NetworkManager and iwd** on the system bus, chosen by `detectBackend()`;
iwd's passphrase prompts go through an inner `IwdAgent`. It reacts to `NameOwnerChanged`,
property changes, AP add/remove and device add/remove, so it recovers if NM restarts.

`WifiNetworkModel` is a plain `QAbstractListModel` (roles Ssid, DisplayName, Type, Signal,
Secure, SavedConnection, Connected) exposed only through `WifiController.networks`.

In the live nucleus build only `enabled`/`currentSsid`/`setEnabled` are used
(`ControlCompactLayer`, `IosControlCenterLayer`, `BarStatusCluster`). The full network list
UI exists only in the legacy `qml/connectivity/` tree — if you want a Wi-Fi picker panel in
the island, that model is already there and you just need a new nucleus layer.

## 5.6 `BluetoothPairingAgent`

`QML_ELEMENT QML_SINGLETON QML_UNCREATABLE`, registers itself on the system bus as a BlueZ
`org.bluez.Agent1` object (`Q_CLASSINFO("D-Bus Interface", "org.bluez.Agent1")`, :19) and
implements the whole agent surface: `RequestPinCode`, `DisplayPinCode`, `RequestPasskey`,
`DisplayPasskey`, `RequestConfirmation`, `RequestAuthorization`, `AuthorizeService`,
`Cancel`, `Release` (:63-72).

Pairing state for the UI: `requestActive`, `requestKind`, `requestRequiresInput`,
`requestRequiresNumericInput`, `requestRequiresConfirmation`, `devicePath`, `deviceName`,
`promptTitle`, `promptMessage`, `displayedCode`, `displayedEnteredCount` (:21-33).
Driving functions: `submitSecret`, `confirmRequest`, `rejectRequest`, `cancelRequest`
(:53-56). Device on/off itself is done through Quickshell's own
`Bluetooth.defaultAdapter.enabled`, not this class.

## 5.7 `StyleTokensBackend` → QML name `StyleTokens`

`QML_NAMED_ELEMENT(StyleTokens) QML_SINGLETON`. Pure constants: `panel`, `accent`
(`#0a84ff`), `radiusPanel`, `durationFast`, … (:12-72). No invokables, no system access.

**This is the legacy palette** and is largely unused by the nucleus build, which styles
itself from `qml/nucleus/IslandTokens.qml`. Don't retheme here expecting the island to
change.

## 5.8 `lyricsmpris`

Standalone binary (`lyricsmpris/`): `LyricsCore`, `LyricsMprisApp`,
`CjkVariantNormalizer`, `ProviderNetworkPolicy`. Spawned by `SysBackend`, communicates over
a pipe (`--pipe`), fetches synced lyrics for the current MPRIS track. Tested by
`tests/lyricsmpris_runtime_tests.cpp` (fake player on an isolated D-Bus session) and
`LyricsCore` unit tests. The nucleus island does not display lyrics yet — the old
`qml/island/SwipeLyricsLayer.qml` did.

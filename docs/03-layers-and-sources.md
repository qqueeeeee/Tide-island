# 3. Content layers and data sources

All of this is `qml/nucleus/`. A **layer** is one visual state of the capsule; a **source**
is a headless object that owns data and talks to the system.

Shared conventions for every layer:

- root is an `Item`, `anchors.fill: parent`, `opacity: 0`,
  `transform: Translate { y: revealOffset }`
- `showCondition` (bool) drives `IslandContentReveal`
- `textFontFamily` / `heroFontFamily` / `iconFontFamily` come from the parent
- inner content is inset 12–14 px left/right
- sizes are in design px (no `uiScale` maths inside a layer)
- **layers hold no persistent state** — they are destroyed on every state change

## 3.1 Layer catalogue

### Idle / clock

| File | Size | What it is | Edit for |
| --- | --- | --- | --- |
| `IdleLayer.qml` | 148×34 | The resting pill: a single 6 px dot at 25 % white, pinned right (14 px margin). Breathing constants come from `IslandMotion.idleBreath*`. | :23-31 for the dot |
| `ClockPeekLayer.qml` | 232×38 | 2 s clock peek (`qs ipc call tide showClock`): time 15 px DemiBold hero font left, date 11 px right, 1.5 px draining hairline whose width is `lifeProgress`. Own 1 s `Timer`. | :53/:63 fonts, :76-87 hairline |

### Media

| File | Size | Notes |
| --- | --- | --- |
| `MediaCompactLayer.qml` | 244×38 | 22 px `AlbumArt`, elided title 12 px, pulsing green wave glyph that dims to 0.45 when paused. Props `title`, `artUrl`, `playing`. |
| `MediaExpandedLayer.qml` | 372×196 | 56 px art, title 14 px DemiBold / artist 12 px, 40 px `IslandCircleButton` play/pause, 4 px scrubber (`Behavior on width`, 240 ms) with elapsed/remaining in the mono/hero font, prev/next glyphs 18 px with press-scale 0.9 and −8 px hit-target margins. Signals `playPauseRequested`, `nextRequested`, `previousRequested`. |

### Recording and screenshot

| File | Size | Notes |
| --- | --- | --- |
| `RecordingCompactLayer.qml` | 214×38 | Pulsing 9 px red dot (0.8 s sine, 0.45 when paused), mono elapsed 13 px, source label right. Props `elapsedText`, `sourceLabel`, `paused`. |
| `CaptureRecordingLayer.qml` | 340×92 | Expanded recorder: 44 px soft-red circle, 21 px mono timer, "Recording"/"Paused · source", pause + stop `IslandCircleButton`s (38 px). Signals `stopRequested`, `pauseToggleRequested`. |
| `ShotCompactLayer.qml` | 246×37 | Camera glyph + label (default "Screenshot Saved"). |
| `CaptureShotLayer.qml` | 348×106 | Expanded shot card: 36 px chip, title + filename (derived from `filePath`), four equal `IslandActionPill`s — Copy / Markup / Open / Delete (`destructive: true`) — and the 2 px life bar. Signals `copyRequested`, `annotateRequested`, `openRequested`, `deleteRequested`, `dismissRequested`. |

The actual `grim`/`grimblast`/`slurp`/recorder processes live in
`qml/common/CaptureController.qml` (instantiated in `shell.qml:14`); these layers only emit
signals.

### Control centre

| File | Size | Notes |
| --- | --- | --- |
| `ControlCompactLayer.qml` | 246×38 | Wi-Fi glyph (blue when on) + SSID or "Wi-Fi Off" + 5 px status dot. Reads `WifiController` directly. |
| `IosControlCenterLayer.qml` | 372×178 | Five 42 px toggles (Wi-Fi, Bluetooth, Mic, Night light, Settings) with 10 px labels, then two `IslandCapsuleSlider`s for volume and brightness. Signal `settingsRequested()`. |

Backends it touches: `SystemServices.requestVolume/setVolume/requestBrightness/setBrightness`
(debounced by 60 ms timers, :81-93), `wpctl … @DEFAULT_AUDIO_SOURCE@` for the mic (:95-109),
`tide-island-config-app` launch (:111-115), `hyprsunset`/`hyprctl hyprsunset` for night light
(:117-124), `WifiController.setEnabled`, `Bluetooth.defaultAdapter.enabled`.
Toggle dispatch is `handleToggle()` at :251-268 — add a sixth toggle there and in the `Row`.

### Notifications

| File | Size | Notes |
| --- | --- | --- |
| `NotifyBannerLayer.qml` | 372×58 | Single-arrival banner: 36 px app tile (glyph+tint from the item), title 13 px, body 11 px, app name 10 px right. Prop `item` (shape from `NotifySource`). |
| `NotificationCardLayer.qml` | 348×106 | Generic card with no actions (used by `showNotification()`): title/app/body + 2 px life bar. |
| `NotifyCompactLayer.qml` | 246×38 | Bell / bell-off glyph, "Notifications" or "Do Not Disturb", red 18 px count badge ("9+" cap) or "all clear"/"silenced" hint. |
| `NotifyExpandedLayer.qml` | 420×296 | The Notification Center. Header + "Focus" (DND) pill + "Clear"; `ListView` **grouped by app** with an iOS-style stacked-card peek when a group has >1; per-card and per-group dismiss. Keys: only `Escape` (no arrow navigation yet). |

### Launcher / clipboard / wallpaper / workspaces (the keyboard panels)

| File | Size | Notes |
| --- | --- | --- |
| `LauncherCompactLayer.qml` | 260×38 | Search glyph + "Launcher" + "Super + Space" chip. |
| `LauncherExpandedLayer.qml` | 460×246 | `FocusScope`. Searches `Quickshell.DesktopEntries.applications` scored by `qml/common/ApplicationSearch.js` (`normalize`, `applicationScore`). 2-column grid, max 6 results, 42 px rows, 28 px `IconImage`. Launch prefers `entry.execute()`, else wraps the command in `systemd-run --user --scope --slice=app.slice` so launched apps do not live in the shell's cgroup (:90-106). |
| `ClipboardCompactLayer.qml` | 252×38 | Clipboard glyph + label + count chip. |
| `ClipboardExpandedLayer.qml` | 460×268 | `FocusScope`. `IslandSearchField` + `ListView` of 46 px rows; image entries are decoded per-row by a `Process` running `cliphist decode <id> > /tmp/tide-island/clip/<id>.img` (:203-221) and shown as a 34 px thumbnail; hover reveals a 24 px delete button. Functions `rebuild()`, `move()`, `paste()`, `remove()` (:35-63). |
| `WallpaperCompactLayer.qml` | 262×38 | Image glyph + "Wallpaper" + "<n> images". |
| `WallpaperExpandedLayer.qml` | 460×300 | `FocusScope`, 3-column `GridView` of 16:10 previews (`sourceSize.width: 320`, `PreserveAspectCrop`), filename strip, applied checkmark. Own `Keys.onPressed` (:69-89): ←/→ or Tab, ↑/↓ = ±3, Enter applies, Esc closes. Sizes come from `NucleusIslandWindow`'s local `Qt.size(262,38)`/`Qt.size(460,300)`, **not** from `IslandTokens`. |
| `WorkspacesCompactLayer.qml` | 258×38 | Grid glyph + pill dots (6 px, active stretched to 16 px, 220 ms) + "n/9". |
| `WorkspacesExpandedLayer.qml` | 452×336 | `FocusScope`, 3×3 mini-desktops (16:10) where each window is a proportionally placed gradient rect; workspace badge + active dot. Keys (:59-82): arrows/Tab, ↑↓ = ±3, Enter switches, Esc closes, **digits 1-9 jump directly** (hardcoded `Key_1..Key_9`). |

### HUD

`VolumeHudLayer.qml` (272×42) is shared by volume and brightness; the `kind` prop
(`"volume"` / `"brightness"`) picks the glyph. 6 px level bar with a local
`SpringAnimation` (4.2 / 0.62), percentage right. Fed by `HudSource`.

## 3.2 Data plumbing (`*Source.qml`)

All are invisible `Item`s (`visible:false; width:0; height:0`) instantiated once in
`shell.qml` and passed down to every screen's island. Add a new one there if you need
shared state.

### `MediaSource.qml` — MPRIS

Uses `Quickshell.Services.Mpris` (no `playerctl`). Picks the playing player, else the first
one (:57-72). Exposes `title`, `artist` (array joined with ", "), `artUrl`, `playing`,
`paused`, `live`, `progress` (0–1), `elapsedText`, `remainingText`.
**Poll: 500 ms `Timer`** (:98-113) that pokes `player.positionChanged()` and re-reads
position/length; it only runs while a player exists. Transport functions
`togglePlaying()`, `next()`, `previous()` proxy to the MPRIS object.

### `HudSource.qml` — volume + brightness

Signals `volumeChanged(value, muted)` and `brightnessChanged(value)`.

- Volume is **event-driven**, not polled: one long-lived `bash -lc` process does one
  initial read then loops on `pactl subscribe`, filtering `sink`/`server` lines (:31-72).
  Read prefers `wpctl get-volume @DEFAULT_AUDIO_SINK@`, falls back to
  `pactl get-sink-volume/get-sink-mute`.
- Brightness polls `/sys/class/backlight/*/brightness` every **0.25 s** in a shell loop
  and only prints on change (:92).
- Both swallow their first emission (`sawVolume`/`sawBrightness`) so the HUD does not flash
  at login.

### `ClipboardSource.qml` — cliphist

`entries: [{ id, kind: "text"|"image"|"link", value, meta }]`, `count`, `available`.
**Not polled** — `refresh()` runs `cliphist list` on demand, and the expanded layer calls it
every time it opens. Binary entries are detected with `^\[\[\s*binary data\s+(.+?)\s*\]\]$`,
links with `^(https?://|www\.)\S+$`; the list is capped at **60** entries (:118).
Paste = `cliphist decode <id> | wl-copy`; delete = `cliphist decode <id> | cliphist delete`;
`wipe` is exposed but unused. Classification lives in `parseLine()` (:22-58).

### `NotifySource.qml` — freedesktop notification server

Wraps `Quickshell.Services.Notifications.NotificationServer` with actions/body/image
support, so **tide-island is your notification daemon** — mako/dunst/swaync must be off.
`items: [{ id, app, title, body, image, urgent, glyph, tint, time, age, notification }]`
capped at **40** (:36), plus `dnd` and `count`. Event-driven; a 30 s timer only refreshes
the relative `age` strings (:42-51). App-specific glyph/tint heuristics by name substring
(mail/discord/spotify/pacman/kitty…) at :53-80 — **add your app here for a custom icon**.
API: `dismiss(id)`, `dismissApp(app)`, `clearAll()`, `groups()`.

### `WallpaperSource.qml`

`entries: [{ name, path }]`, `appliedPath`, `lastError`, `count`, `libraryPath`
(`UserConfig.wallpaperLibraryPath`, default `~/Pictures/Wallpapers`). Scans with
`find … -maxdepth 1` for png/jpg/jpeg/webp/bmp/avif/jxl/gif (:50-59). No polling; refresh
on completion, on library change, and whenever the panel opens.

`applyScript()` (:61-109), in order:

1. if `wallpaperCustomCommandEnabled` and a command is set →
   `sh -c '<custom>' tide-island-wallpaper "$src"` and stop
2. optionally copy the image to `UserConfig.wallpaperPath`
3. `awww img` → `swww img` (both with `--transition-type/-duration/-fps` from config,
   defaults center/3/60) → `hyprctl hyprpaper preload` + `hyprctl hyprpaper wallpaper` →
   `setsid swaybg -m fill`; otherwise fail with "No wallpaper tool found"
4. if `wallpaperPywalEnabled` → `wal -n -q -i "$src"`

Signals `applied(path)`, `failed(message)` (shell.qml turns failures into a notification).
**"socket error /run/…"** means the swww/awww daemon is not running — start it or reorder
this chain to put `hyprpaper` first.

### `WorkspaceSource.qml` — Hyprland

`workspaces: [{ id, name, windows: [{ title, x, y, w, h, tint:[c1,c2] }] }]` where x/y/w/h
are 0–1 fractions of the client's monitor; plus `active`, `count` (**fixed 9**) and a
5-entry gradient palette cycled per client (:17-23). Event-driven on
`Hyprland.onRawEvent`, debounced **90 ms**, for
`openwindow/closewindow/movewindow/workspace/focusedmon/fullscreen` (:31-47). Data comes
from one process: `hyprctl -j clients; echo '@@'; hyprctl -j monitors`, split on `@@`
(:117-134). `buildFrom()` (:58-115) normalises absolute geometry to monitor-relative rects
clamped to 0.96. `switchTo(id)` → `Hyprland.dispatch("workspace " + id)`.
Raising `count` above 9 also needs the digit-key block in `WorkspacesExpandedLayer` (:78-81)
and the 3×3 grid changed.

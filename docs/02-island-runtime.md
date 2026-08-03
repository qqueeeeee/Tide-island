# 2. The island runtime

Files: `qml/nucleus/NucleusIslandWindow.qml` (the whole capsule),
`IslandTokens.qml` (sizes/colours/glyphs), `IslandMotion.qml` (all timings),
`IslandContentReveal.qml` (enter/exit choreography), and the shared widgets
`IslandCircleButton.qml`, `IslandActionPill.qml`, `IslandCapsuleSlider.qml`,
`IslandSearchField.qml`, `AlbumArt.qml`.

## 2.1 Geometry

Everything is computed at the top of `NucleusIslandWindow.qml`:

| Property | Line | Meaning |
| --- | --- | --- |
| `topMargin` | :44 | `max(0, userConfig.islandTopMargin)` — distance from screen top. **This is the "move the island down 5px" knob.** |
| `exactHeight` | :49 | `clamp(userConfig.islandHeight, 20, 96)` — used only when `islandHeightOverrideEnabled`. |
| `uiScale` | :50-52 | Either `exactHeight / tokens.idleCompact.height` (override mode) or `islandScale/100`, clamped. Everything else is multiplied by this. |
| `cornerRadius` | :53 | `max(4, userConfig.islandCornerRadius)`; final radius is `min(height/2, cornerRadius)` so it can never stop being a capsule. |
| `restingWidth/Height` | :54-55 | `tokens.idleCompact` (148×34) × `uiScale`. |
| `exclusiveZone` | :169-171 | Reserved strip: `topMargin + restingHeight + islandBottomGap`, or 0 if `islandReserveSpace` is off. |
| `implicitHeight` | :172-174 | Sized for the tallest panel (workspaces expanded) + 28 px. |

The capsule is horizontally centred by `capsuleHost.x = round((root.width - width)/2)`
(:378-384). The inner `Rectangle` is drawn at **unscaled reference pixels** and the *host*
applies `uiScale` — so all layer metrics are in "design px" and you never multiply by scale
inside a layer. Background colour is
`Qt.rgba(0,0,0, clamp(islandBackgroundOpacity/100, 0.4, 1))` (:397) and there is a subtle
top-down white sheen gradient at :431-439 (the "vibrancy").

## 2.2 The state machine (the important part)

Three input properties combine into one computed `activity` (:82-94), in strict priority:

1. `panelActivity` — keyboard panels: `launcher`, `clipboard`, `notify`, `workspaces`, `wallpaper`
2. `transientActivity` — momentary: `notification`, `shot`, `volume`, `brightness`, `clock`, `banner`
3. `"control"` if `controlCentreOpen`
4. `"recording"` if `recordingLive` (`captureController.recording`)
5. `"media"` if `mediaLive` (`media.live`)
6. `"idle"`

Derived:

- `keyboardPanel = panelActivity !== ""` → drives `WlrLayershell.keyboardFocus`.
- `hasExpanded` (:98-107) — which activities support an expanded card. Everything except
  `idle`, `banner`, `volume`, `brightness`, `clock`.
- `expanded` (:109) is a **plain settable bool**, re-defaulted on every activity change
  (:210-218):
  ```qml
  root.expanded = activity === "shot" || activity === "notification"
               || activity === "control" || keyboardPanel;
  ```
  That is the iOS rule: content-carrying/momentary cards and panels open expanded; ambient
  Live Activities (media, recording) stay **compact** until you tap or long-press.
- `targetSize` (:111-143) — a switch mapping `(activity, expanded)` to a token size.
  Special cases: wallpaper uses local `Qt.size(262,38)` / `Qt.size(460,300)` (:35-36, not
  in tokens); `banner` always `tokens.notifyBanner`; volume/brightness share
  `tokens.volumeCompact` and have no expanded form.

### Auto-dismiss

`dismissMs` (:146-162) applies **only to `transientActivity`**:

| activity | ms |
| --- | --- |
| notification | 6000 |
| shot | 6000 |
| banner | 5000 |
| volume / brightness | 2200 |
| clock | 2600 |
| everything else | 0 (persistent) |

Driven by `dismissTimer` (:326-332) plus `lifeAnimation` (:334-342) which animates
`root.life` 1→0 and is passed to layers as `lifeProgress` (the draining hairline). Hovering
pauses the countdown and, on hover-out, restarts it with **only the remaining time**
(`interval = max(1, round(dismissMs * life))`, :775-786).

### Gestures

`MouseArea` `pointer` fills the capsule with `z: -1`, so buttons inside layers win the hit
test (:740-787):

- Left press arms `pressTimer` (`IslandMotion.longPressInterval`, **420 ms**); on trigger
  it forces `expanded = true` if `hasExpanded`.
- Left click: banner → clear transient and open the notification panel; otherwise toggle
  `expanded`.
- Right click = back/dismiss: close panel, else clear transient, else close control centre.
- Press feedback: capsule scales to `motion.pressScale` (0.972) via a spring (:400, :420-427).

### Public functions (call these from IPC or elsewhere)

`showTransient(kind)`, `clearTransient()`, `showNotification(app, summary, body)`,
`showScreenshot(path)`, `dismissScreenshot()`, `showVolume(value, muted)`,
`showBrightness(value)`, `showClockPeek()`, `togglePlayer()`, `openPanel(kind)`,
`closePanel()`, `toggleLauncher/Clipboard/Notifications/Workspaces/WallpaperPicker()`,
`toggleControlCentre/openControlCentre/closeControlCentre()` — all at :220-324.
`openPanel(kind)` toggles: passing the currently open kind closes it (single-panel
exclusivity).

### `armPanel(item)` — why it exists (:298-304)

A panel `Loader` is created already visible, so the layer's own `showCondition`-driven
reveal never fires and it would pop in without animation and without keyboard focus.
`armPanel` flips `showCondition` false→true to re-run `IslandContentReveal`, then calls
`item.forceActiveFocus()`. Every expanded panel Loader calls it in `onLoaded`
(:614, :636, :660, :683, :706). **If you add a keyboard panel, do the same or typing
won't work until the user clicks.**

### Layer swapping

~20 sibling `Loader { anchors.fill: parent; active: <expr on activity/expanded> }`
(:442-735). The booleans are mutually exclusive, so exactly one layer exists at a time —
Qt destroys and recreates on every switch. There is no persistent stack, and no layer may
assume it keeps state across a state change (that is why the `*Source` objects live at
shell scope).

Each Loader threads the font families (`textFontFamily`, `heroFontFamily`,
`iconFontFamily`, read from `userConfig` at :39-41) into the layer and wires
`onCloseRequested: root.closePanel()`.

### Connections

- `notifications.onReceived` (:198-207) — ignored while a keyboard panel is open, else
  stores `bannerItem` and `showTransient("banner")`.
- `captureController.onScreenshotCaptured/onScreenshotDismissed` (:354-364).
- `SystemServices.onVolumeSnapshotReady` (:366-375) — silently syncs the value; does **not**
  pop the HUD (that's `HudSource`'s job).

## 2.3 `IslandTokens.qml`

Non-visual value table. Sizes (`Qt.size(w,h)`, :45-69):

| token | size | token | size |
| --- | --- | --- | --- |
| idleCompact | 148×34 | mediaCompact | 244×38 |
| mediaExpanded | 372×196 | notificationCompact | 246×37 |
| notificationExpanded | 348×106 | recordingCompact | 214×38 |
| recordingExpanded | 340×92 | controlCompact | 246×38 |
| controlExpanded | 372×178 | volumeCompact | 272×42 |
| clockCompact | 232×38 | shotCompact | 246×37 |
| shotExpanded | 348×106 | launcherCompact | 260×38 |
| launcherExpanded | 460×246 | clipboardCompact | 252×38 |
| clipboardExpanded | 460×268 | notifyCompact | 246×38 |
| notifyExpanded | 420×296 | notifyBanner | 372×58 |
| workspacesCompact | 258×38 | workspacesExpanded | 452×336 |
| timerCompact/Expanded, deviceExpanded | defined but unused (reserved) |

Colours (:18-42): `fg` white plus an alpha ramp `fg85 … fg06`, `chip`/`chipHover`/`chipPressed`
(white 12/18/24 %), `accent` `#f2b32c`, `accent2` `#34c85a`, `accent3` `#ff9f0a`,
`danger` `#ff453a`, `accept` `#30d158`, `nav` `#0a84ff` (active toggle blue), `onFill`
black 70 %. 38 Nerd Font glyph codepoints at :72-108 referenced by name from every layer.

Changing a size here is enough to reshape the capsule — the springs animate to it.

## 2.4 `IslandMotion.qml`

| Property | Value | Used for |
| --- | --- | --- |
| `shapeSpring` / `shapeDamping` / `shapeMass` / `shapeEpsilon` | 3.6 / 0.42 / 1.0 / 0.25 | capsule width+height `Behavior` (the morph) |
| `contentExitDuration` | 100 | old content fade-out |
| `contentRevealDelay` | 110 | wait before new content enters |
| `contentRevealDuration` | 200 | new content fade+slide |
| `contentRevealOffset` | 7 | px it slides up from |
| `buttonSpring` / `buttonDamping` / `buttonColorDuration` | 6.0 / 0.35 / 140 | button press/hover feel |
| `pressScale` | 0.972 | capsule press-down |
| `longPressInterval` | 420 | long-press to expand |
| `idleBreathScale` / `idleBreathOpacity` / `idleBreathDuration` | 1.012 / 0.93 / 2600 | idle breathing |
| `settleDuration` | 420 | nominal, informational |
| `radiusSpring/Damping/Epsilon`, `pulseScale`, `pulseAttackDuration` | — | currently unused leftovers |

Slower, heavier morph → lower `shapeSpring` and/or raise `shapeDamping`. Snappier content →
lower `contentRevealDelay`/`contentRevealDuration`.

## 2.5 `IslandContentReveal.qml` — the layer contract

```qml
IslandContentReveal { target: body; active: root.showCondition }
```

The rules (header comment :9-15) — **every layer follows them**:

- the layer exposes a `revealOffset` property and applies `transform: Translate { y: revealOffset }`
- the layer must **not** bind its own `opacity`; this object owns it
- `active` is normally bound to the layer's `showCondition`

Enter: `PauseAnimation(revealDelay)` → parallel `opacity→1` (OutCubic) and `revealOffset→0`
(OutBack, overshoot 1.15). Exit: `opacity→0` (InQuad) then snap `revealOffset` back.
This is why every panel has that little overshoot when it appears.

## 2.6 Shared widgets

| File | Size | API |
| --- | --- | --- |
| `IslandCircleButton.qml` | 42×42 circle | `glyph`, `glyphSize` (18), `active`, `activeColor` (tokens.nav), `inactiveColor`, `glyphColor`; signal `activated()`. Hover 1.04, press 0.94, colour steps chip→chipHover→chipPressed. |
| `IslandActionPill.qml` | 28 px tall pill | `glyph`, `label`, `destructive` (colours it `tokens.danger`); signal `activated()`; press 0.95. |
| `IslandCapsuleSlider.qml` | 26 px tall | `value` (0–1), `glyph`, `interactive`; signals `moved(value)`, `released(value)`. Fill has its own local spring (4.2 / 0.62); glyph flips to black once `value > 0.12`. |
| `IslandSearchField.qml` | 34 px tall | `placeholder`, `hint` ("ESC"), readonly `text`; signals `accepted`, `cancelled`, `moveDown`, `moveUp`, `deleteSelected`, `textEdited(v)`; functions `clear()`, `grabFocus()`. Keys: ↑ ↓ Enter Esc, Ctrl/Meta+Backspace = delete selected. |
| `AlbumArt.qml` | any | `source`, `cornerRadius` (6). Always paints a warm→violet gradient placeholder underneath, so missing/loading artwork never shows a hole. |

Reusing these three widgets is the fastest way to make a new panel look native.

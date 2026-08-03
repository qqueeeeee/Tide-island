# 9. Recipes

Worked, end-to-end changes. Each lists every file you must touch.

## 9.1 Move the island down / resize it

`~/.config/tide-island/userconfig.json` or the settings app → Island page. No code:
`islandTopMargin`, `islandHeight` + `islandHeightOverrideEnabled`, `islandScale`,
`islandCornerRadius`, `islandBackgroundOpacity`, `islandBottomGap`, `islandReserveSpace`.

Hardcoded fallback if you really want a different default:
`qml/nucleus/NucleusIslandWindow.qml:44`.

## 9.2 Make the bar shorter

Settings app → Status Bar:

1. turn **Use island baseline** off
2. set **Height** to e.g. `24`
3. tune **Baseline offset** (−40…120) until the text sits where you want
4. optionally drop **Font size** / **Icon size** to 11

## 9.3 Change a size or colour of a state

`qml/nucleus/IslandTokens.qml` — sizes at :45-69, colours at :18-42, glyphs at :72-108.
Changing `mediaExpanded` to `Qt.size(400, 210)` is enough; the shape spring animates to it.
Restart the shell, no rebuild.

**Gotcha:** `IslandTokens.idleCompact` (148×34) is mirrored by hand in
`qml/nucleus/NucleusStatusBarWindow.qml:29-30`. Change both or the bar's layout anchor drifts.

## 9.4 Change the animation feel

`qml/nucleus/IslandMotion.qml`. Heavier morph: lower `shapeSpring` / raise `shapeDamping`.
Snappier content: lower `contentRevealDelay` (110) and `contentRevealDuration` (200).
Long-press threshold: `longPressInterval` (420).

## 9.5 Add a brand-new activity / panel

Example: a "Weather" panel on SUPER + T.

1. **Tokens** — add `weatherCompact` and `weatherExpanded` sizes to `IslandTokens.qml`.
2. **Layers** — create `qml/nucleus/WeatherCompactLayer.qml` and
   `WeatherExpandedLayer.qml` following the layer contract in
   [03](03-layers-and-sources.md): root `Item`, `anchors.fill: parent`, `opacity: 0`,
   `revealOffset` + `Translate`, `showCondition`, `IslandContentReveal`, no self-set
   `opacity`. Reuse `IslandCircleButton` / `IslandActionPill` / `IslandCapsuleSlider` /
   `IslandSearchField` so it looks native.
3. **Source** (if it needs data) — `qml/nucleus/WeatherSource.qml`, an invisible `Item`
   exposing plain properties; instantiate it once in `shell.qml` and pass it into each
   island.
4. **State machine** in `NucleusIslandWindow.qml`:
   - if it's keyboard-driven, add `"weather"` to the `panelActivity` set; if momentary, to
     `transientActivity` and give it a `dismissMs`
   - add it to `hasExpanded`
   - add its two cases to `targetSize`
   - add a `toggleWeather()` function calling `openPanel("weather")`
   - add the two `Loader`s with `active: activity === "weather" && !expanded` /
     `&& expanded`, wire `onCloseRequested: root.closePanel()`, and in the expanded
     Loader's `onLoaded` call `root.armPanel(item)` **if it takes keyboard input**
5. **IPC** — a `toggleWeather` function on the `IpcHandler` in `shell.qml`, through the
   debounce guard.
6. **Keybind** — `bind = SUPER, T, exec, qs ipc call tide toggleWeather` in `hyprland.conf`.

No rebuild needed unless you added a C++ backend.

## 9.6 Add a config option (the five-file rule)

Example: `statusBarShowMyThing`.

| Step | File |
| --- | --- |
| 1 | `backend/UserConfigBackend.h` — read-only `Q_PROPERTY(bool statusBarShowMyThing …)` |
| 2 | `backend/UserConfigBackend.cpp` — parse in `loadFromJson` (`jsonBool`, near :771-813); clamp ranges here |
| 3 | consumer QML — `visible: root.userConfig.statusBarShowMyThing` |
| 4 | `Tide-island-app/ConfigStore.qml` — default + property + include in the saved JSON |
| 5 | `Tide-island-app/PageStatusBar.qml` — a `UiSwitch` bound to it |

Then `cmake --build build && cmake --install build` and restart. **Identical key name in all
five places** or it silently does nothing.

## 9.7 Add a bar item

See [04 §4.3](04-status-bar.md). Short version: new `qml/bar/BarX.qml`, instantiate in
`StatusBarLayer.qml`'s left or right cluster, add a `statusBarShowX` key via §9.6, and if it
must be clickable extend the `leftInput*` / `rightInput*` mask rects — otherwise clicks fall
through to the window behind.

## 9.8 Give an app a custom notification icon/colour

`qml/nucleus/NotifySource.qml:53-80` — the app-name substring → glyph/tint heuristics. Add a
branch, pick a glyph name from `IslandTokens` (:72-108).

## 9.9 Fix wallpaper "socket error /run/…"

The swww/awww daemon isn't running. Either `exec-once = swww-daemon` (or `hyprpaper`) in
`hyprland.conf`, or reorder the chain in `qml/nucleus/WallpaperSource.qml:61-109` to try
`hyprpaper` first. Manual equivalent:

```bash
hyprctl hyprpaper preload "$IMG" && hyprctl hyprpaper wallpaper ",$IMG"
```

## 9.10 A panel opens then instantly closes

Double-fire: the same keybind exists in `hyprland.conf` **and** is registered by the settings
app. The 280 ms guard in `shell.qml` catches most cases; remove one of the two definitions.

## 9.11 Typing doesn't go to a panel

The expanded Loader's `onLoaded` is missing `root.armPanel(item)`, or the layer isn't a
`FocusScope`. See [02 §2.2](02-island-runtime.md).

## 9.12 More than 9 workspaces

Three places: `qml/nucleus/WorkspaceSource.qml` (`count` is fixed at 9), the digit-key block
in `WorkspacesExpandedLayer.qml:78-81`, and that layer's 3×3 grid maths.

# 4. The status bar

Live files: `qml/nucleus/NucleusStatusBarWindow.qml` (the window),
`qml/bar/StatusBarLayer.qml` (the layout), and the widgets
`BarWorkspaceDots.qml`, `BarActiveWindow.qml`, `BarStatusCluster.qml`,
`BarBatteryIndicator.qml`, `BarLabel.qml`, `BarHyprlandWorkspaceModel.qml`,
plus `qml/island/IslandClock.qml` (the one surviving file from the old tree) and
`qml/common/HyprlandDispatch.qml`.

`qml/bar/StatusBarWindow.qml` is **dead** — do not edit it.

## 4.1 The window

`NucleusStatusBarWindow.qml`:

| Line | What |
| --- | --- |
| :28 | `islandScale = clamp(userConfig.islandScale/100, 0.6, 1.6)` — note it ignores `islandHeightOverrideEnabled`, so the bar's placeholder is always scale-based |
| :29-30 | `islandRestingWidth = 148 * scale`, `islandRestingHeight = 34 * scale` — **hardcoded mirror of `IslandTokens.idleCompact`**; if you change that token, change these too |
| :34 | `islandTopOffset = max(0, userConfig.islandTopMargin)` |
| :38 | `restingIslandX = round((width - islandRestingWidth)/2)` — layout is built around this fixed rect, never the live capsule |
| :40 | `compositorIsNiri` — gates the Hyprland workspace model |
| :46 | `exclusionMode: ExclusionMode.Ignore` — the island already reserves the strip |
| :47 | `implicitHeight = max(1, ceil(bar.requiredWindowHeight))` |
| :48 | `visible: userConfig.statusBarEnabled` |
| :50-65 | input mask: only `bar.leftInput*` and `bar.rightInput*` rects are clickable |
| :67-71 | `IslandClock { clockFormat; showSeconds }` |
| :73-79 | `HyprlandDispatch` (workspace clicks) + Pipewire sink tracker for the mute glyph |
| :86-101 | `Loader` for `BarHyprlandWorkspaceModel.qml`, only when workspaces are enabled and the compositor is not niri |
| :103-133 | `StatusBarLayer`, fed the resting rect, workspace ids, clock text, `SysBackend.batteryCapacity`/charging, mute state; `onWorkspaceFocusRequested → dispatch.focusWorkspace(id)` |

`revealProgress: 1` and `islandBusy: false` are hardcoded (:114-115) — the bar never animates
with the island by design.

## 4.2 Config keys

All are `statusBar*` properties on `UserConfigBackend`
(`backend/UserConfigBackend.h:72-111`, parsed in `UserConfigBackend.cpp:771-813`) and are
consumed in `StatusBarLayer.qml` unless noted.

### Size and position

| Key | Type / default | Effect |
| --- | --- | --- |
| `statusBarEnabled` | bool `true` | show/hide the whole bar |
| `statusBarHeight` | px `34` [0,240] | explicit height; `0` = follow island baseline (`configuredHeight`, :66) |
| `statusBarUseIslandBaseline` | bool `true` | `followIsland` (:65) — track the island's resting baseline vs use `statusBarTopMargin` |
| `statusBarTopMargin` | px `0` [0,240] | top margin when not following the island (:75, :96) |
| `statusBarBaselineOffset` | px `0` [-40,120] | nudge all content up/down (`baselineY`, :70-72) |
| `statusBarSideMargin` | px `22` [0,400] | screen-edge margin for both clusters (:58) |
| `statusBarIslandGap` | px `14` [0,200] | gap kept between capsule and nearest cluster (:60) |
| `statusBarItemSpacing` | px `14` [0,80] | spacing inside a cluster (:61, :151, :200) |
| `statusBarIconSpacing` | px `9` [0,40] | spacing between status glyphs (:62) |

**To make the bar shorter:** set `statusBarHeight` to e.g. 24 and turn
`statusBarUseIslandBaseline` off, then tune `statusBarBaselineOffset`.

### Typography and colour

| Key | Type / default | Effect |
| --- | --- | --- |
| `statusBarFontSize` | px `13` [7,40] | general text (:79) |
| `statusBarClockFontSize` | px `13` [7,40] | clock (:80) |
| `statusBarIconSize` | px `13` [7,40] | wifi/BT/mute glyphs (:81) |
| `statusBarFontWeight` | `600` [300,900] | text weight (:82) |
| `statusBarTextOpacity` | % `100` [10,100] | text/icon alpha (:84) |
| `statusBarTextShadow` | bool `true` | drop shadow, forwarded to dots/title/labels (:85) |
| `statusBarTextColor` | hex `#ffffff` | text/icon colour (:86) |
| `statusBarOpacity` | % `100` | whole-bar opacity (:87) |

### Background plate (off by default)

| Key | Default | Effect |
| --- | --- | --- |
| `statusBarBackgroundEnabled` | `false` | show the plate (:135) |
| `statusBarBackgroundColor` | `#000000` | plate colour (:144) |
| `statusBarBackgroundOpacity` | % `45` | plate opacity (:145) |
| `statusBarBackgroundRadius` | px `0` [0,60] | plate corner radius (:143) |
| `statusBarBackgroundMargin` | px `0` [0,200] | horizontal inset (:138, :140) |

### Items

| Key | Default | Effect |
| --- | --- | --- |
| `statusBarShowWorkspaces` | true | workspace dots (:45, :165) |
| `statusBarShowActiveWindow` | true | focused window title (:46, :181) |
| `statusBarShowClock` | true | clock label (:48, :242) |
| `statusBarShowSeconds` | false | consumed by `IslandClock.showSeconds` (`NucleusStatusBarWindow.qml:65`) |
| `statusBarShowDate` | false | always show date + time (:245-246) |
| `statusBarShowDateOnHover` | true | swap to date on hover (:257-258) |
| `statusBarShowWifi` / `ShowBluetooth` / `ShowBattery` / `ShowMute` | true | individual glyphs (:226-229 → `BarStatusCluster`) |
| `statusBarBatteryScale` | % `100` [50,220] | battery pill scale (`BarStatusCluster.qml:27`, used :106-113) |
| `statusBarActiveWindowMaxWidth` | px `0` [0,1600] | cap title width, 0 = auto (:189-191) |
| `statusBarActiveWindowOpacity` | % `100` [20,100] | title opacity (:188) |

### Workspace dots

| Key | Default | Effect |
| --- | --- | --- |
| `statusBarWorkspaceDotSize` | px `7` [2,28] | dot size (:169) |
| `statusBarWorkspaceActiveWidth` | px `18` [4,80] | active dot stretched into a pill (:170-171) |
| `statusBarWorkspaceSpacing` | px `6` [0,40] | spacing (:172) |
| `statusBarWorkspaceMinimumCount` | `4` [1,10] | always draw at least this many dots (:173) |

### Island interaction

| Key | Default | Effect |
| --- | --- | --- |
| `statusBarFadeWithIsland` | true | dim the bar while the island is busy (:91-93) |
| `statusBarDimAmount` | % `40` [0,100] | how much it dims (:92-93) |

Because `islandBusy` is hardcoded `false` today, these two currently have no visible effect —
they are the hook if you ever want the dim-on-expand behaviour back.

### Known dead keys

- `statusBarShowStatusIcons` — read into `statusIconsEnabled` (:47) but nothing consumes it;
  superseded by the four per-icon flags.
- `statusBarShowRecordingPill` — no consumer at all; recording lives in the island now, on
  purpose.

## 4.3 Adding a new bar item

1. Write `qml/bar/BarMyThing.qml` styling itself from the props `StatusBarLayer` already
   threads around (`textPixelSize`, `textWeight`, `textColor`, `textAlpha`, `shadowEnabled`).
2. Instantiate it inside `leftCluster` or `rightCluster` in `StatusBarLayer.qml`
   (around :151 / :200) with `visible: root.userConfig.statusBarShowMyThing`.
3. Add `statusBarShowMyThing` to `backend/UserConfigBackend.h` + `.cpp` and to
   `Tide-island-app/ConfigStore.qml` defaults, then a `UiSwitch` in
   `Tide-island-app/PageStatusBar.qml`. Full walkthrough in [09](09-recipes.md).
4. If it must be clickable, extend the left/right input rects
   (`leftInput*`/`rightInput*` in `StatusBarLayer.qml`) or the click will pass through to the
   window underneath.

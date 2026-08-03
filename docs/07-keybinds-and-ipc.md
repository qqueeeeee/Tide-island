# 7. Keybinds and IPC

Everything user-triggered enters the shell through **one** door: Quickshell's IPC. There are
no global-hotkey grabs inside the shell; the compositor runs a command and that command
talks to the running shell.

```
hyprland.conf bind ──► qs ipc call tide <handler> [args] ──► shell.qml IpcHandler ──► island function
```

## 7.1 The handler

`shell.qml` declares `IpcHandler { target: "tide" }` with one function per action. Roughly:

| Handler | Effect |
| --- | --- |
| `toggleLauncher` | `openPanel("launcher")` |
| `toggleClipboard` | `openPanel("clipboard")` |
| `toggleNotifications` | `openPanel("notify")` |
| `toggleWorkspaces` | `openPanel("workspaces")` |
| `toggleWallpaper` | `openPanel("wallpaper")` |
| `toggleControlCenter` | `toggleControlCentre()` |
| `togglePlayer` | expand/collapse the media Live Activity |
| `showClock` | `showClockPeek()` (2.6 s peek) |
| `screenshot` / `screenshotRegion` | `captureController` screenshot flows |
| `toggleRecording` / `pauseRecording` | recorder control |
| `settings` | launches `tide-island-config-app` |

Because `openPanel(kind)` is a **toggle**, one binding both opens and closes a panel.

Call any of them by hand to test:

```bash
qs ipc call tide toggleLauncher
qs ipc call tide showClock
qs ipc call tide toggleControlCenter
```

If `qs` can't find the shell, you have two shells running or the shell isn't up — see
[08](08-build-install-test.md).

## 7.2 The debounce guard

Every handler funnels through a guard in `shell.qml` that drops a repeat of the **same**
action inside **280 ms**. This exists because the settings app can register keybinds while
the same bindings also live in `hyprland.conf`; without it, panels opened and closed in the
same frame.

The guard is a workaround, not a fix — define each binding in exactly one place.

## 7.3 Compositor bindings

Recommended `hyprland.conf` block (matches the defaults):

```ini
exec-once = tide-island
exec-once = hyprpaper          # needed for wallpaper applying

bind = SUPER, Space,      exec, qs ipc call tide toggleLauncher
bind = SUPER, V,          exec, qs ipc call tide toggleClipboard
bind = SUPER, N,          exec, qs ipc call tide toggleNotifications
bind = SUPER, Tab,        exec, qs ipc call tide toggleWorkspaces
bind = SUPER, W,          exec, qs ipc call tide toggleWallpaper
bind = SUPER, C,          exec, qs ipc call tide toggleControlCenter
bind = SUPER, comma,      exec, qs ipc call tide settings
bind = SUPER SHIFT, S,    exec, qs ipc call tide screenshotRegion
bind = SUPER SHIFT, R,    exec, qs ipc call tide toggleRecording
```

Notes:

- **Do not also enable the same binds in the settings app** (double-fire, §7.2).
- The island grabs the keyboard only while a panel is open
  (`WlrLayershell.keyboardFocus` follows `keyboardPanel`), so normal typing is unaffected.
- Escape always closes the open panel; right-click on the capsule is a universal "back".

## 7.4 Adding a new keybind + action

1. Add a function to the `IpcHandler` in `shell.qml`, routed through the debounce guard.
2. Have it call an existing island function, or add a new one to
   `NucleusIslandWindow.qml` next to `openPanel`/`showTransient`.
3. If it opens a new panel kind, register it in the `panelActivity` list, `hasExpanded`,
   `targetSize`, and add the two `Loader`s (compact + expanded) — see
   [09](09-recipes.md).
4. Bind it in `hyprland.conf`. Test with `qs ipc call tide <name>` first; if that works and
   the key doesn't, the problem is the compositor config, not the shell.

## 7.5 Which services must be off

The shell **is** the notification daemon (`NotifySource` runs a
`NotificationServer`). Disable mako / dunst / swaync, otherwise the other daemon wins the
D-Bus name and no notification ever reaches the island.

Clipboard history needs `cliphist` + `wl-clipboard` running as usual
(`wl-paste --watch cliphist store`).

# Nucleus island — keybinds

Add these to `~/.config/hypr/hyprland.conf`. Every panel opens the island
expanded and grabs the keyboard; `Esc` (or right-click) closes it.

```conf
# Island panels
bind = SUPER, SPACE,       exec, qs -c tide-island ipc call island launcher
bind = SUPER, V,           exec, qs -c tide-island ipc call island clipboard
bind = SUPER, N,           exec, qs -c tide-island ipc call island notifications
bind = SUPER, TAB,         exec, qs -c tide-island ipc call island workspaces
bind = SUPER SHIFT, C,     exec, qs -c tide-island ipc call island controlCenter

# Capture
bind = SUPER SHIFT, S,     exec, qs -c tide-island ipc call capture screenshot
bind = SUPER SHIFT, R,     exec, qs -c tide-island ipc call capture toggleRecording
```

## Requirements

| Panel        | Needs                                                       |
| ------------ | ----------------------------------------------------------- |
| Launcher     | nothing (reads `.desktop` entries)                          |
| Clipboard    | `cliphist`, `wl-clipboard` (`wl-copy`), and a `cliphist store` watcher |
| Notifications| nothing — the shell registers itself as the notification daemon, so disable `mako`/`dunst` |
| Workspaces   | `hyprctl` (Hyprland)                                        |

Clipboard watcher, if it is not already running:

```conf
exec-once = wl-paste --watch cliphist store
```

## Panel keys

- Launcher / Clipboard: type to filter, `↑↓` to move, `↵` to launch or paste,
  `Ctrl/Super + ⌫` to delete a clipboard entry.
- Notifications: click a stacked group to expand it, `×` dismisses one or the
  whole group, `Focus` toggles Do Not Disturb.
- Workspaces: `←→↑↓` or `Tab` to move, `1`–`9` to jump, `↵` to switch.

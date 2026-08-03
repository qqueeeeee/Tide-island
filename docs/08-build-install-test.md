# 8. Build, install, test

## 8.1 What gets built

`CMakeLists.txt` at the repo root produces:

| Target | Output | Notes |
| --- | --- | --- |
| `IslandBackend` | `lib/qt6/qml/IslandBackend/` | the QML plugin holding every `backend/*.cpp` singleton (`CMakeLists.txt:160-182`) |
| `lyricsmpris` | binary | standalone MPRIS lyrics helper |
| `Tide-island-app` | `tide-island-config-app` | the settings GUI (own `CMakeLists.txt`) |
| QML tree | `share/tide-island/` | `shell.qml` + `qml/**` installed as data |
| launcher | `tide-island` | shell script that runs `qs -p <shell.qml>` |

Options: `TIDE_ISLAND_WITH_NIRI` (default ON) compiles the niri IPC path in
`CompositorBackend`.

## 8.2 Building

```bash
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$HOME/.local
cmake --build build -j
cmake --install build
```

Dependencies: Qt 6 (Core, Gui, Qml, Quick, DBus), Quickshell, plus runtime tools —
`hyprland`, `hyprpaper` (or swww/awww/swaybg), `grim`, `slurp`, `grimblast`, `satty`,
`wf-recorder`, `cliphist`, `wl-clipboard`, `wpctl`/`pactl` (PipeWire), optionally
`hyprsunset`, `cava`, `wal`.

### When do I need a rebuild?

| Changed | Action |
| --- | --- |
| `qml/**`, `shell.qml` | restart the shell only (`pkill tide-island; tide-island`) — no rebuild |
| `backend/**` | full `cmake --build` + `cmake --install` + restart |
| `Tide-island-app/**` QML | rebuild the app target (QML is in `resources.qrc`) |
| `userconfig.json` | nothing — the shell watches the file |

## 8.3 `install.sh`

Wraps the cmake flow and the extras. Useful flags:

| Flag | Effect |
| --- | --- |
| `--skip-deps` | don't try to install packages |
| `--no-quickshell` | don't install/patch the quickshell config |
| `--no-service` | don't install/enable the systemd user unit |

Typical dev use: `./install.sh --skip-deps --no-quickshell --no-service`, then start the shell
by hand from `hyprland.conf`.

`PKGBUILD` + `tide-island.install` cover the AUR path; `tide-island.service` is the systemd
user unit. **Pick one startup method** — a unit *and* an `exec-once` gives you two islands.

## 8.4 Verifying you run the build you think you do

```bash
pgrep -a tide-island                # should be exactly ONE line
readlink -f /proc/$(pgrep -f 'qs -p' | head -1)/exe
which -a tide-island tide-island-config-app
systemctl --user list-units | grep tide
git -C <repo> log -1 --oneline
```

Two islands almost always means: an AUR/`/usr/bin` install plus a `~/.local/bin` install, or a
systemd unit plus `exec-once`. Remove one.

Clean rebuild when in doubt:

```bash
rm -rf build && cmake -B build -S . -DCMAKE_INSTALL_PREFIX=$HOME/.local && cmake --build build -j && cmake --install build
```

## 8.5 Tests

CTest, defined in `tests/` and `Tide-island-app/tests/`:

```bash
ctest --test-dir build --output-on-failure
ctest --test-dir build -R compositor      # one suite
```

Notable suites:

| Test | Covers |
| --- | --- |
| `compositor_backend_tests.cpp` | compositor detection, niri workspace event parsing |
| `lyricsmpris_runtime_tests.cpp` | lyrics helper against a fake MPRIS player on an isolated D-Bus session |
| `LyricsCore` unit tests | sync/parse logic |
| `wallpaper_apply` (app) | settings-app wallpaper page assets and apply flow |

`wallpaper_apply` fails with a `FileNotFoundError` if a settings page file it loads was
renamed or moved — update the test path when you move pages.

## 8.6 Debugging

- Shell logs: run `tide-island` in a terminal; QML `console.log`, `WARN scene: …` and
  `ReferenceError`s all show there. A `ReferenceError` almost always means a property/object
  used in `shell.qml` was never declared (e.g. the old `settingsApp is not defined`).
- `Type X unavailable … Invalid property assignment: int expected` = a fractional value
  assigned to an int property; `font.pixelSize: 11.5` is the classic. Round it.
- Test IPC without touching keybinds: `qs ipc call tide <handler>`.
- Check a config value actually reached the shell by binding it to a visible `Text`
  temporarily, or `jq . ~/.config/tide-island/userconfig.json`.

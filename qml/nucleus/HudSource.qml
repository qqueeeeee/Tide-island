pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Live volume / brightness watcher for the momentary HUD pill.
//
// Both watchers are single long-lived shell loops that only print when the
// value actually changes, so there is no per-frame process churn:
//
//   * volume     — `pactl subscribe` on the default sink, read back with
//                  wpctl (PipeWire) or pactl (PulseAudio)
//   * brightness — polls /sys/class/backlight (plain file reads)
//
// The first reading of each is swallowed so the island does not flash a HUD
// at shell startup.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    signal volumeChanged(real value, bool muted)
    signal brightnessChanged(real value)

    property bool sawVolume: false
    property bool sawBrightness: false

    Process {
        running: true
        command: ["bash", "-lc", `
            read_volume() {
                if command -v wpctl >/dev/null 2>&1; then
                    out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || return 1
                    vol=$(printf '%s' "$out" | awk '{print $2}')
                    case "$out" in *MUTED*) mute=1 ;; *) mute=0 ;; esac
                elif command -v pactl >/dev/null 2>&1; then
                    vol=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | head -n1 | grep -o '[0-9]\\+%' | head -n1 | tr -d '%')
                    [ -n "$vol" ] || return 1
                    vol=$(awk -v v="$vol" 'BEGIN { printf "%.3f", v / 100 }')
                    case "$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)" in *yes*) mute=1 ;; *) mute=0 ;; esac
                else
                    return 1
                fi
                printf 'V %s %s\\n' "$vol" "$mute"
            }
            read_volume
            if command -v pactl >/dev/null 2>&1; then
                pactl subscribe 2>/dev/null | while read -r line; do
                    case "$line" in *sink*|*server*) read_volume ;; esac
                done
            fi
        `]

        stdout: SplitParser {
            onRead: (line) => {
                const parts = String(line).trim().split(/\s+/);
                if (parts[0] !== "V" || parts.length < 3)
                    return;
                const value = Number(parts[1]);
                if (isNaN(value))
                    return;
                if (!root.sawVolume) {
                    root.sawVolume = true;
                    return;
                }
                root.volumeChanged(value, parts[2] === "1");
            }
        }
    }

    Process {
        running: true
        command: ["bash", "-lc", `
            prev=""
            while :; do
                pct=""
                for d in /sys/class/backlight/*; do
                    [ -r "$d/brightness" ] && [ -r "$d/max_brightness" ] || continue
                    cur=$(cat "$d/brightness" 2>/dev/null)
                    max=$(cat "$d/max_brightness" 2>/dev/null)
                    [ -n "$cur" ] && [ -n "$max" ] && [ "$max" -gt 0 ] || continue
                    pct=$(awk -v c="$cur" -v m="$max" 'BEGIN { printf "%.3f", c / m }')
                    break
                done
                if [ -n "$pct" ] && [ "$pct" != "$prev" ]; then
                    printf 'B %s\\n' "$pct"
                    prev="$pct"
                fi
                sleep 0.25
            done
        `]

        stdout: SplitParser {
            onRead: (line) => {
                const parts = String(line).trim().split(/\s+/);
                if (parts[0] !== "B" || parts.length < 2)
                    return;
                const value = Number(parts[1]);
                if (isNaN(value))
                    return;
                if (!root.sawBrightness) {
                    root.sawBrightness = true;
                    return;
                }
                root.brightnessChanged(value);
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick

// Visual tokens ported 1:1 from the React reference build
// (src/styles.css `--island-*` + the SPECS metrics table).
//
// Every island layer reads its colours, sizes and paddings from here so the
// Quickshell surface renders the same pixels as the reference gallery.
Item {
    id: root

    visible: false
    width: 0
    height: 0

    // --- Colours (oklch tokens resolved to sRGB) ---------------------------
    readonly property color fg: "#ffffff"
    readonly property color fg85: "#d9ffffff"
    readonly property color fg70: "#b3ffffff"
    readonly property color fg60: "#99ffffff"
    readonly property color fg55: "#8cffffff"
    readonly property color fg50: "#80ffffff"
    readonly property color fg35: "#59ffffff"
    readonly property color fg18: "#2effffff"
    readonly property color chip: "#1fffffff"          // white / 12%
    readonly property color chipHover: "#2effffff"
    readonly property color chipPressed: "#3dffffff"
    readonly property color accent: "#f2b32c"          // --island-accent  (camera yellow)
    readonly property color accent2: "#34c85a"         // --island-accent2 (audio green)
    readonly property color accent3: "#ff9f0a"         // --island-accent3 (timer orange)
    readonly property color danger: "#ff453a"          // --island-danger
    readonly property color dangerSoft: "#2eff453a"    // danger / 18%
    readonly property color accept: "#30d158"          // --island-accept
    readonly property color nav: "#0a84ff"             // --island-nav (active toggle blue)
    readonly property color onFill: "#b3000000"        // black/70 on a filled slider

    // --- Metrics table (React SPECS, in reference px) ---------------------
    readonly property size recordingCompact: Qt.size(214, 38)
    readonly property size recordingExpanded: Qt.size(340, 92)
    readonly property size controlCompact: Qt.size(246, 38)
    readonly property size controlExpanded: Qt.size(372, 178)
    readonly property size volumeCompact: Qt.size(272, 42)
    readonly property size shotCompact: Qt.size(246, 37)
    readonly property size shotExpanded: Qt.size(348, 106)
    readonly property size deviceExpanded: Qt.size(318, 86)
    readonly property size mediaExpanded: Qt.size(372, 196)
    readonly property size timerExpanded: Qt.size(340, 132)

    // --- Nerd Font glyphs used by the ported layouts ----------------------
    readonly property string glyphWifi: "\uf1eb"
    readonly property string glyphBluetooth: "\uf293"
    readonly property string glyphMic: "\uf130"
    readonly property string glyphMicOff: "\uf131"
    readonly property string glyphMoon: "\uf186"
    readonly property string glyphSun: "\u{F00DF}"
    readonly property string glyphVolume: "\uf028"
    readonly property string glyphVolumeLow: "\uf027"
    readonly property string glyphCamera: "\uf030"
    readonly property string glyphVideo: "\uf03d"
    readonly property string glyphCopy: "\uf0c5"
    readonly property string glyphMarkup: "\uf040"
    readonly property string glyphOpen: "\uf08e"
    readonly property string glyphTrash: "\uf1f8"
}

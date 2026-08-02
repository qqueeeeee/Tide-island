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
    readonly property color fg45: "#73ffffff"
    readonly property color fg40: "#66ffffff"
    readonly property color fg25: "#40ffffff"
    readonly property color fg18: "#2effffff"
    readonly property color fg14: "#24ffffff"
    readonly property color fg09: "#17ffffff"
    readonly property color fg06: "#0fffffff"
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
    readonly property size idleCompact: Qt.size(148, 34)
    readonly property size mediaCompact: Qt.size(244, 38)
    readonly property size timerCompact: Qt.size(222, 38)
    readonly property size notificationCompact: Qt.size(246, 37)
    readonly property size notificationExpanded: Qt.size(348, 106)
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
    readonly property size launcherCompact: Qt.size(260, 38)
    readonly property size launcherExpanded: Qt.size(460, 246)
    readonly property size clipboardCompact: Qt.size(252, 38)
    readonly property size clipboardExpanded: Qt.size(460, 268)
    readonly property size notifyCompact: Qt.size(246, 38)
    readonly property size notifyExpanded: Qt.size(420, 296)
    readonly property size notifyBanner: Qt.size(372, 58)
    readonly property size workspacesCompact: Qt.size(258, 38)
    readonly property size workspacesExpanded: Qt.size(452, 336)

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
    readonly property string glyphGear: "\uf013"
    readonly property string glyphCopy: "\uf0c5"
    readonly property string glyphMarkup: "\uf040"
    readonly property string glyphOpen: "\uf08e"
    readonly property string glyphTrash: "\uf1f8"
    readonly property string glyphPlay: "\uf04b"
    readonly property string glyphPause: "\uf04c"
    readonly property string glyphNext: "\uf051"
    readonly property string glyphPrev: "\uf048"
    readonly property string glyphWave: "\uf001"
    readonly property string glyphBell: "\uf0f3"
    readonly property string glyphTimer: "\uf252"
    readonly property string glyphSearch: "\uf002"
    readonly property string glyphRocket: "\uf135"
    readonly property string glyphClipboard: "\uf0ea"
    readonly property string glyphImage: "\uf03e"
    readonly property string glyphLink: "\uf0c1"
    readonly property string glyphText: "\uf031"
    readonly property string glyphGrid: "\uf00a"
    readonly property string glyphBellOff: "\uf1f6"
    readonly property string glyphCheck: "\uf00c"
    readonly property string glyphClose: "\uf00d"
    readonly property string glyphTerminal: "\uf120"
    readonly property string glyphMail: "\uf0e0"
    readonly property string glyphPackage: "\uf187"
    readonly property string glyphMessage: "\uf075"
    readonly property string glyphMusic: "\uf001"
}

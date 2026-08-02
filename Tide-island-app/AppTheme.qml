pragma Singleton
import QtQuick

// Apple-flavoured design tokens for the settings app. Mirrors the island's
// palette: near-black glass surfaces, hairline separators, SF-ish typography.
QtObject {
    id: theme

    readonly property bool dark: backend.colorScheme !== "light"

    readonly property color windowBg: dark ? "#0d0d10" : "#f2f2f7"
    readonly property color sidebarBg: dark ? "#15151a" : "#e9e9ef"
    readonly property color cardBg: dark ? "#1b1b21" : "#ffffff"
    readonly property color cardBorder: dark ? "#26262e" : "#e2e2ea"
    readonly property color rowHover: dark ? "#22222a" : "#f4f4f8"
    readonly property color separator: dark ? "#26262e" : "#ececf1"
    readonly property color text: dark ? "#f5f5f7" : "#1d1d1f"
    readonly property color textDim: dark ? "#9a9aa2" : "#6e6e73"
    readonly property color textFaint: dark ? "#6d6d76" : "#8e8e93"
    readonly property color accent: "#0a84ff"
    readonly property color accentSoft: dark ? "#1f3050" : "#dceaff"
    readonly property color danger: "#ff453a"
    readonly property color trackOff: dark ? "#2e2e37" : "#dcdce3"
    readonly property color previewBg: dark ? "#101018" : "#20202c"

    readonly property string fontFamily: "Inter Display"
    readonly property int radiusCard: 16
    readonly property int radiusControl: 10
    readonly property int pad: 18
    readonly property int animation: 180
}

pragma Singleton
import QtQuick

// Apple/Island-flavoured design tokens for the settings app. Mirrors the
// island's own visual language (qml/nucleus/IslandTokens.qml): near-black
// glass surfaces, hairline separators, SF-ish typography, iOS accent green
// for active toggles. Every property that existed before is kept so other
// pages keep compiling; new tokens are additive.
QtObject {
    id: theme

    readonly property bool dark: backend.colorScheme !== "light"

    // --- Core surfaces (kept names) -----------------------------------
    readonly property color windowBg: dark ? "#08080a" : "#f2f2f7"
    readonly property color sidebarBg: dark ? "#0c0c0f" : "#e9e9ef"
    readonly property color cardBg: dark ? "#131316" : "#ffffff"
    readonly property color cardBorder: dark ? "#ffffff14" : "#e2e2ea"
    readonly property color rowHover: dark ? "#ffffff0f" : "#f4f4f8"
    readonly property color separator: dark ? "#ffffff14" : "#ececf1"
    readonly property color text: dark ? "#f5f5f7" : "#1d1d1f"
    readonly property color textDim: dark ? "#9a9aa2" : "#6e6e73"
    readonly property color textFaint: dark ? "#6d6d76" : "#8e8e93"
    readonly property color accent: "#0a84ff"
    readonly property color accentSoft: dark ? "#1f3050" : "#dceaff"
    readonly property color danger: "#ff453a"
    readonly property color trackOff: dark ? "#ffffff1f" : "#dcdce3"
    readonly property color previewBg: dark ? "#0a0a10" : "#20202c"

    readonly property string fontFamily: "Inter Display"
    readonly property int radiusCard: 20
    readonly property int radiusControl: 12
    readonly property int pad: 18
    readonly property int animation: 180

    // --- New: island-matching glass + accent tokens ---------------------
    // iOS control-centre accent green — used for active toggles/switches.
    readonly property color accentActive: "#30d158"
    readonly property color accentActiveSoft: "#2e30d158"

    // Glass chip surfaces lifted straight from IslandTokens (white-on-black
    // translucency) so nested controls read as part of the same material.
    readonly property color glassBg: "#cc0a0a0d"
    readonly property color glassBorder: "#ffffff1a"
    readonly property color chip: "#14ffffff"
    readonly property color chipHover: "#1fffffff"
    readonly property color chipPressed: "#29ffffff"
    readonly property color fillOnDark: "#d9ffffff"
    readonly property color onFill: "#b3000000"

    readonly property string iconFontFamily: "JetBrainsMono Nerd Font"

    // Island corner language: big soft radii, tall pill controls.
    readonly property int radiusCapsule: 999
    readonly property int radiusChip: 14
    readonly property int radiusNav: 14

    // SF-like type scale.
    readonly property int fontSizeTitle: 22
    readonly property int fontSizeHeading: 15
    readonly property int fontSizeBody: 13
    readonly property int fontSizeCaption: 12
    readonly property int fontSizeMicro: 11
}

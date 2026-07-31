pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Wayland

// Focused window title, compositor agnostic (wlr foreign-toplevel), so it works
// on both Hyprland and niri.
Item {
    id: root

    property string fallbackText: ""
    property string textFontFamily: ""
    property int pixelSize: 13
    property real maximumWidth: 260

    readonly property var activeToplevel: ToplevelManager.activeToplevel
    readonly property string appId: activeToplevel && activeToplevel.appId
        ? String(activeToplevel.appId)
        : ""
    readonly property string rawTitle: activeToplevel && activeToplevel.title
        ? String(activeToplevel.title)
        : ""

    function prettyAppId(value) {
        const source = String(value || "").trim();
        if (source === "")
            return "";

        const tail = source.split(".").pop();
        if (tail.length === 0)
            return source;

        return tail.charAt(0).toUpperCase() + tail.slice(1);
    }

    readonly property string displayText: {
        const app = prettyAppId(appId);
        if (app !== "")
            return app;

        const title = rawTitle.trim();
        if (title !== "")
            return title;

        return fallbackText;
    }

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    width: implicitWidth
    height: implicitHeight
    opacity: displayText === "" ? 0 : 1

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
    }

    BarLabel {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        fontFamily: root.textFontFamily
        pixelSize: root.pixelSize
        weight: Font.DemiBold
        maximumWidth: root.maximumWidth
    }
}

pragma ComponentBehavior: Bound

import QtQuick

// Reference `WorkspacesCompact`: 258 x 38 — grid glyph, nine pills (active one
// stretched to 16px), "n/9" counter.
Item {
    id: root

    property WorkspaceSource source: null
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    property real revealOffset: 0

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandTokens { id: tokens }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14

        Text {
            id: glyph

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: tokens.glyphGrid
            color: tokens.nav
            font.family: root.iconFontFamily
            font.pixelSize: 13
        }

        Text {
            id: counter

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: (root.source ? root.source.active : 1) + "/9"
            color: tokens.fg55
            font.family: root.textFontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
        }

        Row {
            anchors.left: glyph.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 5

            Repeater {
                model: root.source ? root.source.workspaces : []

                delegate: Rectangle {
                    required property var modelData

                    readonly property bool isActive: root.source
                        && root.source.active === modelData.id
                    readonly property bool occupied: modelData.windows.length > 0

                    width: isActive ? 16 : 6
                    height: 6
                    radius: 3
                    color: isActive
                        ? tokens.fg
                        : (occupied ? tokens.fg45 : "#26ffffff")

                    Behavior on width {
                        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                    }
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
            }
        }
    }
}

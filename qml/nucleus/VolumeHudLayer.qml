pragma ComponentBehavior: Bound

import QtQuick

// Reference `VolumeHud`: 272 x 42 momentary pill — glyph, level bar, percentage.
Item {
    id: root

    property real value: 0
    property bool muted: false
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
        anchors.leftMargin: 15
        anchors.rightMargin: 15

        Text {
            id: glyph

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: root.muted || root.value <= 0.001
                ? "\uf026"
                : (root.value > 0.5 ? tokens.glyphVolume : tokens.glyphVolumeLow)
            color: tokens.fg
            font.family: root.iconFontFamily
            font.pixelSize: 15
        }

        Rectangle {
            id: bar

            anchors.left: glyph.right
            anchors.leftMargin: 12
            anchors.right: percent.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: "#26ffffff"
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: 3
                width: parent.width * Math.max(0, Math.min(1, root.muted ? 0 : root.value))
                color: tokens.fg85

                Behavior on width {
                    SpringAnimation { spring: 4.2; damping: 0.62; mass: 1.0; epsilon: 0.25 }
                }
            }
        }

        Text {
            id: percent

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(Math.max(0, Math.min(1, root.value)) * 100) + "%"
            color: tokens.fg60
            font.family: root.textFontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
        }
    }
}

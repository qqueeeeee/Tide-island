pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Screen-recording surface, ported pixel-for-pixel from the React reference
// (`RecordingExpanded`): 340 x 92, a 44px soft-red circle with the video glyph
// on the left, pulsing dot + mono hero timer, and pause / stop circles right.
Item {
    id: root

    readonly property var userConfig: UserConfig

    property string elapsedText: "00:00"
    property string textFontFamily: ""
    property string heroFontFamily: ""
    property string iconFontFamily: userConfig.iconFontFamily
    property string sourceLabel: "Region"
    property bool showCondition: true
    property bool paused: false
    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    signal stopRequested()
    signal pauseToggleRequested()

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

        Rectangle {
            id: badge

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 44
            height: 44
            radius: height / 2
            color: tokens.dangerSoft

            Text {
                anchors.centerIn: parent
                text: tokens.glyphVideo
                color: tokens.danger
                font.family: root.iconFontFamily
                font.pixelSize: 18
            }
        }

        Column {
            anchors.left: badge.right
            anchors.leftMargin: 12
            anchors.right: controls.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Row {
                spacing: 7

                Rectangle {
                    id: liveDot

                    anchors.verticalCenter: parent.verticalCenter
                    width: 7
                    height: 7
                    radius: 3.5
                    color: tokens.danger
                    opacity: root.paused ? 0.45 : 1

                    SequentialAnimation on opacity {
                        running: !root.paused
                        loops: Animation.Infinite

                        NumberAnimation { to: 0.35; duration: 620; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 620; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.elapsedText
                    color: tokens.fg
                    font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
                    font.pixelSize: 21
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.5
                }
            }

            Text {
                text: (root.paused ? "Paused" : "Recording") + " \u00b7 " + root.sourceLabel
                color: tokens.fg55
                elide: Text.ElideRight
                font.family: root.textFontFamily
                font.pixelSize: 11
            }
        }

        Row {
            id: controls

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            IslandCircleButton {
                implicitWidth: 38
                implicitHeight: 38
                glyphSize: 15
                glyph: root.paused ? "\uf04b" : "\uf04c"
                iconFontFamily: root.iconFontFamily
                onActivated: root.pauseToggleRequested()
            }

            IslandCircleButton {
                implicitWidth: 38
                implicitHeight: 38
                glyphSize: 14
                glyph: "\uf04d"
                iconFontFamily: root.iconFontFamily
                inactiveColor: tokens.dangerSoft
                glyphColor: tokens.danger
                onActivated: root.stopRequested()
            }
        }
    }
}

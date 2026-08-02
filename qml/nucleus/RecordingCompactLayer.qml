pragma ComponentBehavior: Bound

import QtQuick

// Reference `RecordingCompact`: 214 x 38, 14px side padding, pulsing 9px dot,
// mono timer, region label pinned right at 55% white.
Item {
    id: root

    property string elapsedText: "00:00"
    property string sourceLabel: "Screen"
    property bool paused: false
    property string textFontFamily: ""
    property string heroFontFamily: ""
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

        Rectangle {
            id: dot

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 9
            height: 9
            radius: 4.5
            color: tokens.danger
            opacity: root.paused ? 0.45 : 1

            SequentialAnimation on opacity {
                running: !root.paused
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
            }
        }

        Text {
            id: elapsed

            anchors.left: dot.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: root.elapsedText
            color: tokens.fg
            font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Text {
            anchors.right: parent.right
            anchors.left: elapsed.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: root.sourceLabel
            color: tokens.fg55
            elide: Text.ElideRight
            font.family: root.textFontFamily
            font.pixelSize: 12
        }
    }
}

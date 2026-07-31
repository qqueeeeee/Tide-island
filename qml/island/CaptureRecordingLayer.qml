pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Compact "recording" capsule content: pulsing red dot plus an elapsed timer,
// mirroring the iOS recording pill. Clicking it stops the recording.
Item {
    id: root

    readonly property var userConfig: UserConfig

    property string elapsedText: "00:00"
    property string textFontFamily: ""
    property bool showCondition: true

    signal stopRequested()

    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Rectangle {
            id: dot

            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: "#ff453a"

            SequentialAnimation on opacity {
                running: root.showCondition
                loops: Animation.Infinite

                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.elapsedText
            color: "#ffffff"
            font.family: root.textFontFamily
            font.pixelSize: root.userConfig.bodyFontSize
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onClicked: root.stopRequested()
    }
}

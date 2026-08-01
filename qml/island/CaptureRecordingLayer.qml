pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// iOS-style recording capsule: pulsing red dot + elapsed timer pinned to the
// left, pause/resume and stop buttons pinned to the right. The island is the
// primary recording surface, so every control lives here.
Item {
    id: root

    readonly property var userConfig: UserConfig

    property string elapsedText: "00:00"
    property string textFontFamily: ""
    property bool showCondition: true
    property bool paused: false

    signal stopRequested()
    signal pauseToggleRequested()

    anchors.fill: parent
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }

    // --- Left: recording dot + timer ---
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            id: dot

            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            radius: 5
            color: "#ff453a"
            opacity: root.paused ? 0.45 : 1

            SequentialAnimation on opacity {
                running: root.showCondition && !root.paused
                loops: Animation.Infinite

                NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.elapsedText
            color: "#ffffff"
            opacity: root.paused ? 0.6 : 1
            font.family: root.textFontFamily
            font.pixelSize: root.userConfig.bodyFontSize
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
        }
    }

    // --- Right: pause / resume + stop ---
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        // Pause / resume
        Rectangle {
            id: pauseButton

            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            radius: 12
            color: pauseHover.hovered ? "#33ffffff" : "#22ffffff"
            scale: pauseArea.pressed ? 0.9 : 1

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

            // Two bars (pause) or a triangle (resume).
            Row {
                anchors.centerIn: parent
                spacing: 3
                visible: !root.paused

                Rectangle { width: 3; height: 10; radius: 1.5; color: "#ffffff" }
                Rectangle { width: 3; height: 10; radius: 1.5; color: "#ffffff" }
            }

            Canvas {
                anchors.centerIn: parent
                width: 12
                height: 12
                visible: root.paused
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = "#ffffff";
                    ctx.beginPath();
                    ctx.moveTo(2, 1);
                    ctx.lineTo(11, 6);
                    ctx.lineTo(2, 11);
                    ctx.closePath();
                    ctx.fill();
                }
            }

            HoverHandler { id: pauseHover }

            MouseArea {
                id: pauseArea

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pauseToggleRequested()
            }
        }

        // Stop
        Rectangle {
            id: stopButton

            anchors.verticalCenter: parent.verticalCenter
            width: 24
            height: 24
            radius: 12
            color: stopHover.hovered ? "#ff5f55" : "#ff453a"
            scale: stopArea.pressed ? 0.9 : 1

            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }

            Rectangle {
                anchors.centerIn: parent
                width: 9
                height: 9
                radius: 2
                color: "#ffffff"
            }

            HoverHandler { id: stopHover }

            MouseArea {
                id: stopArea

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stopRequested()
            }
        }
    }
}

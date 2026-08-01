pragma ComponentBehavior: Bound

import QtQuick

// The animated audio-wave / equaliser that sits on the right of the compact
// now-playing pill. Bars dance while playing and freeze in place the instant
// playback pauses — the pill never resizes for a pause.
Item {
    id: root

    property bool playing: true
    property bool active: true
    property color barColor: "#ffffff"
    readonly property int barCount: 4

    implicitWidth: barCount * 3 + (barCount - 1) * 2
    implicitHeight: 14
    width: implicitWidth
    height: implicitHeight
    opacity: root.playing ? 0.95 : 0.42

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
    }

    Row {
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index

                readonly property real restingHeight: 3 + (index % 2 === 0 ? 1 : 0)

                anchors.verticalCenter: parent.verticalCenter
                width: 3
                radius: 1.5
                height: restingHeight
                color: root.barColor

                // Freeze, don't reset: pausing leaves the bars exactly where
                // they were, which is what makes the pause read as "held".
                SequentialAnimation on height {
                    running: root.playing && root.active
                    loops: Animation.Infinite

                    PauseAnimation { duration: index * 90 }
                    NumberAnimation { to: 12; duration: 300; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 4; duration: 300; easing.type: Easing.InOutQuad }
                }

                Behavior on height {
                    enabled: !(root.playing && root.active)

                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Split / dual live activity — two things are genuinely live at once (e.g. music
// plus a running timer), so the pill carries two independent compact bubbles
// side by side instead of hiding one of them.
//
// Each bubble is separately tappable and expands only its own activity. If a
// third activity is live it collapses to the "minimal" dot on the trailing
// edge; tapping that dot cycles which activities occupy the two bubbles.
Item {
    id: root

    readonly property var userConfig: UserConfig

    // Activity kinds, most recently started first: "media" | "timer" | "recording".
    property var activities: []

    property string currentArtUrl: ""
    property bool mediaPlaying: true

    property real timerProgress: 0
    property int timerRemainingSeconds: 0
    property bool timerRunning: true

    readonly property string timerText: {
        const total = Math.max(0, Math.round(root.timerRemainingSeconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = total % 60;
        const pad = function(value) { return value < 10 ? "0" + value : String(value); };
        if (hours > 0)
            return hours + ":" + pad(minutes) + ":" + pad(seconds);
        return minutes + ":" + pad(seconds);
    }

    property string recordingElapsedText: ""
    property bool recordingPaused: false

    property string textFontFamily: ""
    property bool showCondition: false
    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    signal activityActivated(string kind)
    signal cycleRequested()

    readonly property string primaryKind: activities.length > 0 ? String(activities[0]) : ""
    readonly property string secondaryKind: activities.length > 1 ? String(activities[1]) : ""
    readonly property bool hasOverflow: activities.length > 2

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    component ActivityBubble: Item {
        id: bubble

        property string kind: ""

        implicitWidth: chip.width
        implicitHeight: chip.height
        visible: kind !== ""

        Rectangle {
            id: chip

            width: bubbleRow.implicitWidth + 18
            height: 24
            radius: height / 2
            color: bubbleArea.pressed ? "#33ffffff" : "#1fffffff"
            anchors.verticalCenter: parent.verticalCenter
            scale: bubbleArea.pressed ? 0.95 : 1

            Behavior on color {
                ColorAnimation { duration: 130 }
            }

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            Row {
                id: bubbleRow

                anchors.centerIn: parent
                spacing: 6

                // Media: album art thumbnail + wave.
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: bubble.kind === "media"
                    width: visible ? 16 : 0
                    height: 16
                    radius: 5
                    color: "#1f1f1f"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.currentArtUrl
                        visible: root.currentArtUrl !== "" && status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 32
                        sourceSize.height: 32
                    }
                }

                IslandAudioWave {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: bubble.kind === "media"
                    playing: root.mediaPlaying
                    active: root.showCondition && bubble.kind === "media"
                }

                // Timer: mini ring + countdown.
                Canvas {
                    id: miniRing

                    anchors.verticalCenter: parent.verticalCenter
                    visible: bubble.kind === "timer"
                    width: visible ? 14 : 0
                    height: 14

                    Connections {
                        target: root

                        function onTimerProgressChanged() { miniRing.requestPaint(); }
                        function onTimerRunningChanged() { miniRing.requestPaint(); }
                        function onShowConditionChanged() { miniRing.requestPaint(); }
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const center = width / 2;
                        const radius = center - 1.4;

                        ctx.lineWidth = 2.2;
                        ctx.strokeStyle = "#3a3a3a";
                        ctx.beginPath();
                        ctx.arc(center, center, radius, 0, Math.PI * 2);
                        ctx.stroke();

                        const sweep = Math.max(0, Math.min(1, root.timerProgress)) * Math.PI * 2;
                        if (sweep <= 0)
                            return;

                        ctx.strokeStyle = root.timerRunning ? "#ff9f0a" : "#8e8e93";
                        ctx.lineCap = "round";
                        ctx.beginPath();
                        ctx.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + sweep);
                        ctx.stroke();
                    }
                }

                // Recording: pulsing red dot.
                Rectangle {
                    id: recordingDot

                    anchors.verticalCenter: parent.verticalCenter
                    visible: bubble.kind === "recording"
                    width: visible ? 8 : 0
                    height: 8
                    radius: 4
                    color: "#ff453a"

                    SequentialAnimation {
                        running: recordingDot.visible && !root.recordingPaused
                        loops: Animation.Infinite

                        NumberAnimation {
                            target: recordingDot
                            property: "opacity"
                            to: 0.35
                            duration: 700
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            target: recordingDot
                            property: "opacity"
                            to: 1
                            duration: 700
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    text: bubble.kind === "timer"
                        ? root.timerText
                        : (bubble.kind === "recording" ? root.recordingElapsedText : "")
                    color: "#ffffff"
                    font.family: root.textFontFamily
                    font.pixelSize: Math.max(10, root.userConfig.bodyFontSize - 2)
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: bubbleArea

                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.activityActivated(bubble.kind)
            }
        }
    }

    ActivityBubble {
        kind: root.primaryKind
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    ActivityBubble {
        kind: root.secondaryKind
        anchors.right: overflowDot.visible ? overflowDot.left : parent.right
        anchors.rightMargin: overflowDot.visible ? 8 : 10
        anchors.verticalCenter: parent.verticalCenter
    }

    // "Minimal" representation of everything that did not fit: one small dot.
    // Tapping it cycles which activities are shown in the two bubbles.
    Rectangle {
        id: overflowDot

        visible: root.hasOverflow
        width: 8
        height: 8
        radius: 4
        color: overflowArea.pressed ? "#ffffff" : "#8e8e93"
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color {
            ColorAnimation { duration: 130 }
        }

        MouseArea {
            id: overflowArea

            anchors.fill: parent
            anchors.margins: -8
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.PointingHandCursor
            onClicked: root.cycleRequested()
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Expanded *timer* activity — deliberately NOT the media card layout.
//
// iOS gives the timer its own arrangement: a progress ring / icon pinned left,
// then one very large monospaced countdown that owns most of the width, with
// the activity label above it and small pause / cancel controls below. There is
// no scrubber and no transport row here.
Item {
    id: root

    readonly property var userConfig: UserConfig

    property real progress: 0
    property int remainingSeconds: 0
    property int totalSeconds: 0
    property bool running: true
    property string label: "Timer"
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: false

    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    signal toggleRequested()
    signal cancelRequested()
    signal controlPressed()

    readonly property string remainingText: {
        const total = Math.max(0, Math.round(root.remainingSeconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = total % 60;
        const pad = function(value) { return value < 10 ? "0" + value : String(value); };
        if (hours > 0)
            return hours + ":" + pad(minutes) + ":" + pad(seconds);
        return pad(minutes) + ":" + pad(seconds);
    }

    anchors.fill: parent
    anchors.leftMargin: 30
    anchors.rightMargin: 30
    anchors.topMargin: 16
    anchors.bottomMargin: 16
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    // --- Left: progress ring with a timer glyph in the middle --------------
    Item {
        id: ringBlock

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 58
        height: 58

        Canvas {
            id: ring

            anchors.fill: parent

            Connections {
                target: root

                function onProgressChanged() { ring.requestPaint(); }
                function onRunningChanged() { ring.requestPaint(); }
                function onShowConditionChanged() { ring.requestPaint(); }
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const center = width / 2;
                const radius = center - 3;

                ctx.lineWidth = 4;
                ctx.strokeStyle = "#2c2c2e";
                ctx.beginPath();
                ctx.arc(center, center, radius, 0, Math.PI * 2);
                ctx.stroke();

                const sweep = Math.max(0, Math.min(1, root.progress)) * Math.PI * 2;
                if (sweep <= 0)
                    return;

                ctx.strokeStyle = root.running ? "#ff9f0a" : "#8e8e93";
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + sweep);
                ctx.stroke();
            }
        }

        // Simple hourglass/timer glyph drawn from primitives so it never
        // depends on an icon font being present.
        Item {
            anchors.centerIn: parent
            width: 18
            height: 18
            opacity: root.running ? 1 : 0.6

            Rectangle {
                anchors.centerIn: parent
                width: 13
                height: 13
                radius: 6.5
                color: "transparent"
                border.width: 1.6
                border.color: "#ff9f0a"
            }

            Rectangle {
                x: parent.width / 2 - 0.8
                y: parent.height / 2 - 5
                width: 1.6
                height: 5.5
                radius: 0.8
                color: "#ff9f0a"
            }
        }
    }

    // --- Right: label, huge countdown, controls ----------------------------
    Item {
        anchors.left: ringBlock.right
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: labelText.height + countdown.height + controlsRow.height + 12

        Text {
            id: labelText

            anchors.left: parent.left
            anchors.top: parent.top
            text: root.label
            color: "#8e8e93"
            font.family: root.textFontFamily
            font.pixelSize: Math.max(10, root.userConfig.bodyFontSize - 4)
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2
            font.capitalization: Font.AllUppercase
            elide: Text.ElideRight
            width: parent.width
        }

        // The star of this layout: countdown at hero scale.
        Text {
            id: countdown

            anchors.left: parent.left
            anchors.top: labelText.bottom
            anchors.topMargin: 2
            text: root.remainingText
            color: root.running ? "#ffffff" : "#c7c7cc"
            font.family: root.textFontFamily
            font.pixelSize: Math.max(30, root.userConfig.bodyFontSize + 20)
            font.weight: Font.Bold
            font.letterSpacing: -0.5

            Behavior on color {
                ColorAnimation { duration: 160 }
            }
        }

        Row {
            id: controlsRow

            anchors.left: parent.left
            anchors.top: countdown.bottom
            anchors.topMargin: 8
            spacing: 8

            IslandActionButton {
                compact: true
                label: root.running ? "Pause" : "Resume"
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onActivated: {
                    root.controlPressed();
                    root.toggleRequested();
                }
            }

            IslandActionButton {
                compact: true
                destructive: true
                label: "Cancel"
                textFontFamily: root.textFontFamily
                iconFontFamily: root.iconFontFamily
                onActivated: {
                    root.controlPressed();
                    root.cancelRequested();
                }
            }
        }
    }
}

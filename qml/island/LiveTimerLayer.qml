pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Compact timer live activity — dual compact layout: progress ring pinned left,
// live countdown pinned right. Like the media layer this is a resting state: it
// is held for as long as the timer runs and never auto-expands mid-countdown.
// Only the *completion* of the timer is an urgent, momentary event.
Item {
    id: root

    readonly property var userConfig: UserConfig

    property real progress: 0
    property int remainingSeconds: 0
    property bool running: true
    property string textFontFamily: ""
    property bool showCondition: true
    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    readonly property string remainingText: {
        const total = Math.max(0, Math.round(root.remainingSeconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor((total % 3600) / 60);
        const seconds = total % 60;
        const pad = function(value) { return value < 10 ? "0" + value : String(value); };
        if (hours > 0)
            return hours + ":" + pad(minutes) + ":" + pad(seconds);
        return minutes + ":" + pad(seconds);
    }

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    IslandDualCompact {
        horizontalPadding: 12

        leftItem: Component {
            Canvas {
                id: ring

                width: 18
                height: 18
                opacity: root.running ? 1 : 0.55

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
                    const radius = center - 1.5;

                    ctx.lineWidth = 2.4;
                    ctx.strokeStyle = "#3a3a3a";
                    ctx.beginPath();
                    ctx.arc(center, center, radius, 0, Math.PI * 2);
                    ctx.stroke();

                    const sweep = Math.max(0, Math.min(1, root.progress)) * Math.PI * 2;
                    if (sweep <= 0)
                        return;

                    ctx.strokeStyle = "#ff9f0a";
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + sweep);
                    ctx.stroke();
                }
            }
        }

        rightItem: Component {
            Text {
                text: root.remainingText
                color: "#ffffff"
                opacity: root.running ? 1 : 0.6
                font.family: root.textFontFamily
                font.pixelSize: root.userConfig.bodyFontSize
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
            }
        }
    }
}

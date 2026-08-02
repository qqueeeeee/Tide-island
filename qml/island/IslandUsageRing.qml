pragma ComponentBehavior: Bound

import QtQuick

// A tiny circular progress ring used as a satellite of the idle orb.
//
// Painted with Canvas to match the timer bubble ring elsewhere in the island.
// The value eases rather than snapping, so a load spike reads as a sweep.
Item {
    id: root

    property real size: 11
    // 0..1
    property real value: 0
    property bool known: false
    property color ringColor: "#4cc2ff"
    property bool motionActive: true
    // Staggers the bob of multiple satellites so they do not move in lockstep.
    property int orbitPhase: 0

    property real displayedValue: 0
    property real bob: 0

    width: root.size
    height: root.size

    onValueChanged: valueEase.restart()
    Component.onCompleted: valueEase.restart()

    NumberAnimation {
        id: valueEase

        target: root
        property: "displayedValue"
        to: root.value
        duration: 520
        easing.type: Easing.OutCubic
    }

    onDisplayedValueChanged: ringCanvas.requestPaint()
    onKnownChanged: ringCanvas.requestPaint()

    transform: Translate { y: root.bob }

    SequentialAnimation on bob {
        running: root.motionActive
        loops: Animation.Infinite
        PauseAnimation { duration: root.orbitPhase * 700 }
        NumberAnimation { to: -0.8; duration: 2500; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.8; duration: 2700; easing.type: Easing.InOutSine }
    }

    Canvas {
        id: ringCanvas

        anchors.fill: parent

        Component.onCompleted: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            const centerX = width / 2;
            const centerY = height / 2;
            const lineWidth = Math.max(1.4, width * 0.17);
            const radius = Math.min(width, height) / 2 - lineWidth / 2;
            const progress = root.known ? Math.max(0, Math.min(1, root.displayedValue)) : 0;
            const startAngle = -Math.PI / 2;
            const endAngle = startAngle - Math.PI * 2 * progress;

            ctx.clearRect(0, 0, width, height);
            ctx.lineCap = "round";
            ctx.lineWidth = lineWidth;

            ctx.beginPath();
            ctx.strokeStyle = "rgba(255, 255, 255, 0.16)";
            ctx.arc(centerX, centerY, radius, 0, Math.PI * 2);
            ctx.stroke();

            if (progress > 0.001) {
                ctx.beginPath();
                ctx.strokeStyle = root.ringColor;
                ctx.arc(centerX, centerY, radius, startAngle, endAngle, true);
                ctx.stroke();
            }
        }
    }
}

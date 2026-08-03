pragma ComponentBehavior: Bound

import QtQuick

// The `tide showClock` peek: a momentary pill with the time on the left and the
// date on the right, styled like the reference compact layouts.
Item {
    id: root

    property string timeText: Qt.formatTime(new Date(), "h:mm ap")
    property string dateText: Qt.formatDate(new Date(), "ddd, MMM d")
    property string textFontFamily: ""
    property string heroFontFamily: ""
    property real lifeProgress: 1
    property bool showCondition: true
    property real revealOffset: 0

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandTokens { id: tokens }

    // The peek only lives a couple of seconds, but tick anyway so it never
    // shows a stale minute.
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            const now = new Date();
            root.timeText = Qt.formatTime(now, "h:mm ap");
            root.dateText = Qt.formatDate(now, "ddd, MMM d");
        }
    }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Text {
        id: timeLabel

        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.timeText
        color: tokens.fg
        font.family: root.heroFontFamily
        font.pixelSize: 15
        font.weight: Font.DemiBold
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: root.dateText
        color: tokens.fg55
        font.family: root.textFontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
    }

    // Thin countdown hairline, same language as the notification card.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.bottomMargin: 4
        height: 1.5
        radius: 1
        color: tokens.fg14

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: parent.radius
            width: parent.width * Math.max(0, Math.min(1, root.lifeProgress))
            color: tokens.fg35
        }
    }
}

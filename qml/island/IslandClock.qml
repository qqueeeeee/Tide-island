import QtQuick

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property string currentTime: "00:00"
    property string currentDateLabel: "Mon, Jan 01"
    property string clockFormat: "12"
    property bool showSeconds: false

    readonly property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    function padTwoDigits(value) {
        return value < 10 ? "0" + value : String(value);
    }

    function formatDateLabel(now) {
        return dayNames[now.getDay()]
            + ", "
            + monthNames[now.getMonth()]
            + " "
            + padTwoDigits(now.getDate());
    }

    function updateClock() {
        const now = new Date();
        const pattern = root.clockFormat === "24"
            ? (root.showSeconds ? "HH:mm:ss" : "HH:mm")
            : (root.showSeconds ? "hh:mm:ss ap" : "hh:mm ap");
        root.currentTime = Qt.formatTime(now, pattern);
        root.currentDateLabel = root.formatDateLabel(now);
        clockTimer.interval = root.showSeconds
            ? Math.max(120, 1000 - now.getMilliseconds())
            : (60 - now.getSeconds()) * 1000 - now.getMilliseconds();
    }

    onClockFormatChanged: updateClock()
    onShowSecondsChanged: updateClock()

    Timer {
        id: clockTimer

        running: true
        repeat: true
        triggeredOnStart: true
        interval: 1000

        onTriggered: root.updateClock()
    }
}

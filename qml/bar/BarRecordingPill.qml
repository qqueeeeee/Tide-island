import QtQuick
import IslandBackend
import "." as Bar

// Persistent recording pill for the status bar. Stays visible while a recording
// runs, even when the island itself is showing something else.
Row {
    id: root

    property string elapsedText: "00:00"
    property string textFontFamily: ""
    property int pixelSize: 12

    spacing: 5

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 8
        height: 8
        radius: 4
        color: "#ff453a"

        SequentialAnimation on opacity {
            running: root.visible
            loops: Animation.Infinite

            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutQuad }
        }
    }

    Bar.BarLabel {
        anchors.verticalCenter: parent.verticalCenter
        text: root.elapsedText
        fontFamily: root.textFontFamily
        pixelSize: root.pixelSize
        weight: Font.Bold
        textColor: "#ff9f99"
    }
}

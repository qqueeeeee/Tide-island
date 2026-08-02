import QtQuick
import TideIsland 1.0

Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    property bool destructive: false

    signal clicked()

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 30
    radius: 9
    color: root.primary
        ? (mouse.pressed ? Qt.darker(AppTheme.accent, 1.2) : AppTheme.accent)
        : (mouse.pressed ? AppTheme.rowHover : (AppTheme.dark ? "#22222a" : "#eeeef3"))
    border.width: root.primary ? 0 : 1
    border.color: AppTheme.cardBorder

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.primary ? "#ffffff" : (root.destructive ? AppTheme.danger : AppTheme.text)
        font.family: AppTheme.fontFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

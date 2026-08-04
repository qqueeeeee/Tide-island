import QtQuick
import TideIsland 1.0

Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    property bool destructive: false

    signal clicked()

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 32
    radius: AppTheme.radiusChip - 2
    color: root.primary
        ? (mouse.pressed ? Qt.darker(AppTheme.accentActive, 1.15) : AppTheme.accentActive)
        : (mouse.pressed ? AppTheme.chipPressed : (mouse.containsMouse ? AppTheme.chipHover : AppTheme.chip))
    border.width: root.primary ? 0 : 1
    border.color: AppTheme.glassBorder

    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.primary ? "#00230f" : (root.destructive ? AppTheme.danger : AppTheme.text)
        font.family: AppTheme.fontFamily
        font.pixelSize: AppTheme.fontSizeCaption
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

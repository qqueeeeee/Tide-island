import QtQuick
import TideIsland 1.0

Item {
    id: root

    property string label: ""
    property string hint: ""
    property string configKey: ""
    property bool checked: root.configKey === "" ? false : ConfigStore.flag(root.configKey)

    signal toggled(bool value)

    width: parent ? parent.width : 0
    implicitHeight: Math.max(44, textColumn.implicitHeight + 18)
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        radius: AppTheme.radiusControl
        color: hover.hovered ? AppTheme.rowHover : "transparent"

        Behavior on color { ColorAnimation { duration: AppTheme.animation } }
    }

    HoverHandler { id: hover }

    Column {
        id: textColumn

        anchors.left: parent.left
        anchors.right: track.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            text: root.label
            color: AppTheme.text
            font.family: AppTheme.fontFamily
            font.pixelSize: 13
        }

        Text {
            width: parent.width
            visible: root.hint !== ""
            text: root.hint
            color: AppTheme.textFaint
            wrapMode: Text.WordWrap
            font.family: AppTheme.fontFamily
            font.pixelSize: 12
        }
    }

    Rectangle {
        id: track

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 44
        height: 26
        radius: 13
        color: root.checked ? "#30d158" : AppTheme.trackOff

        Behavior on color { ColorAnimation { duration: AppTheme.animation } }

        Rectangle {
            width: 22
            height: 22
            radius: 11
            y: 2
            x: root.checked ? track.width - width - 2 : 2
            color: "#ffffff"

            Behavior on x {
                NumberAnimation { duration: 190; easing.type: Easing.OutBack; easing.overshoot: 0.9 }
            }
        }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                const next = !root.checked;
                if (root.configKey !== "")
                    ConfigStore.set(root.configKey, next);
                else
                    root.checked = next;
                root.toggled(next);
            }
        }
    }
}

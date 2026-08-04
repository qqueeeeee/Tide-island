import QtQuick
import TideIsland 1.0

// Island-style pill toggle (same silhouette as the control-centre circle
// buttons, flattened into a switch). API unchanged: label/hint/configKey,
// `toggled(bool)` signal.
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
        radius: AppTheme.radiusChip
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
            font.pixelSize: AppTheme.fontSizeBody
        }

        Text {
            width: parent.width
            visible: root.hint !== ""
            text: root.hint
            color: AppTheme.textFaint
            wrapMode: Text.WordWrap
            font.family: AppTheme.fontFamily
            font.pixelSize: AppTheme.fontSizeCaption
        }
    }

    Rectangle {
        id: track

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 46
        height: 27
        radius: height / 2
        color: root.checked ? AppTheme.accentActive : AppTheme.trackOff
        border.width: 1
        border.color: root.checked ? "transparent" : AppTheme.glassBorder

        Behavior on color { ColorAnimation { duration: AppTheme.animation } }

        Rectangle {
            width: 23
            height: 23
            radius: 11.5
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

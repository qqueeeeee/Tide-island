import QtQuick
import QtQuick.Controls.Basic
import TideIsland 1.0

Item {
    id: root

    property string label: ""
    property string hint: ""
    property string configKey: ""
    property string placeholder: ""
    property int fieldWidth: 240

    width: parent ? parent.width : 0
    implicitHeight: Math.max(48, column.implicitHeight + 18)
    height: implicitHeight

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: field.left
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

    TextField {
        id: field

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.fieldWidth
        height: 32
        color: AppTheme.text
        placeholderText: root.placeholder
        placeholderTextColor: AppTheme.textFaint
        font.family: AppTheme.fontFamily
        font.pixelSize: 12
        leftPadding: 10
        rightPadding: 10
        selectByMouse: true
        text: root.configKey === "" ? "" : ConfigStore.text(root.configKey)

        background: Rectangle {
            radius: 8
            color: AppTheme.dark ? "#101014" : "#f5f5f8"
            border.width: 1
            border.color: field.activeFocus ? AppTheme.accent : AppTheme.cardBorder
        }

        onEditingFinished: {
            if (root.configKey !== "")
                ConfigStore.set(root.configKey, field.text);
        }
    }
}

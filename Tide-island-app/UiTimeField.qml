import QtQuick
import QtQuick.Controls.Basic
import TideIsland 1.0

// Label + HH:MM entry, glass-chip styled to match UiTextField. Bound to a
// ConfigStore string key ("HH:MM", 24h clock).
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string configKey: ""
    property int fieldWidth: 96

    readonly property string currentValue: root.configKey === "" ? "" : ConfigStore.text(root.configKey)

    function pad2(n) { return (n < 10 ? "0" : "") + n; }

    function commit(value) {
        const match = /^\s*([0-9]{1,2})\s*:\s*([0-9]{1,2})\s*$/.exec(value);
        if (!match) {
            field.text = root.currentValue;
            return;
        }
        const hours = Math.max(0, Math.min(23, parseInt(match[1], 10)));
        const minutes = Math.max(0, Math.min(59, parseInt(match[2], 10)));
        const normalized = root.pad2(hours) + ":" + root.pad2(minutes);
        field.text = normalized;
        if (root.configKey !== "")
            ConfigStore.set(root.configKey, normalized);
    }

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

    TextField {
        id: field

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.fieldWidth
        height: 32
        color: AppTheme.text
        horizontalAlignment: TextInput.AlignHCenter
        placeholderText: "HH:MM"
        placeholderTextColor: AppTheme.textFaint
        font.family: AppTheme.fontFamily
        font.pixelSize: AppTheme.fontSizeCaption
        selectByMouse: true
        validator: RegularExpressionValidator { regularExpression: /^[0-9]{0,2}:?[0-9]{0,2}$/ }
        text: root.currentValue

        background: Rectangle {
            radius: AppTheme.radiusChip - 2
            color: AppTheme.chip
            border.width: 1
            border.color: field.activeFocus ? AppTheme.accentActive : AppTheme.glassBorder
        }

        onEditingFinished: root.commit(field.text)
    }
}

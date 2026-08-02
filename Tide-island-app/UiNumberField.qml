import QtQuick
import QtQuick.Controls.Basic
import TideIsland 1.0

// Label + exact numeric entry. Same visual language as UiTextField, but it
// clamps to [minimum, maximum] and always writes a number to the config.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string configKey: ""
    property int minimum: 0
    property int maximum: 1000
    property string suffix: "px"
    property int fieldWidth: 120

    readonly property int currentValue: root.configKey === "" ? 0 : Math.round(ConfigStore.number(root.configKey))

    function commit(value) {
        const parsed = Number(value);
        if (!isFinite(parsed)) {
            field.text = String(root.currentValue);
            return;
        }
        const clamped = Math.max(root.minimum, Math.min(root.maximum, Math.round(parsed)));
        field.text = String(clamped);
        if (root.configKey !== "")
            ConfigStore.set(root.configKey, clamped);
    }

    width: parent ? parent.width : 0
    implicitHeight: Math.max(48, column.implicitHeight + 18)
    height: implicitHeight

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: fieldRow.left
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

    Row {
        id: fieldRow

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        UiButton {
            text: "−"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.commit(root.currentValue - 1)
        }

        TextField {
            id: field

            width: root.fieldWidth
            height: 32
            color: AppTheme.text
            horizontalAlignment: TextInput.AlignHCenter
            font.family: AppTheme.fontFamily
            font.pixelSize: 12
            selectByMouse: true
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: root.minimum; top: root.maximum }
            text: String(root.currentValue)

            background: Rectangle {
                radius: 8
                color: AppTheme.dark ? "#101014" : "#f5f5f8"
                border.width: 1
                border.color: field.activeFocus ? AppTheme.accent : AppTheme.cardBorder
            }

            onEditingFinished: root.commit(field.text)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.suffix !== ""
            text: root.suffix
            color: AppTheme.textFaint
            font.family: AppTheme.fontFamily
            font.pixelSize: 12
        }

        UiButton {
            text: "+"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: root.commit(root.currentValue + 1)
        }
    }
}

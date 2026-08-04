import QtQuick
import QtQuick.Controls.Basic
import TideIsland 1.0

// Add/remove string chips, bound to a ConfigStore array-of-strings key.
// API: label, hint, configKey (array<string>), placeholder.
// Uses ConfigStore.value()/set() — there is no dedicated array accessor in
// ConfigStore, so this widget reads the raw JS array and writes it back
// whole on every change (same pattern the store already uses for objects).
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string configKey: ""
    property string placeholder: "Add…"

    readonly property var tags: {
        const raw = root.configKey === "" ? [] : ConfigStore.value(root.configKey);
        return Array.isArray(raw) ? raw : [];
    }

    function commitTags(list) {
        if (root.configKey !== "")
            ConfigStore.set(root.configKey, list);
    }

    function addTag(value) {
        const trimmed = String(value).trim();
        if (trimmed === "")
            return;
        const list = root.tags.slice();
        if (list.indexOf(trimmed) === -1)
            list.push(trimmed);
        root.commitTags(list);
    }

    function removeTag(index) {
        const list = root.tags.slice();
        list.splice(index, 1);
        root.commitTags(list);
    }

    width: parent ? parent.width : 0
    implicitHeight: column.implicitHeight + 14
    height: implicitHeight

    Column {
        id: column

        y: 7
        width: parent.width
        spacing: 8

        Text {
            visible: root.label !== ""
            text: root.label
            color: AppTheme.text
            font.family: AppTheme.fontFamily
            font.pixelSize: AppTheme.fontSizeBody
        }

        Flow {
            width: parent.width
            spacing: 6
            visible: root.tags.length > 0

            Repeater {
                model: root.tags

                delegate: Rectangle {
                    id: chip

                    required property string modelData
                    required property int index

                    height: 28
                    radius: height / 2
                    color: AppTheme.chip
                    border.width: 1
                    border.color: AppTheme.glassBorder
                    width: chipRow.implicitWidth + 20

                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: chip.modelData
                            color: AppTheme.text
                            font.family: AppTheme.fontFamily
                            font.pixelSize: AppTheme.fontSizeCaption
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "✕"
                            color: AppTheme.textFaint
                            font.pixelSize: 10
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.removeTag(chip.index)
                            }
                        }
                    }
                }
            }
        }

        Row {
            width: parent.width
            spacing: 8

            TextField {
                id: input

                width: parent.width - addButton.width - parent.spacing
                height: 32
                color: AppTheme.text
                placeholderText: root.placeholder
                placeholderTextColor: AppTheme.textFaint
                font.family: AppTheme.fontFamily
                font.pixelSize: AppTheme.fontSizeCaption
                leftPadding: 10
                rightPadding: 10
                selectByMouse: true

                background: Rectangle {
                    radius: AppTheme.radiusChip - 2
                    color: AppTheme.chip
                    border.width: 1
                    border.color: input.activeFocus ? AppTheme.accentActive : AppTheme.glassBorder
                }

                onAccepted: {
                    root.addTag(input.text);
                    input.text = "";
                }
            }

            UiButton {
                id: addButton
                text: "Add"
                anchors.verticalCenter: parent.verticalCenter
                onClicked: {
                    root.addTag(input.text);
                    input.text = "";
                }
            }
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
}

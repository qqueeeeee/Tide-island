import QtQuick
import TideIsland 1.0

// Reorderable list with up/down controls and an enable checkbox per row.
// `options` is the catalogue: [{ label: "Wi-Fi", value: "wifi" }, ...].
// The config key stores a plain array of the *enabled* values, in order —
// exactly what the shell consumes (e.g. controlCenterModules,
// liveActivityPriority). Disabled entries are simply absent from that array
// and are listed after the enabled ones.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string configKey: ""
    property var options: []

    readonly property var order: {
        const raw = root.configKey === "" ? [] : ConfigStore.list(root.configKey);
        return Array.isArray(raw) ? raw.map((entry) => String(entry)) : [];
    }

    // Rows: enabled values first (config order), then the remaining options.
    readonly property var rows: {
        const catalogue = Array.isArray(root.options) ? root.options : [];
        const labelFor = (value) => {
            for (let index = 0; index < catalogue.length; index++) {
                if (String(catalogue[index].value) === value)
                    return String(catalogue[index].label);
            }
            return value;
        };
        const list = [];
        for (let i = 0; i < root.order.length; i++)
            list.push({ value: root.order[i], label: labelFor(root.order[i]), enabled: true });
        for (let j = 0; j < catalogue.length; j++) {
            const value = String(catalogue[j].value);
            if (root.order.indexOf(value) === -1)
                list.push({ value: value, label: String(catalogue[j].label), enabled: false });
        }
        return list;
    }

    function commit(values) {
        if (root.configKey !== "")
            ConfigStore.set(root.configKey, values);
    }

    function setEnabled(value, enabled) {
        const values = root.order.slice();
        const at = values.indexOf(value);
        if (enabled && at === -1)
            values.push(value);
        else if (!enabled && at !== -1)
            values.splice(at, 1);
        root.commit(values);
    }

    function move(value, delta) {
        const values = root.order.slice();
        const at = values.indexOf(value);
        const target = at + delta;
        if (at === -1 || target < 0 || target >= values.length)
            return;
        values.splice(at, 1);
        values.splice(target, 0, value);
        root.commit(values);
    }

    width: parent ? parent.width : 0
    implicitHeight: column.implicitHeight + 14
    height: implicitHeight

    Column {
        id: column

        y: 7
        width: parent.width
        spacing: 8

        Column {
            width: parent.width
            spacing: 3
            visible: root.label !== ""

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

        Column {
            width: parent.width
            spacing: 6

            Repeater {
                model: root.rows

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool first: row.index === 0
                    readonly property bool last: row.index === root.order.length - 1

                    width: column.width
                    height: 40
                    radius: AppTheme.radiusChip
                    color: AppTheme.chip
                    border.width: 1
                    border.color: AppTheme.glassBorder
                    opacity: row.modelData.enabled ? 1 : 0.55

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: row.modelData.enabled ? AppTheme.accentActive : "transparent"
                            border.width: 1
                            border.color: row.modelData.enabled ? "transparent" : AppTheme.glassBorder

                            Text {
                                anchors.centerIn: parent
                                visible: row.modelData.enabled
                                text: "✓"
                                color: "#00230f"
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -6
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setEnabled(row.modelData.value, !row.modelData.enabled)
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: row.modelData.label
                            color: AppTheme.text
                            font.family: AppTheme.fontFamily
                            font.pixelSize: AppTheme.fontSizeBody
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        visible: row.modelData.enabled

                        Text {
                            text: "▲"
                            font.pixelSize: 11
                            color: AppTheme.text
                            opacity: row.first ? 0.35 : 1

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                enabled: !row.first
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.move(row.modelData.value, -1)
                            }
                        }

                        Text {
                            text: "▼"
                            font.pixelSize: 11
                            color: AppTheme.text
                            opacity: row.last ? 0.35 : 1

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -8
                                enabled: !row.last
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.move(row.modelData.value, 1)
                            }
                        }
                    }
                }
            }
        }
    }
}

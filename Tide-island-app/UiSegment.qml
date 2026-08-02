import QtQuick
import TideIsland 1.0

// Segmented control for small enumerations (12/24h, and friends).
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string configKey: ""
    // [{ label: "12-hour", value: "12" }, ...]
    property var options: []
    property var currentValue: root.configKey === "" ? "" : ConfigStore.value(root.configKey)

    signal selected(var value)

    width: parent ? parent.width : 0
    implicitHeight: Math.max(46, column.implicitHeight + 18)
    height: implicitHeight

    Column {
        id: column

        anchors.left: parent.left
        anchors.right: group.left
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
        id: group

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 30
        width: segments.implicitWidth + 6
        radius: 9
        color: AppTheme.trackOff

        Row {
            id: segments

            anchors.centerIn: parent
            spacing: 2

            Repeater {
                model: root.options

                delegate: Rectangle {
                    id: segment

                    required property var modelData

                    readonly property bool active: String(root.currentValue) === String(segment.modelData.value)

                    height: 24
                    width: Math.max(60, segmentLabel.implicitWidth + 22)
                    radius: 7
                    color: segment.active ? AppTheme.cardBg : "transparent"

                    Behavior on color { ColorAnimation { duration: AppTheme.animation } }

                    Text {
                        id: segmentLabel

                        anchors.centerIn: parent
                        text: segment.modelData.label
                        color: segment.active ? AppTheme.text : AppTheme.textDim
                        font.family: AppTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: segment.active ? Font.DemiBold : Font.Normal
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.configKey !== "")
                                ConfigStore.set(root.configKey, segment.modelData.value);
                            root.selected(segment.modelData.value);
                        }
                    }
                }
            }
        }
    }
}

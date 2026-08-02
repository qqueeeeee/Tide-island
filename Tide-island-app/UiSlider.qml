import QtQuick
import QtQuick.Controls.Basic
import TideIsland 1.0

// Label + live value + Apple-style track.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string configKey: ""
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property string suffix: " px"

    readonly property int currentValue: root.configKey === "" ? slider.value : ConfigStore.number(root.configKey)

    width: parent ? parent.width : 0
    implicitHeight: column.implicitHeight + 14
    height: implicitHeight

    Column {
        id: column

        y: 7
        width: parent.width
        spacing: 4

        Item {
            width: parent.width
            height: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
                color: AppTheme.text
                font.family: AppTheme.fontFamily
                font.pixelSize: 13
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentValue + root.suffix
                color: AppTheme.textDim
                font.family: AppTheme.fontFamily
                font.pixelSize: 12
            }
        }

        Slider {
            id: slider

            width: parent.width
            height: 22
            from: root.from
            to: root.to
            stepSize: root.stepSize
            snapMode: Slider.SnapAlways
            value: root.currentValue

            onMoved: {
                if (root.configKey !== "")
                    ConfigStore.set(root.configKey, Math.round(value));
            }

            background: Rectangle {
                x: 0
                y: (slider.height - height) / 2
                width: slider.width
                height: 4
                radius: 2
                color: AppTheme.trackOff

                Rectangle {
                    width: slider.visualPosition * parent.width
                    height: parent.height
                    radius: 2
                    color: AppTheme.accent
                }
            }

            handle: Rectangle {
                x: slider.visualPosition * (slider.width - width)
                y: (slider.height - height) / 2
                width: 16
                height: 16
                radius: 8
                color: "#ffffff"
                border.width: 1
                border.color: AppTheme.dark ? "#00000055" : "#0000001a"
                scale: slider.pressed ? 1.12 : 1

                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
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
            font.pixelSize: 12
        }
    }
}

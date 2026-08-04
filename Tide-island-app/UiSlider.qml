import QtQuick
import TideIsland 1.0

// Label + live value + island capsule slider (tall pill, glyph, spring fill).
// API kept identical to the previous UiSlider: label/hint/configKey/from/to/
// stepSize/suffix. Optional `glyph` adds a leading icon like the island's
// control-centre sliders.
Item {
    id: root

    property string label: ""
    property string hint: ""
    property string configKey: ""
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property string suffix: " px"
    property string glyph: ""

    readonly property int currentValue: root.configKey === "" ? internalValue : ConfigStore.number(root.configKey)
    property int internalValue: root.from
    readonly property real ratio: (root.to === root.from) ? 0 : (root.currentValue - root.from) / (root.to - root.from)

    signal moved(int value)

    function valueFromRatio(r) {
        const span = root.to - root.from;
        const raw = root.from + r * span;
        const stepped = Math.round(raw / root.stepSize) * root.stepSize;
        return Math.max(root.from, Math.min(root.to, stepped));
    }

    function apply(next) {
        if (root.configKey !== "")
            ConfigStore.set(root.configKey, next);
        else
            root.internalValue = next;
        root.moved(next);
    }

    width: parent ? parent.width : 0
    implicitHeight: column.implicitHeight + 14
    height: implicitHeight

    Column {
        id: column

        y: 7
        width: parent.width
        spacing: 6

        Item {
            width: parent.width
            height: 18
            visible: root.label !== ""

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
                color: AppTheme.text
                font.family: AppTheme.fontFamily
                font.pixelSize: AppTheme.fontSizeBody
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentValue + root.suffix
                color: AppTheme.textDim
                font.family: AppTheme.fontFamily
                font.pixelSize: AppTheme.fontSizeCaption
            }
        }

        Item {
            id: capsule

            width: parent.width
            height: 30

            Rectangle {
                id: track

                anchors.fill: parent
                radius: height / 2
                color: AppTheme.chip
                border.width: 1
                border.color: AppTheme.glassBorder
                clip: true

                Rectangle {
                    id: fill

                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: height / 2
                    width: Math.max(0, Math.min(1, root.ratio)) * track.width
                    color: AppTheme.fillOnDark

                    Behavior on width {
                        SpringAnimation { spring: 4.2; damping: 0.62; mass: 1.0; epsilon: 0.25 }
                    }
                }

                Text {
                    visible: root.glyph !== ""
                    anchors.left: parent.left
                    anchors.leftMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyph
                    font.family: AppTheme.iconFontFamily
                    font.pixelSize: 14
                    color: root.ratio > 0.14 ? AppTheme.onFill : AppTheme.textDim
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    text: Math.round(Math.max(0, Math.min(1, root.ratio)) * 100) + "%"
                    font.family: AppTheme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: root.ratio > 0.86 ? AppTheme.onFill : AppTheme.textDim
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function ratioAt(mx) {
                    return Math.max(0, Math.min(1, mx / Math.max(1, width)));
                }

                onPressed: (mouse) => root.apply(root.valueFromRatio(ratioAt(mouse.x)))
                onPositionChanged: (mouse) => { if (pressed) root.apply(root.valueFromRatio(ratioAt(mouse.x))); }
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

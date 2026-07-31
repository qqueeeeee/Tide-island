import QtQuick

// iOS-style battery pill, adapted from the island's SwipeCustomInfoLayer battery
// shape so the bar and the island stay visually identical.
Item {
    id: root

    property int level: 0
    property bool charging: false
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property int batteryWidth: 32
    property int batteryHeight: 15
    property int tipWidth: 2
    property int tipHeight: 5
    property int outerRadius: 5
    property int labelFontSize: 11
    property int labelFontSizeCharging: 10
    property int boltSize: 9

    readonly property string chargingIconGlyph: "\uf0e7"
    readonly property real clampedLevel: Math.max(0, Math.min(100, level))
    readonly property bool roundedEnd: clampedLevel >= 85
    readonly property color bodyColor: (!charging && clampedLevel <= 20) ? "#ff3b30" : "white"
    readonly property color emptyColor: Qt.rgba(1, 1, 1, 0.56)

    implicitWidth: batteryWidth
    implicitHeight: batteryHeight
    width: implicitWidth
    height: implicitHeight

    Rectangle {
        id: batteryBody

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - root.tipWidth - 1
        height: parent.height
        radius: root.outerRadius
        color: root.emptyColor
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: 0
            topLeftRadius: root.outerRadius
            bottomLeftRadius: root.outerRadius
            topRightRadius: root.roundedEnd ? root.outerRadius : 0
            bottomRightRadius: root.roundedEnd ? root.outerRadius : 0
            width: Math.max(root.outerRadius * 2, parent.width * (root.clampedLevel / 100.0))
            color: root.bodyColor

            Behavior on width {
                NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 300 }
            }
        }

        Row {
            visible: root.charging
            anchors.centerIn: parent
            spacing: 2
            z: 2

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.clampedLevel + ""
                color: "black"
                font.pixelSize: root.labelFontSizeCharging
                font.family: root.textFontFamily
                font.weight: Font.DemiBold
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.chargingIconGlyph
                color: "#242424"
                font.pixelSize: root.boltSize
                font.family: root.iconFontFamily
            }
        }

        Text {
            visible: !root.charging
            anchors.centerIn: parent
            text: root.clampedLevel + ""
            color: root.clampedLevel <= 20 ? "white" : "black"
            font.pixelSize: root.labelFontSize
            font.family: root.textFontFamily
            font.weight: root.clampedLevel <= 20 ? Font.Bold : Font.DemiBold
            z: 2
        }
    }

    Rectangle {
        width: root.tipWidth
        height: root.tipHeight
        radius: Math.round(root.tipWidth / 2)
        color: root.clampedLevel >= 100 ? root.bodyColor : root.emptyColor
        anchors.left: batteryBody.right
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter

        Behavior on color {
            ColorAnimation { duration: 300 }
        }
    }
}

import QtQuick

// Shared text element for the status bar. Draws a soft dark shadow behind the
// glyph/label so the fully transparent bar stays legible on light wallpapers.
Item {
    id: root

    property string text: ""
    property string fontFamily: ""
    property int pixelSize: 13
    property int weight: Font.DemiBold
    property color textColor: "white"
    property real letterSpacing: -0.15
    property real maximumWidth: -1
    property bool shadowEnabled: true

    readonly property real naturalWidth: label.implicitWidth
    implicitWidth: maximumWidth > 0 ? Math.min(maximumWidth, label.implicitWidth) : label.implicitWidth
    implicitHeight: label.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Text {
        id: shadow

        visible: root.shadowEnabled
        x: 0
        y: 1
        width: root.width
        height: root.height
        text: root.text
        color: "#73000000"
        font.family: root.fontFamily
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        font.letterSpacing: root.letterSpacing
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        verticalAlignment: Text.AlignVCenter
    }

    Text {
        id: label

        anchors.fill: parent
        text: root.text
        color: root.textColor
        font.family: root.fontFamily
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        font.letterSpacing: root.letterSpacing
        elide: Text.ElideRight
        wrapMode: Text.NoWrap
        verticalAlignment: Text.AlignVCenter
    }
}

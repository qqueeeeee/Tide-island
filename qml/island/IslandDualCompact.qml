pragma ComponentBehavior: Bound

import QtQuick

// Two-sided ("dual") compact layout used by the real Dynamic Island: a small
// item pinned to the left edge, a separate small item pinned to the right edge,
// and a gap in the middle. Callers pass two components so every dual-compact
// state (media, timer, ...) shares identical padding and alignment rules.
//
// States that only have one thing to say keep using centred content instead.
Item {
    id: root

    property Component leftItem: null
    property Component rightItem: null
    property real horizontalPadding: 12

    anchors.fill: parent

    Loader {
        anchors.left: parent.left
        anchors.leftMargin: root.horizontalPadding
        anchors.verticalCenter: parent.verticalCenter
        active: root.leftItem !== null
        sourceComponent: root.leftItem
    }

    Loader {
        anchors.right: parent.right
        anchors.rightMargin: root.horizontalPadding
        anchors.verticalCenter: parent.verticalCenter
        active: root.rightItem !== null
        sourceComponent: root.rightItem
    }
}

pragma ComponentBehavior: Bound

import QtQuick

// Reference `IdleContent`: nothing but a 6px dot at 25% white, pinned right.
Item {
    id: root

    property bool showCondition: true
    property real revealOffset: 0

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandTokens { id: tokens }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 6
        radius: 3
        color: "#40ffffff"
    }
}

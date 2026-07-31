pragma ComponentBehavior: Bound

import QtQuick

// iOS-like workspace dots. Reuses the island's Hyprland dispatch path for
// clicks via the focusRequested signal.
Item {
    id: root

    property var workspaceIds: []
    property int currentWorkspace: 1
    property int minimumCount: 4
    property real dotSize: 7
    property real activeDotWidth: 18
    property real spacing: 6
    property bool interactive: true

    signal focusRequested(int workspaceId)

    readonly property var resolvedIds: {
        const ids = [];
        const source = workspaceIds || [];
        for (let index = 0; index < source.length; index++) {
            const id = Number(source[index]);
            if (isFinite(id) && id > 0 && ids.indexOf(id) === -1)
                ids.push(id);
        }

        if (ids.indexOf(currentWorkspace) === -1 && currentWorkspace > 0)
            ids.push(currentWorkspace);

        for (let fill = 1; ids.length < minimumCount; fill++) {
            if (ids.indexOf(fill) === -1)
                ids.push(fill);
        }

        ids.sort(function(left, right) { return left - right; });
        return ids;
    }

    implicitWidth: dotRow.implicitWidth
    implicitHeight: Math.max(dotSize, 18)
    width: implicitWidth
    height: implicitHeight

    Row {
        id: dotRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing

        Repeater {
            model: root.resolvedIds

            delegate: Item {
                id: dotItem

                required property var modelData

                readonly property int workspaceId: Number(dotItem.modelData)
                readonly property bool isActive: dotItem.workspaceId === root.currentWorkspace

                width: dotItem.isActive ? root.activeDotWidth : root.dotSize
                height: root.dotSize
                anchors.verticalCenter: parent.verticalCenter

                Behavior on width {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    id: dotShadow

                    anchors.fill: parent
                    anchors.topMargin: 1
                    anchors.bottomMargin: -1
                    radius: height / 2
                    color: "#59000000"
                }

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: dotItem.isActive ? "white" : Qt.rgba(1, 1, 1, hoverHandler.hovered ? 0.7 : 0.45)

                    Behavior on color {
                        ColorAnimation { duration: 180 }
                    }
                }

                HoverHandler {
                    id: hoverHandler
                    enabled: root.interactive
                }

                TapHandler {
                    enabled: root.interactive
                    onTapped: root.focusRequested(dotItem.workspaceId)
                }
            }
        }
    }
}

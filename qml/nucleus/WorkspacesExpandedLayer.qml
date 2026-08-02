pragma ComponentBehavior: Bound

import QtQuick

// Reference `WorkspacesExpanded`: 452 x 336 — header with the focused workspace's
// window titles, a 3x3 grid of 16:10 mini-desktop tiles, keyboard-hint footer.
FocusScope {
    id: root

    property WorkspaceSource source: null
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    property real revealOffset: 0

    property int focusIndex: 1

    signal closeRequested()

    anchors.fill: parent
    opacity: 0
    focus: root.showCondition
    transform: Translate { y: root.revealOffset }

    IslandTokens { id: tokens }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    readonly property var focused: {
        const list = root.source ? root.source.workspaces : [];
        for (let index = 0; index < list.length; ++index) {
            if (list[index].id === root.focusIndex)
                return list[index];
        }
        return null;
    }

    onShowConditionChanged: {
        if (root.showCondition) {
            if (root.source)
                root.source.rebuild();
            root.focusIndex = root.source ? root.source.active : 1;
        }
    }

    function move(step) {
        root.focusIndex = ((root.focusIndex - 1 + step + 9) % 9) + 1;
    }

    function select(id) {
        if (root.source)
            root.source.switchTo(id);
        root.closeRequested();
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
            root.move(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backtab) {
            root.move(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            root.move(3);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            root.move(-3);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.select(root.focusIndex);
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.closeRequested();
            event.accepted = true;
        } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
            root.select(event.key - Qt.Key_0);
            event.accepted = true;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 12
        anchors.bottomMargin: 11

        Item {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 16

            Text {
                id: headerTitle

                anchors.left: parent.left
                anchors.baseline: parent.bottom
                text: "Workspaces"
                color: tokens.fg
                font.family: root.textFontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                anchors.left: headerTitle.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.baseline: headerTitle.baseline
                text: {
                    const workspace = root.focused;
                    if (!workspace || workspace.windows.length === 0)
                        return "no windows";
                    return workspace.windows.map((win) => win.title).join(" · ");
                }
                color: tokens.fg45
                elide: Text.ElideRight
                font.family: root.textFontFamily
                font.pixelSize: 11
            }
        }

        Grid {
            id: grid

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: 9
            columns: 3
            columnSpacing: 7
            rowSpacing: 7

            Repeater {
                model: root.source ? root.source.workspaces : []

                delegate: Rectangle {
                    id: tile

                    required property var modelData

                    readonly property bool isActive: root.source
                        && root.source.active === tile.modelData.id
                    readonly property bool isFocused: root.focusIndex === tile.modelData.id

                    width: (grid.width - 2 * grid.columnSpacing) / 3
                    height: width * 10 / 16
                    radius: 10
                    clip: true
                    border.width: 1
                    border.color: tile.isFocused ? tokens.fg70 : "#1affffff"
                    color: tile.isFocused
                        ? tokens.fg14
                        : (tileArea.containsMouse ? "#1affffff" : tokens.fg06)

                    Behavior on color { ColorAnimation { duration: 130 } }
                    Behavior on border.color { ColorAnimation { duration: 130 } }

                    // Mini desktop — abstract window rects at the real tiling geometry.
                    Repeater {
                        model: tile.modelData.windows

                        delegate: Rectangle {
                            required property var modelData

                            x: modelData.x * tile.width
                            y: modelData.y * tile.height
                            width: Math.max(6, modelData.w * tile.width)
                            height: Math.max(5, modelData.h * tile.height)
                            radius: 3
                            gradient: Gradient {
                                orientation: Gradient.Vertical
                                GradientStop { position: 0.0; color: modelData.tint[0] }
                                GradientStop { position: 1.0; color: modelData.tint[1] }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                height: 3
                                color: "#40ffffff"
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: tile.modelData.windows.length === 0
                        text: "empty"
                        color: tokens.fg25
                        font.family: root.textFontFamily
                        font.pixelSize: 10
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 4
                        width: 15
                        height: 15
                        radius: 8
                        color: "#8c000000"

                        Text {
                            anchors.centerIn: parent
                            text: String(tile.modelData.id)
                            color: tokens.fg
                            font.family: root.textFontFamily
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 4
                        visible: tile.isActive
                        width: 6
                        height: 6
                        radius: 3
                        color: tokens.accept
                    }

                    MouseArea {
                        id: tileArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.focusIndex = tile.modelData.id
                        onClicked: root.select(tile.modelData.id)
                    }
                }
            }
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 12

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Super + Tab"
                color: tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "1–9 jump · ↵ switch"
                color: tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10
            }
        }
    }
}

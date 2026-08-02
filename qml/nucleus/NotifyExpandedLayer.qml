pragma ComponentBehavior: Bound

import QtQuick

// Reference `NotifyExpanded`: 420 x 296 — header row (title, Focus toggle, Clear),
// grouped stacked cards, footer with the count and a close affordance.
FocusScope {
    id: root

    property NotifySource source: null
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    property real revealOffset: 0

    property string openGroup: ""
    property var groups: []

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

    function rebuild() {
        root.groups = root.source ? root.source.groups() : [];
    }

    onShowConditionChanged: {
        if (root.showCondition) {
            root.openGroup = "";
            root.rebuild();
        }
    }

    Connections {
        target: root.source

        function onItemsChanged() {
            root.rebuild();
        }
    }

    Keys.onEscapePressed: root.closeRequested()

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        anchors.bottomMargin: 12

        Item {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 22

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "Notification Center"
                color: tokens.fg
                font.family: root.textFontFamily
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: focusRow.implicitWidth + 18
                    height: 22
                    radius: 11
                    color: root.source && root.source.dnd ? tokens.fg : tokens.chip

                    Row {
                        id: focusRow

                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.source && root.source.dnd ? tokens.glyphBellOff : tokens.glyphBell
                            color: root.source && root.source.dnd ? "#000000" : tokens.fg70
                            font.family: root.iconFontFamily
                            font.pixelSize: 11
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Focus"
                            color: root.source && root.source.dnd ? "#000000" : tokens.fg70
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.source)
                                root.source.dnd = !root.source.dnd;
                        }
                    }
                }

                Rectangle {
                    width: clearRow.implicitWidth + 18
                    height: 22
                    radius: 11
                    color: clearArea.containsMouse ? tokens.fg18 : tokens.chip

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Row {
                        id: clearRow

                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tokens.glyphCheck
                            color: tokens.fg70
                            font.family: root.iconFontFamily
                            font.pixelSize: 11
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Clear"
                            color: tokens.fg70
                            font.family: root.textFontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                        }
                    }

                    MouseArea {
                        id: clearArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.source)
                                root.source.clearAll();
                        }
                    }
                }
            }
        }

        ListView {
            id: list

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: 9
            anchors.bottom: footer.top
            anchors.bottomMargin: 9
            clip: true
            spacing: 6
            boundsBehavior: Flickable.StopAtBounds
            model: root.groups

            delegate: Item {
                id: groupItem

                required property var modelData

                readonly property string app: groupItem.modelData ? String(groupItem.modelData.app) : ""
                readonly property var entries: groupItem.modelData ? groupItem.modelData.items : []
                readonly property bool expanded: root.openGroup === groupItem.app
                    || groupItem.entries.length === 1
                readonly property bool stacked: !groupItem.expanded && groupItem.entries.length > 1

                width: list.width
                height: cards.height + (groupItem.stacked ? 6 : 0)

                // iOS stacked-card hint peeking out under a collapsed group.
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 16
                    y: cards.height - 4
                    height: 10
                    radius: 6
                    visible: groupItem.stacked
                    color: tokens.fg06
                }

                Column {
                    id: cards

                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: groupItem.expanded ? groupItem.entries.length : 1

                        delegate: Rectangle {
                            id: card

                            required property int index

                            readonly property var entry: groupItem.entries[card.index]

                            width: cards.width
                            height: Math.max(46, cardBody.implicitHeight + 18)
                            radius: 13
                            color: tokens.fg09

                            Rectangle {
                                id: cardTile

                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.top: parent.top
                                anchors.topMargin: 9
                                width: 26
                                height: 26
                                radius: 7
                                color: tokens.chip

                                Text {
                                    anchors.centerIn: parent
                                    text: card.entry ? String(card.entry.glyph) : tokens.glyphBell
                                    color: card.entry ? card.entry.tint : tokens.accent
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 13
                                }
                            }

                            Column {
                                id: cardBody

                                anchors.left: cardTile.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: cardArea.containsMouse ? 30 : 10
                                anchors.top: parent.top
                                anchors.topMargin: 8
                                spacing: 2

                                Item {
                                    width: parent.width
                                    height: titleText.implicitHeight

                                    Rectangle {
                                        id: urgentChip

                                        anchors.right: ageText.left
                                        anchors.rightMargin: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: card.entry ? card.entry.urgent === true : false
                                        width: urgentLabel.implicitWidth + 10
                                        height: 13
                                        radius: 6
                                        color: tokens.dangerSoft

                                        Text {
                                            id: urgentLabel

                                            anchors.centerIn: parent
                                            text: "urgent"
                                            color: tokens.danger
                                            font.family: root.textFontFamily
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    Text {
                                        id: ageText

                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: card.entry ? String(card.entry.age) : ""
                                        color: tokens.fg40
                                        font.family: root.textFontFamily
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        id: titleText

                                        anchors.left: parent.left
                                        anchors.right: urgentChip.visible ? urgentChip.left : ageText.left
                                        anchors.rightMargin: 6
                                        text: card.entry ? String(card.entry.title) : ""
                                        color: tokens.fg
                                        elide: Text.ElideRight
                                        font.family: root.textFontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: card.entry ? String(card.entry.body) : ""
                                    color: tokens.fg60
                                    elide: Text.ElideRight
                                    font.family: root.textFontFamily
                                    font.pixelSize: 11
                                }

                                Text {
                                    width: parent.width
                                    visible: groupItem.stacked
                                    text: (groupItem.entries.length - 1) + " more from " + groupItem.app
                                    color: tokens.fg40
                                    font.family: root.textFontFamily
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: cardArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openGroup = groupItem.expanded && groupItem.entries.length > 1
                                    ? ""
                                    : groupItem.app
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 6
                                anchors.top: parent.top
                                anchors.topMargin: 9
                                width: 22
                                height: 22
                                radius: 11
                                visible: cardArea.containsMouse || closeArea.containsMouse
                                color: closeArea.containsMouse ? tokens.fg09 : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: tokens.glyphClose
                                    color: closeArea.containsMouse ? tokens.fg : tokens.fg45
                                    font.family: root.iconFontFamily
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: closeArea

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!root.source)
                                            return;
                                        if (groupItem.expanded && card.entry)
                                            root.source.dismiss(card.entry.id);
                                        else
                                            root.source.dismissApp(groupItem.app);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Text {
            anchors.centerIn: list
            visible: root.groups.length === 0
            text: "No Notifications"
            color: tokens.fg40
            font.family: root.textFontFamily
            font.pixelSize: 12
        }

        Item {
            id: footer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 12

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: (root.source ? root.source.count : 0) + " notifications"
                color: tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "close"
                color: closeHint.containsMouse ? tokens.fg60 : tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10

                MouseArea {
                    id: closeHint

                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeRequested()
                }
            }
        }
    }
}

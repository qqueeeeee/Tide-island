pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// Reference `ClipboardExpanded`: 460 x 268 — search pill, scrollable history list
// (34px thumbnail, value + meta, hover delete) and a keyboard-hint footer.
FocusScope {
    id: root

    property ClipboardSource source: null
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    property real revealOffset: 0

    property string query: ""
    property var results: []
    property int selectedIndex: 0

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
        const all = root.source && root.source.entries ? root.source.entries : [];
        const needle = root.query.trim().toLowerCase();
        root.results = needle === ""
            ? all.slice()
            : all.filter((entry) => String(entry.value).toLowerCase().indexOf(needle) !== -1);
        root.selectedIndex = 0;
    }

    function move(offset) {
        const count = root.results.length;
        if (count <= 0)
            return;
        root.selectedIndex = (root.selectedIndex + offset + count) % count;
    }

    function paste(entry) {
        if (!entry || !root.source)
            return;
        root.source.paste(entry);
        root.closeRequested();
    }

    function remove(entry) {
        if (!entry || !root.source)
            return;
        root.source.remove(entry);
        root.rebuild();
    }

    onShowConditionChanged: {
        if (root.showCondition) {
            root.query = "";
            search.clear();
            if (root.source)
                root.source.refresh();
            root.rebuild();
            focusTimer.restart();
        }
    }

    Timer {
        id: focusTimer

        interval: 40
        onTriggered: search.grabFocus()
    }

    Connections {
        target: root.source

        function onEntriesChanged() {
            root.rebuild();
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 13
        anchors.bottomMargin: 12

        IslandSearchField {
            id: search

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            placeholder: "Search clipboard…"
            textFontFamily: root.textFontFamily
            iconFontFamily: root.iconFontFamily
            onTextEdited: (value) => {
                root.query = value;
                root.rebuild();
            }
            onMoveDown: root.move(1)
            onMoveUp: root.move(-1)
            onAccepted: root.paste(root.results[root.selectedIndex])
            onDeleteSelected: root.remove(root.results[root.selectedIndex])
            onCancelled: root.closeRequested()
        }

        ListView {
            id: list

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: search.bottom
            anchors.topMargin: 9
            anchors.bottom: footer.top
            anchors.bottomMargin: 9
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: root.selectedIndex
            model: root.results




            delegate: Rectangle {
                id: row

                required property int index
                required property var modelData

                readonly property bool selected: root.selectedIndex === row.index
                readonly property bool isImage: row.modelData && row.modelData.kind === "image"

                width: list.width
                height: 46
                radius: 11
                color: row.selected
                    ? tokens.fg14
                    : (rowArea.containsMouse ? tokens.fg09 : "transparent")

                Behavior on color { ColorAnimation { duration: 120 } }

                Item {
                    id: thumb

                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 34

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: tokens.chip
                        clip: true

                        Image {
                            id: preview

                            anchors.fill: parent
                            visible: row.isImage && preview.status === Image.Ready
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            sourceSize.width: 68
                            sourceSize.height: 68
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !preview.visible
                            text: {
                                if (!row.modelData)
                                    return tokens.glyphText;
                                if (row.modelData.kind === "link")
                                    return tokens.glyphLink;
                                if (row.modelData.kind === "image")
                                    return tokens.glyphImage;
                                return tokens.glyphText;
                            }
                            color: row.modelData && row.modelData.kind === "link"
                                ? tokens.nav
                                : tokens.fg70
                            font.family: root.iconFontFamily
                            font.pixelSize: 14
                        }
                    }

                    // Decode image entries into a cache file so the thumbnail can
                    // be shown exactly like the reference preview tile.
                    Process {
                        id: decode

                        running: row.isImage
                        command: ["sh", "-c",
                            "mkdir -p /tmp/tide-island/clip && f=/tmp/tide-island/clip/"
                            + (row.modelData ? row.modelData.id : "0")
                            + ".img && [ -s \"$f\" ] || cliphist decode "
                            + (row.modelData ? row.modelData.id : "0")
                            + " > \"$f\"; printf %s \"$f\""]

                        stdout: StdioCollector {
                            onStreamFinished: {
                                const path = String(this.text).trim();
                                if (path !== "")
                                    preview.source = "file://" + path;
                            }
                        }
                    }
                }

                Column {
                    anchors.left: thumb.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: rowArea.containsMouse ? 34 : 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: row.modelData ? String(row.modelData.value) : ""
                        color: tokens.fg
                        elide: Text.ElideRight
                        font.family: root.textFontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Text {
                        width: parent.width
                        text: row.modelData
                            ? String(row.modelData.meta ? row.modelData.meta : row.modelData.kind)
                            : ""
                        color: tokens.fg45
                        elide: Text.ElideRight
                        font.family: root.textFontFamily
                        font.pixelSize: 10
                    }
                }

                MouseArea {
                    id: rowArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.selectedIndex = row.index
                    onClicked: root.paste(row.modelData)
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: 12
                    visible: rowArea.containsMouse || trashArea.containsMouse
                    color: trashArea.containsMouse ? tokens.fg09 : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: tokens.glyphTrash
                        color: trashArea.containsMouse ? tokens.danger : tokens.fg50
                        font.family: root.iconFontFamily
                        font.pixelSize: 12
                    }

                    MouseArea {
                        id: trashArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.remove(row.modelData)
                    }
                }
            }
        }

        Text {
            anchors.centerIn: list
            visible: root.results.length === 0
            text: root.source && !root.source.available
                ? "cliphist not installed"
                : "Nothing copied yet"
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
                text: "Super + V"
                color: tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "↵ paste · ⌘⌫ delete"
                color: tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import "../common/ApplicationSearch.js" as ApplicationSearch

// Reference `LauncherExpanded`: 460 x 246, search pill on top, a two-column grid
// of six results (28px icon tile, name + exec) and a keyboard-hint footer.
FocusScope {
    id: root

    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    property real revealOffset: 0

    property string query: ""
    property var results: []
    property int selectedIndex: 0

    readonly property int visibleCount: Math.min(6, root.results.length)

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

    function execText(entry) {
        if (!entry)
            return "";
        const command = entry.command ? entry.command : [];
        if (command.length > 0)
            return String(command.join(" "));
        return String(entry.id ? entry.id : entry.name);
    }

    function rebuild() {
        const hasQuery = ApplicationSearch.normalize(root.query) !== "";
        const available = DesktopEntries.applications.values;
        const ranked = [];

        for (let index = 0; index < available.length; ++index) {
            const entry = available[index];
            if (!entry || entry.noDisplay || String(entry.name).trim() === "")
                continue;
            const score = hasQuery ? ApplicationSearch.applicationScore(entry, root.query) : 0;
            if (score < 0)
                continue;
            ranked.push({ entry: entry, score: score });
        }

        ranked.sort((left, right) => {
            if (hasQuery && left.score !== right.score)
                return right.score - left.score;
            return String(left.entry.name).localeCompare(String(right.entry.name));
        });

        root.results = ranked.map((candidate) => candidate.entry);
        root.selectedIndex = 0;
    }

    function move(offset) {
        const count = root.visibleCount;
        if (count <= 0)
            return;
        root.selectedIndex = (root.selectedIndex + offset + count) % count;
    }

    function launch(entry) {
        if (!entry) {
            root.closeRequested();
            return;
        }

        const desktopCommand = [];
        const command = entry.command ? entry.command : [];
        for (let index = 0; index < command.length; ++index)
            desktopCommand.push(String(command[index]));

        if (desktopCommand.length === 0) {
            entry.execute();
        } else {
            // Launch outside the shell's own service scope so restarting
            // tide-island never kills the app that was started from here.
            const scoped = [
                "systemd-run", "--user", "--scope", "--quiet", "--collect",
                "--slice=app.slice", "--expand-environment=no"
            ];
            const workingDirectory = String(entry.workingDirectory ? entry.workingDirectory : "");
            if (workingDirectory !== "")
                scoped.push("--working-directory=" + workingDirectory);
            scoped.push("--");
            for (let index = 0; index < desktopCommand.length; ++index)
                scoped.push(desktopCommand[index]);
            Quickshell.execDetached(scoped);
        }

        root.closeRequested();
    }

    function launchSelected() {
        if (root.selectedIndex < 0 || root.selectedIndex >= root.visibleCount)
            return;
        root.launch(root.results[root.selectedIndex]);
    }

    onShowConditionChanged: {
        if (root.showCondition) {
            root.query = "";
            search.clear();
            root.rebuild();
            focusTimer.restart();
        }
    }

    Component.onCompleted: root.rebuild()

    Timer {
        id: focusTimer

        interval: 40
        onTriggered: search.grabFocus()
    }

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.rebuild();
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 13
        anchors.bottomMargin: 14

        IslandSearchField {
            id: search

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            placeholder: "Search apps…"
            textFontFamily: root.textFontFamily
            iconFontFamily: root.iconFontFamily
            onTextEdited: (value) => {
                root.query = value;
                root.rebuild();
            }
            onMoveDown: root.move(1)
            onMoveUp: root.move(-1)
            onAccepted: root.launchSelected()
            onCancelled: root.closeRequested()
        }

        Text {
            anchors.centerIn: parent
            visible: root.results.length === 0
            text: "No matches"
            color: tokens.fg40
            font.family: root.textFontFamily
            font.pixelSize: 12
        }

        Grid {
            id: grid

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: search.bottom
            anchors.topMargin: 10
            columns: 2
            columnSpacing: 4
            rowSpacing: 4

            Repeater {
                model: root.visibleCount

                delegate: Rectangle {
                    id: cell

                    required property int index

                    readonly property var entry: root.results[cell.index]
                    readonly property bool selected: root.selectedIndex === cell.index

                    width: (grid.width - grid.columnSpacing) / 2
                    height: 42
                    radius: 10
                    color: cell.selected
                        ? tokens.fg14
                        : (cellArea.containsMouse ? tokens.fg09 : "transparent")

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Rectangle {
                        id: iconTile

                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 8
                        color: tokens.chip

                        IconImage {
                            anchors.centerIn: parent
                            width: 17
                            height: 17
                            source: cell.entry
                                ? Quickshell.iconPath(cell.entry.icon, "application-x-executable")
                                : ""
                        }
                    }

                    Column {
                        anchors.left: iconTile.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            width: parent.width
                            text: cell.entry ? String(cell.entry.name) : ""
                            color: tokens.fg
                            elide: Text.ElideRight
                            font.family: root.textFontFamily
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }

                        Text {
                            width: parent.width
                            text: root.execText(cell.entry)
                            color: tokens.fg45
                            elide: Text.ElideRight
                            font.family: root.textFontFamily
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: cellArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = cell.index
                        onClicked: root.launch(cell.entry)
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
                text: "Super + Space"
                color: tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "↑↓ navigate · ↵ launch"
                color: tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10
            }
        }
    }
}

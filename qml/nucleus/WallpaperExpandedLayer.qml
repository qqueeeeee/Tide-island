pragma ComponentBehavior: Bound

import QtQuick

// Wallpaper picker, expanded: 460 x 300 — header with the library folder, a
// scrollable 3-wide grid of 16:10 previews (click or ↵ applies), footer hints.
FocusScope {
    id: root

    property WallpaperSource source: null
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    property real revealOffset: 0

    property int selectedIndex: 0

    readonly property var entries: root.source ? root.source.entries : []

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

    function activate() {
        if (root.source)
            root.source.refresh();
        root.selectedIndex = 0;
        root.forceActiveFocus();
    }

    onShowConditionChanged: {
        if (root.showCondition)
            root.activate();
    }

    Component.onCompleted: root.activate()

    function move(step) {
        const count = root.entries.length;
        if (count <= 0)
            return;
        root.selectedIndex = (root.selectedIndex + step + count) % count;
        grid.positionViewAtIndex(root.selectedIndex, GridView.Contain);
    }

    function apply(path) {
        if (root.source)
            root.source.apply(path);
        root.closeRequested();
    }

    function applySelected() {
        const list = root.entries;
        if (root.selectedIndex < 0 || root.selectedIndex >= list.length)
            return;
        root.apply(list[root.selectedIndex].path);
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
            root.applySelected();
            event.accepted = true;
        } else if (event.key === Qt.Key_Escape) {
            root.closeRequested();
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
                text: "Wallpaper"
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
                text: root.source ? root.source.libraryPath : ""
                color: tokens.fg45
                elide: Text.ElideMiddle
                font.family: root.textFontFamily
                font.pixelSize: 11
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.entries.length === 0
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "No images in " + (root.source ? root.source.libraryPath : "the wallpaper folder")
                + "\nSet a folder in Settings → Wallpaper."
            color: tokens.fg35
            font.family: root.textFontFamily
            font.pixelSize: 11
        }

        GridView {
            id: grid

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.topMargin: 9
            anchors.bottom: footer.top
            anchors.bottomMargin: 8
            visible: root.entries.length > 0
            clip: true
            cellWidth: Math.floor(width / 3)
            cellHeight: Math.round(cellWidth * 10 / 16)
            model: root.entries
            currentIndex: root.selectedIndex

            delegate: Item {
                id: cell

                required property int index
                required property var modelData

                readonly property bool isSelected: root.selectedIndex === cell.index
                readonly property bool isApplied: root.source
                    && root.source.appliedPath === cell.modelData.path

                width: grid.cellWidth
                height: grid.cellHeight

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: 10
                    clip: true
                    border.width: 1
                    border.color: cell.isSelected ? tokens.fg70 : "#1affffff"
                    color: cell.isSelected ? tokens.fg14 : tokens.fg06

                    Behavior on border.color { ColorAnimation { duration: 130 } }
                    Behavior on color { ColorAnimation { duration: 130 } }

                    Image {
                        anchors.fill: parent
                        anchors.margins: 1
                        source: "file://" + encodeURI(cell.modelData.path)
                        asynchronous: true
                        cache: true
                        smooth: true
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 320
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 17
                        color: "#a6000000"

                        Text {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideMiddle
                            text: cell.modelData.name
                            color: tokens.fg85
                            font.family: root.textFontFamily
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 4
                        visible: cell.isApplied
                        width: 14
                        height: 14
                        radius: 7
                        color: tokens.accept

                        Text {
                            anchors.centerIn: parent
                            text: tokens.glyphCheck
                            color: "#000000"
                            font.family: root.iconFontFamily
                            font.pixelSize: 8
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selectedIndex = cell.index
                        onClicked: root.apply(cell.modelData.path)
                    }
                }
            }
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
                text: "Super + W"
                color: tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "↑↓←→ browse · ↵ apply · esc close"
                color: tokens.fg35
                font.family: root.textFontFamily
                font.pixelSize: 10
            }
        }
    }
}

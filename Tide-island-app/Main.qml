import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import TideIsland 1.0

ApplicationWindow {
    id: window

    width: 1060
    height: 740
    minimumWidth: 900
    minimumHeight: 580
    visible: true
    title: "Tide Island Settings"
    color: AppTheme.windowBg

    FontLoader {
        source: "qrc:/RES/InterVariable.ttf"
    }

    readonly property var pages: [
        { title: "Island", subtitle: "Placement, scale, shape", glyph: "◗", source: "PageIsland.qml" },
        { title: "Motion", subtitle: "Spring, reveal, timing", glyph: "◈", source: "PageMotion.qml" },
        { title: "Activities", subtitle: "Live activity sources", glyph: "◎", source: "PageActivities.qml" },
        { title: "Notifications", subtitle: "Banners and cards", glyph: "◍", source: "PageNotifications.qml" },
        { title: "Status bar", subtitle: "Spacing and modules", glyph: "▤", source: "PageStatusBar.qml" },
        { title: "Appearance", subtitle: "Fonts and sizes", glyph: "✿", source: "PageAppearance.qml" },
        { title: "Capture", subtitle: "Screenshots and recording", glyph: "◉", source: "PageCapture.qml" },
        { title: "Wallpaper", subtitle: "Picker, pywal, transitions", glyph: "▣", source: "PageWallpaper.qml" },
        { title: "Shortcuts", subtitle: "Keybinds and IPC", glyph: "⌘", source: "PageShortcuts.qml" },
        { title: "General", subtitle: "Behaviour and defaults", glyph: "▧", source: "PageGeneral.qml" },
        { title: "About", subtitle: "Config file and resets", glyph: "ⓘ", source: "PageAbout.qml" }
    ]

    property int currentPage: 0
    property string searchQuery: ""

    readonly property var filteredIndices: {
        const q = window.searchQuery.trim().toLowerCase();
        if (q === "")
            return window.pages.map((_, index) => index);
        const result = [];
        for (let index = 0; index < window.pages.length; index++) {
            const page = window.pages[index];
            if (page.title.toLowerCase().indexOf(q) !== -1 || page.subtitle.toLowerCase().indexOf(q) !== -1)
                result.push(index);
        }
        return result;
    }

    // `tide-island-config-app --page wallpaper` (used by the island's wallpaper
    // shortcut) lands directly on that page.
    Component.onCompleted: {
        const requested = String(typeof startupPage === "undefined" ? "" : startupPage).trim().toLowerCase();
        if (requested === "")
            return;
        for (let index = 0; index < window.pages.length; index++) {
            if (window.pages[index].title.toLowerCase() === requested
                || window.pages[index].source.toLowerCase() === "page" + requested + ".qml") {
                window.currentPage = index;
                return;
            }
        }
    }

    // ---- Sidebar -----------------------------------------------------------
    Rectangle {
        id: sidebar

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 236
        color: AppTheme.sidebarBg

        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: AppTheme.separator
        }

        Item {
            id: brandRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            height: 62

            Rectangle {
                id: mark

                anchors.verticalCenter: parent.verticalCenter
                x: 4
                width: 40
                height: 15
                radius: 7
                color: "#000000"

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#22ffffff" }
                        GradientStop { position: 0.6; color: "#00ffffff" }
                    }
                }
            }

            Column {
                anchors.left: mark.right
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    text: "Tide Island"
                    color: AppTheme.text
                    font.family: AppTheme.fontFamily
                    font.pixelSize: AppTheme.fontSizeHeading
                    font.weight: Font.DemiBold
                }

                Text {
                    text: "Settings"
                    color: AppTheme.textFaint
                    font.family: AppTheme.fontFamily
                    font.pixelSize: AppTheme.fontSizeCaption
                }
            }
        }

        // Search field — filters the sidebar entries by title/subtitle.
        Rectangle {
            id: searchField

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: brandRow.bottom
            anchors.margins: 14
            anchors.topMargin: 2
            height: 32
            radius: AppTheme.radiusChip
            color: AppTheme.chip
            border.width: 1
            border.color: searchInput.activeFocus ? AppTheme.accentActive : AppTheme.glassBorder

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "⌕"
                    color: AppTheme.textFaint
                    font.pixelSize: 13
                }

                TextInput {
                    id: searchInput

                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 20
                    color: AppTheme.text
                    font.family: AppTheme.fontFamily
                    font.pixelSize: AppTheme.fontSizeCaption
                    clip: true
                    selectByMouse: true
                    onTextChanged: window.searchQuery = text

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchInput.text === ""
                        text: "Search settings"
                        color: AppTheme.textFaint
                        font.family: AppTheme.fontFamily
                        font.pixelSize: AppTheme.fontSizeCaption
                    }
                }
            }
        }

        ScrollView {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: searchField.bottom
            anchors.bottom: statusFooter.top
            anchors.margins: 14
            anchors.topMargin: 8
            anchors.bottomMargin: 0
            clip: true
            contentWidth: availableWidth

            Column {
                width: parent.width
                spacing: 4

                Repeater {
                    model: window.filteredIndices

                    delegate: Rectangle {
                        id: navItem

                        required property int modelData

                        readonly property int pageIndex: navItem.modelData
                        readonly property var page: window.pages[navItem.pageIndex]
                        readonly property bool active: window.currentPage === navItem.pageIndex

                        width: parent.width
                        height: 46
                        radius: AppTheme.radiusNav
                        color: navItem.active
                            ? AppTheme.accentActive
                            : (navHover.hovered ? AppTheme.rowHover : "transparent")

                        Behavior on color { ColorAnimation { duration: AppTheme.animation } }

                        HoverHandler { id: navHover }

                        Text {
                            id: navGlyph

                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            text: navItem.page.glyph
                            color: navItem.active ? "#00230f" : AppTheme.textDim
                            font.pixelSize: 15
                        }

                        Column {
                            anchors.left: navGlyph.right
                            anchors.leftMargin: 12
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: navItem.page.title
                                color: navItem.active ? "#00230f" : AppTheme.text
                                font.family: AppTheme.fontFamily
                                font.pixelSize: AppTheme.fontSizeBody
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: navItem.page.subtitle
                                color: navItem.active ? "#0a2e18" : AppTheme.textFaint
                                font.family: AppTheme.fontFamily
                                font.pixelSize: AppTheme.fontSizeCaption
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: window.currentPage = navItem.pageIndex
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: window.filteredIndices.length === 0
                    text: "No matching settings"
                    color: AppTheme.textFaint
                    horizontalAlignment: Text.AlignHCenter
                    font.family: AppTheme.fontFamily
                    font.pixelSize: AppTheme.fontSizeCaption
                }
            }
        }

        Text {
            id: statusFooter

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 16
            text: ConfigStore.status !== "" ? ConfigStore.status : ConfigStore.path
            color: AppTheme.textFaint
            wrapMode: Text.Wrap
            elide: Text.ElideMiddle
            maximumLineCount: 2
            font.family: AppTheme.fontFamily
            font.pixelSize: AppTheme.fontSizeMicro
        }
    }

    // ---- Content -----------------------------------------------------------
    Item {
        anchors.left: sidebar.right
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Item {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 68

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: AppTheme.separator
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                text: window.pages[window.currentPage].title
                color: AppTheme.text
                font.family: AppTheme.fontFamily
                font.pixelSize: AppTheme.fontSizeTitle
                font.weight: Font.DemiBold
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                text: "Changes apply live"
                color: AppTheme.textFaint
                font.family: AppTheme.fontFamily
                font.pixelSize: AppTheme.fontSizeCaption
            }
        }

        ScrollView {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            contentWidth: availableWidth
            clip: true

            Item {
                width: parent.width
                implicitHeight: loader.implicitHeight + 52

                Loader {
                    id: loader

                    x: 26
                    y: 4
                    width: parent.width - 52
                    source: window.pages[window.currentPage].source

                    onLoaded: {
                        if (item)
                            item.width = loader.width;
                    }
                }

                Binding {
                    target: loader.item
                    property: "width"
                    value: loader.width
                    when: loader.item !== null
                }
            }
        }
    }
}

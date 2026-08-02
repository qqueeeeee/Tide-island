import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Window
import TideIsland 1.0

ApplicationWindow {
    id: window

    width: 1020
    height: 720
    minimumWidth: 860
    minimumHeight: 560
    visible: true
    title: "Tide Island Settings"
    color: AppTheme.windowBg

    FontLoader {
        source: "qrc:/RES/InterVariable.ttf"
    }

    readonly property var pages: [
        { title: "Island", subtitle: "Placement, scale, shape", glyph: "◗", source: "PageIsland.qml" },
        { title: "Status bar", subtitle: "Spacing and modules", glyph: "▤", source: "PageStatusBar.qml" },
        { title: "Appearance", subtitle: "Fonts and sizes", glyph: "✿", source: "PageAppearance.qml" },
        { title: "Capture", subtitle: "Screenshots and recording", glyph: "◉", source: "PageCapture.qml" },
        { title: "Shortcuts", subtitle: "Keybinds and IPC", glyph: "⌘", source: "PageShortcuts.qml" },
        { title: "About", subtitle: "Config file and resets", glyph: "ⓘ", source: "PageAbout.qml" }
    ]

    property int currentPage: 0

    // ---- Sidebar -----------------------------------------------------------
    Rectangle {
        id: sidebar

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 232
        color: AppTheme.sidebarBg

        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: AppTheme.separator
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 4

            Item {
                width: parent.width
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
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Settings"
                        color: AppTheme.textFaint
                        font.family: AppTheme.fontFamily
                        font.pixelSize: 12
                    }
                }
            }

            Repeater {
                model: window.pages

                delegate: Rectangle {
                    id: navItem

                    required property int index
                    required property var modelData

                    readonly property bool active: window.currentPage === navItem.index

                    width: parent.width
                    height: 46
                    radius: 11
                    color: navItem.active
                        ? AppTheme.accent
                        : (navHover.hovered ? AppTheme.rowHover : "transparent")

                    Behavior on color { ColorAnimation { duration: AppTheme.animation } }

                    HoverHandler { id: navHover }

                    Text {
                        id: navGlyph

                        x: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: navItem.modelData.glyph
                        color: navItem.active ? "#ffffff" : AppTheme.textDim
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
                            text: navItem.modelData.title
                            color: navItem.active ? "#ffffff" : AppTheme.text
                            font.family: AppTheme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: navItem.modelData.subtitle
                            color: navItem.active ? "#e8f1ff" : AppTheme.textFaint
                            font.family: AppTheme.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: window.currentPage = navItem.index
                    }
                }
            }
        }

        Text {
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
            font.pixelSize: 11
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

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                text: window.pages[window.currentPage].title
                color: AppTheme.text
                font.family: AppTheme.fontFamily
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                text: "Changes apply live"
                color: AppTheme.textFaint
                font.family: AppTheme.fontFamily
                font.pixelSize: 12
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

pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Screenshot card, ported pixel-for-pixel from the React reference
// (`NotificationExpanded`): 348 x 106, 16px side padding, a 36px rounded chip
// with the camera glyph, title + filename, then four equal-width action pills
// and the draining life bar along the bottom.
Item {
    id: root

    readonly property var userConfig: UserConfig

    property string filePath: ""
    property string textFontFamily: ""
    property string heroFontFamily: ""
    property string iconFontFamily: userConfig.iconFontFamily
    property bool showCondition: true
    // 1 -> 0 while the card is on screen; drives the bottom life bar.
    property real lifeProgress: 1
    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    readonly property string displayName: {
        const value = String(root.filePath);
        const index = value.lastIndexOf("/");
        return index >= 0 ? value.substring(index + 1) : value;
    }

    signal copyRequested()
    signal annotateRequested()
    signal openRequested()
    signal deleteRequested()
    signal dismissRequested()

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandTokens { id: tokens }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 12
        anchors.bottomMargin: 14

        // --- Header: chip + title + filename -------------------------------
        Item {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 36

            Rectangle {
                id: chip

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 36
                height: 36
                radius: 9
                color: tokens.chip

                Text {
                    anchors.centerIn: parent
                    text: tokens.glyphCamera
                    color: tokens.accent
                    font.family: root.iconFontFamily
                    font.pixelSize: 17
                }
            }

            Column {
                anchors.left: chip.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: "Screenshot Saved"
                    color: tokens.fg
                    elide: Text.ElideRight
                    font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: root.displayName
                    color: tokens.fg55
                    elide: Text.ElideMiddle
                    font.family: root.textFontFamily
                    font.pixelSize: 11
                }
            }
        }

        // --- Action pills --------------------------------------------------
        Row {
            id: actionRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 6

            readonly property real cellWidth: (width - spacing * 3) / 4

            IslandActionPill {
                width: actionRow.cellWidth
                glyph: tokens.glyphCopy
                label: "Copy"
                iconFontFamily: root.iconFontFamily
                textFontFamily: root.textFontFamily
                onActivated: root.copyRequested()
            }

            IslandActionPill {
                width: actionRow.cellWidth
                glyph: tokens.glyphMarkup
                label: "Markup"
                iconFontFamily: root.iconFontFamily
                textFontFamily: root.textFontFamily
                onActivated: root.annotateRequested()
            }

            IslandActionPill {
                width: actionRow.cellWidth
                glyph: tokens.glyphOpen
                label: "Open"
                iconFontFamily: root.iconFontFamily
                textFontFamily: root.textFontFamily
                onActivated: root.openRequested()
            }

            IslandActionPill {
                width: actionRow.cellWidth
                glyph: tokens.glyphTrash
                label: "Delete"
                destructive: true
                iconFontFamily: root.iconFontFamily
                textFontFamily: root.textFontFamily
                onActivated: root.deleteRequested()
            }
        }
    }

    // --- Life bar ----------------------------------------------------------
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        height: 2
        radius: 1
        color: "#1affffff"
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1, root.lifeProgress))
            radius: 1
            color: tokens.fg35
        }
    }
}

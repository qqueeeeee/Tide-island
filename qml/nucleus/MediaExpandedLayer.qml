pragma ComponentBehavior: Bound

import QtQuick

// Reference `MediaExpanded`: 372 x 196, 20px side padding / 16px vertical,
// 56px artwork, title + artist, 40px play circle, 4px scrubber with elapsed and
// remaining, then centered prev / next ghost buttons.
Item {
    id: root

    property string title: ""
    property string artist: ""
    property string artUrl: ""
    property bool playing: false
    property real progress: 0
    property string elapsedText: "0:00"
    property string remainingText: "0:00"
    property string textFontFamily: ""
    property string heroFontFamily: ""
    property string iconFontFamily: ""
    property bool showCondition: true
    property real revealOffset: 0

    signal playPauseRequested()
    signal nextRequested()
    signal previousRequested()

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
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
        anchors.bottomMargin: 16

        // --- Header ---------------------------------------------------------
        Item {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 56

            AlbumArt {
                id: art

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 56
                height: 56
                cornerRadius: 10
                source: root.artUrl
            }

            IslandCircleButton {
                id: playButton

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: 40
                implicitHeight: 40
                glyphSize: 16
                glyph: root.playing ? tokens.glyphPause : tokens.glyphPlay
                iconFontFamily: root.iconFontFamily
                onActivated: root.playPauseRequested()
            }

            Column {
                anchors.left: art.right
                anchors.leftMargin: 14
                anchors.right: playButton.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Text {
                    width: parent.width
                    text: root.title
                    color: tokens.fg
                    elide: Text.ElideRight
                    font.family: root.textFontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: root.artist
                    color: tokens.fg60
                    elide: Text.ElideRight
                    font.family: root.textFontFamily
                    font.pixelSize: 11.5
                }
            }
        }

        // --- Scrubber -------------------------------------------------------
        Column {
            id: scrubber

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: 6
            spacing: 6

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: "#26ffffff"
                clip: true

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    radius: 2
                    width: parent.width * Math.max(0, Math.min(1, root.progress))
                    color: tokens.fg85

                    Behavior on width { NumberAnimation { duration: 240 } }
                }
            }

            Item {
                width: parent.width
                height: 11

                Text {
                    anchors.left: parent.left
                    text: root.elapsedText
                    color: tokens.fg55
                    font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
                    font.pixelSize: 10
                }

                Text {
                    anchors.right: parent.right
                    text: "-" + root.remainingText
                    color: tokens.fg55
                    font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
                    font.pixelSize: 10
                }
            }
        }

        // --- Transport ------------------------------------------------------
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            spacing: 28

            Text {
                text: tokens.glyphPrev
                color: tokens.fg85
                font.family: root.iconFontFamily
                font.pixelSize: 18
                scale: previousArea.pressed ? 0.9 : 1

                Behavior on scale { NumberAnimation { duration: 110 } }

                MouseArea {
                    id: previousArea
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.previousRequested()
                }
            }

            Text {
                text: tokens.glyphNext
                color: tokens.fg85
                font.family: root.iconFontFamily
                font.pixelSize: 18
                scale: nextArea.pressed ? 0.9 : 1

                Behavior on scale { NumberAnimation { duration: 110 } }

                MouseArea {
                    id: nextArea
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.nextRequested()
                }
            }
        }
    }
}

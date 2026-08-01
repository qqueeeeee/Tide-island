pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Compact "now playing" live activity: album thumbnail, track title and a tiny
// equaliser. This is a *resting* layer — it owns the collapsed capsule for as
// long as the player is actually playing (or paused), and never auto-hides.
Item {
    id: root

    readonly property var userConfig: UserConfig

    property string currentArtUrl: ""
    property string currentTrack: ""
    property string currentArtist: ""
    property bool playing: true
    property string textFontFamily: ""
    property bool showCondition: true
    // Driven by IslandContentReveal — do not bind.
    property real revealOffset: 0

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 9

        // Album art, with a neutral placeholder when the player exposes none.
        Rectangle {
            id: artwork

            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            radius: 6
            color: "#1f1f1f"
            clip: true
            opacity: root.playing ? 1 : 0.55

            Image {
                anchors.fill: parent
                source: root.currentArtUrl
                visible: root.currentArtUrl !== "" && status === Image.Ready
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize.width: 40
                sourceSize.height: 40
            }
        }

        Text {
            id: title

            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(
                0,
                parent.width - artwork.width - equaliser.width - parent.spacing * 2
            )
            text: root.currentTrack !== "" ? root.currentTrack : "Now Playing"
            color: "#ffffff"
            opacity: root.playing ? 1 : 0.6
            elide: Text.ElideRight
            maximumLineCount: 1
            font.family: root.textFontFamily
            font.pixelSize: root.userConfig.bodyFontSize
            font.weight: Font.DemiBold
        }

        // Three bars that dance while playing and flatten when paused.
        Row {
            id: equaliser

            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            spacing: 2

            Repeater {
                model: 3

                Rectangle {
                    required property int index

                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    radius: 1.5
                    height: root.playing ? 5 : 3
                    color: "#ffffff"
                    opacity: root.playing ? 0.9 : 0.4

                    SequentialAnimation on height {
                        running: root.playing && root.showCondition
                        loops: Animation.Infinite

                        PauseAnimation { duration: index * 110 }
                        NumberAnimation { to: 12; duration: 320; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 4; duration: 320; easing.type: Easing.InOutQuad }
                    }
                }
            }
        }
    }
}

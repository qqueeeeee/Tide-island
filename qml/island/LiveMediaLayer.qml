pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Compact "now playing" live activity — dual compact layout: album art pinned
// left, animated audio wave pinned right, gap in the middle (notch friendly).
//
// This is a *resting* layer. It owns the collapsed capsule for as long as a
// player holds a track, never auto-hides, and NEVER auto-expands: pausing only
// freezes the wave, and a track change cross-fades the art in place. The big
// now-playing card is only ever opened by the user tapping the pill.
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

    // Cross-fade state for in-place track changes.
    property string displayedArtUrl: ""
    property string outgoingArtUrl: ""
    property real artCrossfade: 1

    anchors.fill: parent
    opacity: 0
    transform: Translate { y: root.revealOffset }

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Component.onCompleted: displayedArtUrl = currentArtUrl

    onCurrentArtUrlChanged: {
        if (currentArtUrl === displayedArtUrl) return;

        if (displayedArtUrl === "" || !showCondition) {
            artCrossfadeAnimation.stop();
            outgoingArtUrl = "";
            displayedArtUrl = currentArtUrl;
            artCrossfade = 1;
            return;
        }

        outgoingArtUrl = displayedArtUrl;
        displayedArtUrl = currentArtUrl;
        artCrossfade = 0;
        artCrossfadeAnimation.restart();
    }

    SequentialAnimation {
        id: artCrossfadeAnimation

        NumberAnimation {
            target: root
            property: "artCrossfade"
            from: 0
            to: 1
            duration: 220
            easing.type: Easing.OutCubic
        }

        ScriptAction { script: root.outgoingArtUrl = "" }
    }

    IslandDualCompact {
        horizontalPadding: 12

        leftItem: Component {
            Rectangle {
                width: 20
                height: 20
                radius: 6
                color: "#1f1f1f"
                clip: true
                opacity: root.playing ? 1 : 0.6

                Behavior on opacity {
                    NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
                }

                Image {
                    anchors.fill: parent
                    source: root.outgoingArtUrl
                    visible: root.outgoingArtUrl !== "" && status === Image.Ready
                    opacity: 1 - root.artCrossfade
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: 40
                    sourceSize.height: 40
                }

                Image {
                    anchors.fill: parent
                    source: root.displayedArtUrl
                    visible: root.displayedArtUrl !== "" && status === Image.Ready
                    opacity: root.artCrossfade
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: 40
                    sourceSize.height: 40
                }
            }
        }

        rightItem: Component {
            IslandAudioWave {
                playing: root.playing
                active: root.showCondition
            }
        }
    }
}

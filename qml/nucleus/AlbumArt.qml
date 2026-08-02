pragma ComponentBehavior: Bound

import QtQuick

// Reference `AlbumArt`: 140deg warm-to-violet gradient with a soft highlight in
// the upper left. Falls back to the gradient whenever MPRIS has no artwork.
Item {
    id: root

    property string source: ""
    property real cornerRadius: 6

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        clip: true

        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#e0644f" }
            GradientStop { position: 0.55; color: "#a3419b" }
            GradientStop { position: 1.0; color: "#3f4bb0" }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#59ffffff" }
                GradientStop { position: 0.58; color: "#00ffffff" }
            }
        }

        Image {
            anchors.fill: parent
            visible: root.source !== "" && status === Image.Ready
            source: root.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
        }
    }
}

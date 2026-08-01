pragma ComponentBehavior: Bound

import QtQuick
import IslandBackend

// Expanded island layer shown right after a screenshot lands: thumbnail on the
// left, quick actions on the right (copy, markup, open, delete).
Item {
    id: root

    readonly property var userConfig: UserConfig

    property string filePath: ""
    property string textFontFamily: ""
    property string heroFontFamily: ""
    property bool showCondition: true
    // Driven by IslandContentReveal (see below) — do not bind.
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

    IslandContentReveal {
        target: root
        active: root.showCondition
    }

    Item {
        anchors.fill: parent
        anchors.margins: 22

        Rectangle {
            id: thumbnailFrame

            anchors.left: parent.left
            anchors.top: parent.top
            width: 128
            height: 84
            radius: 12
            color: "#14ffffff"
            border.width: 1
            border.color: "#26ffffff"
            clip: true

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: root.filePath !== "" ? "file://" + root.filePath : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                smooth: true
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.openRequested()
            }
        }

        Text {
            id: title

            anchors.left: thumbnailFrame.right
            anchors.leftMargin: 16
            anchors.top: thumbnailFrame.top
            anchors.right: parent.right
            text: "Screenshot saved"
            color: "#ffffff"
            elide: Text.ElideRight
            font.family: root.heroFontFamily !== "" ? root.heroFontFamily : root.textFontFamily
            font.pixelSize: root.userConfig.titleFontSize
            font.weight: Font.DemiBold
        }

        Text {
            id: subtitle

            anchors.left: title.left
            anchors.right: parent.right
            anchors.top: title.bottom
            anchors.topMargin: 4
            text: root.displayName
            color: "#99ffffff"
            elide: Text.ElideMiddle
            font.family: root.textFontFamily
            font.pixelSize: Math.max(11, root.userConfig.bodyFontSize - 3)
        }

        Row {
            anchors.left: title.left
            anchors.bottom: thumbnailFrame.bottom
            spacing: 8

            IslandActionButton {
                label: "Copy"
                accent: true
                textFontFamily: root.textFontFamily
                onActivated: root.copyRequested()
            }

            IslandActionButton {
                label: "Markup"
                textFontFamily: root.textFontFamily
                onActivated: root.annotateRequested()
            }

            IslandActionButton {
                label: "Open"
                textFontFamily: root.textFontFamily
                onActivated: root.openRequested()
            }

            IslandActionButton {
                label: "Delete"
                destructive: true
                textFontFamily: root.textFontFamily
                onActivated: root.deleteRequested()
            }
        }
    }
}

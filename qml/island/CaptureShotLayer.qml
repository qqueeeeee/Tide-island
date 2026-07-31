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
    opacity: showCondition ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 220; easing.type: Easing.InOutQuad }
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

            ActionButton {
                label: "Copy"
                onActivated: root.copyRequested()
            }

            ActionButton {
                label: "Markup"
                onActivated: root.annotateRequested()
            }

            ActionButton {
                label: "Open"
                onActivated: root.openRequested()
            }

            ActionButton {
                label: "Delete"
                destructive: true
                onActivated: root.deleteRequested()
            }
        }
    }

    component ActionButton: Rectangle {
        id: button

        property string label: ""
        property bool destructive: false

        signal activated()

        implicitWidth: buttonLabel.implicitWidth + 22
        width: implicitWidth
        height: 30
        radius: 15
        color: buttonArea.pressed
            ? (button.destructive ? "#66ff453a" : "#3dffffff")
            : (button.destructive ? "#33ff453a" : "#1fffffff")
        scale: buttonArea.pressed ? 0.95 : 1

        Behavior on color { ColorAnimation { duration: 140 } }
        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        Text {
            id: buttonLabel

            anchors.centerIn: parent
            text: button.label
            color: button.destructive ? "#ff8a80" : "#ffffff"
            font.family: root.textFontFamily
            font.pixelSize: Math.max(11, root.userConfig.bodyFontSize - 2)
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: buttonArea

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: button.activated()
        }
    }
}

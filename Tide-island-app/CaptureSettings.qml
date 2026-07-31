import QtQuick
import QtQuick.Controls
import TideIsland 1.0

PagePanel {
    id: root

    property int revision: 0

    function boolValue(key, fallback) {
        revision
        const value = ConfigStore.value(key, fallback)
        return value === true || value === "true"
    }

    function setBoolValue(key, value) {
        ConfigStore.setValue(key, value)
        ConfigStore.save()
        revision += 1
    }

    function intValue(key, fallback) {
        revision
        const value = Number(ConfigStore.value(key, fallback))
        return isNaN(value) ? fallback : Math.round(value)
    }

    function saveInt(key, value, fallback, minimumValue, maximumValue) {
        if (String(value).trim().length === 0)
            return fallback

        const parsedValue = Number(value)
        if (isNaN(parsedValue))
            return fallback

        const roundedValue = Math.min(maximumValue, Math.max(minimumValue, Math.round(parsedValue)))
        ConfigStore.setValue(key, roundedValue)
        ConfigStore.save()
        revision += 1
        return roundedValue
    }

    function textValue(key, fallback) {
        revision
        const value = ConfigStore.value(key, fallback)
        return value === undefined || value === null ? "" : String(value)
    }

    function saveText(key, value) {
        ConfigStore.setValue(key, String(value).trim())
        ConfigStore.save()
        revision += 1
        return String(value).trim()
    }

    Flickable {
        id: scroller

        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: content.height
        boundsBehavior: Flickable.StopAtBounds
        boundsMovement: Flickable.StopAtBounds
        interactive: false

        WheelHandler {
            target: null
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

            onWheel: function(event) {
                const rawDelta = event.pixelDelta.y !== 0 ? event.pixelDelta.y : event.angleDelta.y / 120 * 64
                const maxY = Math.max(0, scroller.contentHeight - scroller.height)
                scroller.contentY = Math.max(0, Math.min(maxY, scroller.contentY - rawDelta))
                event.accepted = true
            }
        }

        Item {
            id: content

            width: scroller.width
            height: pathsCard.y + pathsCard.height + 40

            Text {
                id: title

                text: "Capture"
                color: Theme.textColor
                font.family: Theme.titleFontFamily
                font.pixelSize: 30
                x: 60
                y: 50
            }

            Text {
                id: hintLabel

                anchors.top: title.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.right: parent.right
                anchors.rightMargin: 40
                text: "Screenshots and recordings run through grim, slurp and wf-recorder. "
                    + "Bind keys to: qs ipc call capture screenshot / capture toggleRecordingArea."
                wrapMode: Text.WordWrap
                color: Theme.subtleTextColor
                font.family: Theme.textFontFamily
                font.pixelSize: 14
            }

            Text {
                id: behaviourTitle

                text: "Behaviour"
                anchors.top: hintLabel.bottom
                anchors.topMargin: 26
                anchors.left: parent.left
                anchors.leftMargin: 32
                color: Theme.textColor
                font.family: Theme.titleFontFamily
                font.pixelSize: 23
            }

            Rectangle {
                id: behaviourCard

                anchors.top: behaviourTitle.bottom
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.right: parent.right
                anchors.rightMargin: 40
                height: behaviourColumn.implicitHeight + 32
                radius: 12
                color: Theme.componentBgColor
                border.width: 1
                border.color: Theme.inputBorderColor

                Column {
                    id: behaviourColumn

                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    ToggleRow {
                        width: parent.width
                        title: "Record Audio"
                        subtitle: "Capture the default sink monitor while recording"
                        checked: root.boolValue("captureRecordAudio", true)
                        onToggledValue: function(value) { root.setBoolValue("captureRecordAudio", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Copy To Clipboard"
                        subtitle: "Copy the screenshot image and the recording file URI"
                        checked: root.boolValue("captureCopyToClipboard", true)
                        onToggledValue: function(value) { root.setBoolValue("captureCopyToClipboard", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Desktop Notification"
                        subtitle: "Send a notify-send message once the file is saved"
                        checked: root.boolValue("captureNotify", true)
                        onToggledValue: function(value) { root.setBoolValue("captureNotify", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Screenshot Preview"
                        subtitle: "Expand the island with a thumbnail and quick actions"
                        checked: root.boolValue("captureShowScreenshotPreview", true)
                        onToggledValue: function(value) { root.setBoolValue("captureShowScreenshotPreview", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Status Bar Recording Pill"
                        subtitle: "Keep a red timer in the bar while recording"
                        checked: root.boolValue("statusBarShowRecordingPill", true)
                        onToggledValue: function(value) { root.setBoolValue("statusBarShowRecordingPill", value) }
                    }

                    ValueRow {
                        width: parent.width
                        title: "Preview Duration"
                        subtitle: "Seconds the screenshot preview stays open"
                        value: String(root.intValue("captureScreenshotPreviewSeconds", 6))
                        onCommit: function(text) {
                            return String(root.saveInt("captureScreenshotPreviewSeconds", text, 6, 2, 60))
                        }
                    }
                }
            }

            Text {
                id: pathsTitle

                text: "Paths & Tools"
                anchors.top: behaviourCard.bottom
                anchors.topMargin: 30
                anchors.left: parent.left
                anchors.leftMargin: 32
                color: Theme.textColor
                font.family: Theme.titleFontFamily
                font.pixelSize: 23
            }

            Rectangle {
                id: pathsCard

                anchors.top: pathsTitle.bottom
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.right: parent.right
                anchors.rightMargin: 40
                height: pathsColumn.implicitHeight + 32
                radius: 12
                color: Theme.componentBgColor
                border.width: 1
                border.color: Theme.inputBorderColor

                Column {
                    id: pathsColumn

                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    TextRow {
                        width: parent.width
                        title: "Screenshot Folder"
                        subtitle: "Empty means ~/Pictures/Screenshots"
                        value: root.textValue("captureScreenshotDirectory", "")
                        onCommit: function(text) { return root.saveText("captureScreenshotDirectory", text) }
                    }

                    TextRow {
                        width: parent.width
                        title: "Recording Folder"
                        subtitle: "Empty means ~/Videos"
                        value: root.textValue("captureVideoDirectory", "")
                        onCommit: function(text) { return root.saveText("captureVideoDirectory", text) }
                    }

                    TextRow {
                        width: parent.width
                        title: "Markup Tool"
                        subtitle: "Command for annotating, %f is the file. Empty tries satty, then swappy"
                        value: root.textValue("captureAnnotationTool", "")
                        onCommit: function(text) { return root.saveText("captureAnnotationTool", text) }
                    }
                }
            }
        }
    }

    component ToggleRow: Item {
        id: toggleRow

        property string title: ""
        property string subtitle: ""
        property bool checked: false

        signal toggledValue(bool value)

        height: 52

        Text {
            id: toggleTitle

            text: toggleRow.title
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 4
            color: Theme.textColor
            font.family: Theme.textFontFamily
            font.pixelSize: 18
        }

        Text {
            text: toggleRow.subtitle
            anchors.left: toggleTitle.left
            anchors.top: toggleTitle.bottom
            anchors.topMargin: 4
            width: Math.max(80, parent.width - rowSwitch.width - 28)
            color: Theme.subtleTextColor
            elide: Text.ElideRight
            font.family: Theme.textFontFamily
            font.pixelSize: 14
        }

        StyledSwitch {
            id: rowSwitch

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: toggleRow.checked

            onToggled: function(value) { toggleRow.toggledValue(value) }
        }
    }

    component ValueRow: Item {
        id: valueRow

        property string title: ""
        property string subtitle: ""
        property string value: ""

        property var onCommit: null

        height: 52

        Text {
            id: valueTitle

            text: valueRow.title
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 4
            color: Theme.textColor
            font.family: Theme.textFontFamily
            font.pixelSize: 18
        }

        Text {
            text: valueRow.subtitle
            anchors.left: valueTitle.left
            anchors.top: valueTitle.bottom
            anchors.topMargin: 4
            width: Math.max(80, parent.width - valueField.width - 28)
            color: Theme.subtleTextColor
            elide: Text.ElideRight
            font.family: Theme.textFontFamily
            font.pixelSize: 14
        }

        ConfigTextField {
            id: valueField

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 96
            text: valueRow.value
            inputMethodHints: Qt.ImhDigitsOnly
            validator: IntValidator { bottom: 0; top: 600 }

            onEditingFinished: {
                if (valueRow.onCommit)
                    valueField.text = valueRow.onCommit(valueField.text)
            }
        }
    }

    component TextRow: Item {
        id: textRow

        property string title: ""
        property string subtitle: ""
        property string value: ""

        property var onCommit: null

        height: 52

        Text {
            id: textRowTitle

            text: textRow.title
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.topMargin: 4
            color: Theme.textColor
            font.family: Theme.textFontFamily
            font.pixelSize: 18
        }

        Text {
            text: textRow.subtitle
            anchors.left: textRowTitle.left
            anchors.top: textRowTitle.bottom
            anchors.topMargin: 4
            width: Math.max(80, parent.width - textField.width - 28)
            color: Theme.subtleTextColor
            elide: Text.ElideRight
            font.family: Theme.textFontFamily
            font.pixelSize: 14
        }

        ConfigTextField {
            id: textField

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 260
            text: textRow.value

            onEditingFinished: {
                if (textRow.onCommit)
                    textField.text = textRow.onCommit(textField.text)
            }
        }
    }

    component StyledSwitch: Item {
        id: control

        signal toggled(bool checked)

        property bool checked: false

        width: 48
        height: 26

        Rectangle {
            id: track

            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            width: 40
            height: 24
            radius: 12
            color: control.checked ? Theme.accentColor : Theme.componentBgColor
            border.width: 1
            border.color: control.checked ? Theme.accentColor : Theme.inputBorderColor

            Behavior on color {
                ColorAnimation { duration: 180; easing.type: Easing.InOutQuad }
            }
        }

        Rectangle {
            id: knob

            width: 18
            height: 18
            radius: 9
            x: control.checked ? 22 : 6
            y: 3
            color: Theme.cardBgColor

            Behavior on x {
                NumberAnimation { duration: 180; easing.type: Easing.InOutQuad }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: control.toggled(!control.checked)
        }
    }
}

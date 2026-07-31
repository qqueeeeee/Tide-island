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
            height: layoutCard.y + layoutCard.height + 40

            Text {
                id: title

                text: "Status Bar"
                color: Theme.textColor
                font.family: Theme.titleFontFamily
                font.pixelSize: 30
                x: 60
                y: 50
            }

            Text {
                id: modulesTitle

                text: "Modules"
                anchors.top: title.bottom
                anchors.topMargin: 34
                anchors.left: parent.left
                anchors.leftMargin: 32
                color: Theme.textColor
                font.family: Theme.titleFontFamily
                font.pixelSize: 23
            }

            Rectangle {
                id: modulesCard

                anchors.top: modulesTitle.bottom
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.right: parent.right
                anchors.rightMargin: 40
                height: modulesColumn.implicitHeight + 32
                radius: 12
                color: Theme.componentBgColor
                border.width: 1
                border.color: Theme.inputBorderColor

                Column {
                    id: modulesColumn

                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 4

                    ToggleRow {
                        width: parent.width
                        title: "Enable Status Bar"
                        subtitle: "Transparent iOS-style bar sharing the island's surface"
                        checked: root.boolValue("statusBarEnabled", true)
                        onToggledValue: function(value) { root.setBoolValue("statusBarEnabled", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Workspace Dots"
                        subtitle: "Show workspace indicators on the left side"
                        checked: root.boolValue("statusBarShowWorkspaces", true)
                        onToggledValue: function(value) { root.setBoolValue("statusBarShowWorkspaces", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Focused Window"
                        subtitle: "Show the focused application next to the dots"
                        checked: root.boolValue("statusBarShowActiveWindow", true)
                        onToggledValue: function(value) { root.setBoolValue("statusBarShowActiveWindow", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Status Icons"
                        subtitle: "Wi-Fi, Bluetooth, mute and battery on the right side"
                        checked: root.boolValue("statusBarShowStatusIcons", true)
                        onToggledValue: function(value) { root.setBoolValue("statusBarShowStatusIcons", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Clock"
                        subtitle: "Show the clock at the far right"
                        checked: root.boolValue("statusBarShowClock", true)
                        onToggledValue: function(value) { root.setBoolValue("statusBarShowClock", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Date On Hover"
                        subtitle: "Swap the clock for the date while hovering it"
                        checked: root.boolValue("statusBarShowDateOnHover", true)
                        onToggledValue: function(value) { root.setBoolValue("statusBarShowDateOnHover", value) }
                    }

                    ToggleRow {
                        width: parent.width
                        title: "Yield To Island"
                        subtitle: "Fade the bar away whenever the island expands"
                        checked: root.boolValue("statusBarFadeWithIsland", true)
                        onToggledValue: function(value) { root.setBoolValue("statusBarFadeWithIsland", value) }
                    }
                }
            }

            Text {
                id: layoutTitle

                text: "Layout"
                anchors.top: modulesCard.bottom
                anchors.topMargin: 30
                anchors.left: parent.left
                anchors.leftMargin: 32
                color: Theme.textColor
                font.family: Theme.titleFontFamily
                font.pixelSize: 23
            }

            Rectangle {
                id: layoutCard

                anchors.top: layoutTitle.bottom
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.leftMargin: 32
                anchors.right: parent.right
                anchors.rightMargin: 40
                height: layoutColumn.implicitHeight + 32
                radius: 12
                color: Theme.componentBgColor
                border.width: 1
                border.color: Theme.inputBorderColor

                Column {
                    id: layoutColumn

                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    ValueRow {
                        width: parent.width
                        title: "Side Margin"
                        subtitle: "Distance from the screen edges, in pixels"
                        value: String(root.intValue("statusBarSideMargin", 22))
                        onCommit: function(text) {
                            return String(root.saveInt("statusBarSideMargin", text, 22, 0, 400))
                        }
                    }

                    ValueRow {
                        width: parent.width
                        title: "Opacity"
                        subtitle: "Overall bar opacity, 0 to 100"
                        value: String(root.intValue("statusBarOpacity", 100))
                        onCommit: function(text) {
                            return String(root.saveInt("statusBarOpacity", text, 100, 0, 100))
                        }
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
            validator: IntValidator { bottom: 0; top: 400 }

            onEditingFinished: {
                if (valueRow.onCommit)
                    valueField.text = valueRow.onCommit(valueField.text)
            }

            onAccepted: {
                if (valueRow.onCommit)
                    valueField.text = valueRow.onCommit(valueField.text)
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

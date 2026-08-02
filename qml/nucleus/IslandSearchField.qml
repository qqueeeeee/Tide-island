pragma ComponentBehavior: Bound

import QtQuick

// Reference search pill shared by the launcher and the clipboard:
// `rounded-full bg-island-chip px-3.5 py-2` with a search glyph, the input and
// an "ESC" hint chip.
Rectangle {
    id: root

    property string placeholder: "Search…"
    property string textFontFamily: ""
    property string iconFontFamily: ""
    property string hint: "ESC"
    readonly property string text: input.text

    signal accepted()
    signal cancelled()
    signal moveDown()
    signal moveUp()
    signal deleteSelected()
    signal textEdited(string value)

    IslandTokens { id: tokens }

    implicitHeight: 34
    height: implicitHeight
    radius: height / 2
    color: tokens.chip

    function clear() {
        input.text = "";
    }

    function grabFocus() {
        input.forceActiveFocus();
    }

    Text {
        id: glyph

        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: tokens.glyphSearch
        color: tokens.fg50
        font.family: root.iconFontFamily
        font.pixelSize: 13
    }

    Text {
        id: hintChip

        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        visible: root.hint !== ""
        text: root.hint
        color: tokens.fg45
        font.family: root.textFontFamily
        font.pixelSize: 9
        font.weight: Font.Medium
    }

    TextInput {
        id: input

        anchors.left: glyph.right
        anchors.leftMargin: 10
        anchors.right: hintChip.visible ? hintChip.left : parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        color: tokens.fg
        selectionColor: tokens.fg25
        selectedTextColor: tokens.fg
        clip: true
        font.family: root.textFontFamily
        font.pixelSize: 13
        onTextChanged: root.textEdited(text)

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Down) {
                root.moveDown();
                event.accepted = true;
            } else if (event.key === Qt.Key_Up) {
                root.moveUp();
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.accepted();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                root.cancelled();
                event.accepted = true;
            } else if (event.key === Qt.Key_Backspace
                       && ((event.modifiers & Qt.ControlModifier) || (event.modifiers & Qt.MetaModifier))) {
                root.deleteSelected();
                event.accepted = true;
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            visible: input.text === ""
            text: root.placeholder
            color: tokens.fg35
            font: input.font
        }
    }
}

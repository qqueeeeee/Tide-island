import QtQuick
import QtQuick.Controls.Basic
import TideIsland 1.0

TextField {
    id: field

    property string placeholder: ""

    signal committed(string value)

    height: 30
    color: AppTheme.text
    placeholderText: field.placeholder
    placeholderTextColor: AppTheme.textFaint
    font.family: AppTheme.fontFamily
    font.pixelSize: 12
    leftPadding: 9
    rightPadding: 9
    selectByMouse: true

    background: Rectangle {
        radius: 8
        color: AppTheme.dark ? "#101014" : "#f5f5f8"
        border.width: 1
        border.color: field.activeFocus ? AppTheme.accent : AppTheme.cardBorder
    }

    onEditingFinished: field.committed(field.text.trim())
}

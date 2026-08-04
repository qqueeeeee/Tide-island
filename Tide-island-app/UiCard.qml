import QtQuick
import TideIsland 1.0

// Grouped settings card: title, optional caption, hairline-separated rows.
// Restyled as a near-black glass panel matching the island's chip surfaces.
Rectangle {
    id: card

    property string title: ""
    property string caption: ""
    default property alias content: rows.data

    color: AppTheme.cardBg
    radius: AppTheme.radiusCard
    border.width: 1
    border.color: AppTheme.cardBorder
    implicitHeight: layout.implicitHeight + AppTheme.pad * 2

    Column {
        id: layout

        x: AppTheme.pad
        y: AppTheme.pad
        width: card.width - AppTheme.pad * 2
        spacing: 12

        Column {
            width: parent.width
            spacing: 3
            visible: card.title !== ""

            Text {
                text: card.title
                color: AppTheme.text
                font.family: AppTheme.fontFamily
                font.pixelSize: AppTheme.fontSizeHeading
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                visible: card.caption !== ""
                text: card.caption
                color: AppTheme.textFaint
                wrapMode: Text.WordWrap
                font.family: AppTheme.fontFamily
                font.pixelSize: AppTheme.fontSizeCaption
            }
        }

        Column {
            id: rows
            width: parent.width
            spacing: 2
        }
    }
}

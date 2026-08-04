import QtQuick
import TideIsland 1.0

Column {
    spacing: 14

    UiCard {
        width: parent.width
        title: "Where captures go"
        caption: "Leave empty to use ~/Videos and ~/Pictures."

        UiTextField {
            label: "Recordings folder"
            configKey: "captureVideoDirectory"
            placeholder: "~/Videos"
            fieldWidth: 280
        }

        UiTextField {
            label: "Screenshots folder"
            configKey: "captureScreenshotDirectory"
            placeholder: "~/Pictures"
            fieldWidth: 280
        }

        UiTextField {
            label: "Annotation tool"
            hint: "Opened from the screenshot card's Edit action, e.g. satty or swappy."
            configKey: "captureAnnotationTool"
            placeholder: "satty"
            fieldWidth: 280
        }
    }

    UiCard {
        width: parent.width
        title: "Formats & naming"

        UiSegment {
            label: "Screenshot format"
            configKey: "captureScreenshotFormat"
            options: [
                { label: "PNG", value: "png" },
                { label: "JPG", value: "jpg" }
            ]
        }

        UiSegment {
            label: "Video format"
            configKey: "captureVideoFormat"
            options: [
                { label: "MP4", value: "mp4" },
                { label: "MKV", value: "mkv" },
                { label: "WebM", value: "webm" }
            ]
        }

        UiTextField {
            label: "Screenshot name pattern"
            hint: "strftime tokens, e.g. %Y-%m-%d_%H-%M-%S."
            configKey: "captureScreenshotNamePattern"
            placeholder: "Screenshot_%Y-%m-%d_%H-%M-%S"
            fieldWidth: 280
        }

        UiTextField {
            label: "Recording name pattern"
            configKey: "captureVideoNamePattern"
            placeholder: "Recording_%Y-%m-%d_%H-%M-%S"
            fieldWidth: 280
        }
    }

    UiCard {
        width: parent.width
        title: "Behaviour"

        UiSwitch {
            label: "Record audio"
            configKey: "captureRecordAudio"
        }

        UiSwitch {
            label: "Copy captures to the clipboard"
            configKey: "captureCopyToClipboard"
        }

        UiSwitch {
            label: "Send a desktop notification"
            configKey: "captureNotify"
        }

        UiSwitch {
            label: "Show the screenshot card in the island"
            configKey: "captureShowScreenshotPreview"
        }

        UiSlider {
            label: "Screenshot card duration"
            configKey: "captureScreenshotPreviewSeconds"
            from: 2
            to: 30
            suffix: " s"
        }
    }
}

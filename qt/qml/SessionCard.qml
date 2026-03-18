import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: card

    property string sessionId
    property string sessionName
    property int sessionState
    property int sessionProvider
    property double sessionCost
    property string sessionProjectPath

    radius: 8
    color: "#2D2D2D"
    border.color: {
        switch (sessionState) {
            case 1: return "#FF9F0A"   // needsInput
            case 2: return "#FF453A"   // error
            default: return "#3D3D3D"
        }
    }
    border.width: sessionState === 1 || sessionState === 2 ? 2 : 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Header: name + state
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // State dot
            Rectangle {
                width: 10
                height: 10
                radius: 5
                color: {
                    switch (sessionState) {
                        case 0: return "#30D158"
                        case 1: return "#FF9F0A"
                        case 2: return "#FF453A"
                        default: return "#555555"
                    }
                }
            }

            // Provider icon
            Text {
                text: {
                    switch (sessionProvider) {
                        case 0: return "\u2728"  // claude
                        case 1: return "\u26A1"  // codex
                        case 2: return "\u270F"  // aider
                        case 3: return "\u2B50"  // gemini
                        default: return "\u2699"  // custom
                    }
                }
                font.pixelSize: 14
            }

            Text {
                text: sessionName
                color: "#FFFFFF"
                font.pixelSize: 14
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: "$" + sessionCost.toFixed(2)
                color: "#30D158"
                font.pixelSize: 12
            }
        }

        // Project path
        Text {
            text: sessionProjectPath || ""
            color: "#8E8E93"
            font.pixelSize: 11
            elide: Text.ElideMiddle
            Layout.fillWidth: true
            visible: text.length > 0
        }

        // State label
        Text {
            text: {
                switch (sessionState) {
                    case 0: return "Working..."
                    case 1: return "Needs Input"
                    case 2: return "Error"
                    default: return "Inactive"
                }
            }
            color: {
                switch (sessionState) {
                    case 0: return "#30D158"
                    case 1: return "#FF9F0A"
                    case 2: return "#FF453A"
                    default: return "#555555"
                }
            }
            font.pixelSize: 12
        }

        // Terminal output preview (placeholder)
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1A1A1A"
            radius: 4

            Text {
                anchors.fill: parent
                anchors.margins: 8
                text: "Terminal output will appear here"
                color: "#555555"
                font.pixelSize: 11
                font.family: "monospace"
                wrapMode: Text.Wrap
                elide: Text.ElideRight
            }
        }
    }
}

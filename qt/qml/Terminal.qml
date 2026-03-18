import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: terminalPanel
    color: "#1A1A1A"

    property string sessionId: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: "#252525"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Text {
                    text: "Terminal"
                    color: "#8E8E93"
                    font.pixelSize: 12
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: sessionId.length > 0 ? sessionId.substring(0, 8) + "..." : "No session"
                    color: "#555555"
                    font.pixelSize: 11
                    font.family: "monospace"
                }
            }
        }

        // Terminal widget placeholder
        // In production, this uses the native TerminalWidget (QQuickPaintedItem)
        // registered as a QML type. For now, show output as scrollable text.
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            TextArea {
                id: terminalOutput
                readOnly: true
                color: "#E0E0E0"
                font.family: "monospace"
                font.pixelSize: 13
                background: Rectangle { color: "#1A1A1A" }
                wrapMode: TextEdit.NoWrap
                text: sessionModel.output || ""
            }
        }

        // Input bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            color: "#252525"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8

                Text {
                    text: ">"
                    color: "#30D158"
                    font.pixelSize: 14
                    font.family: "monospace"
                }

                TextField {
                    id: inputField
                    Layout.fillWidth: true
                    placeholderText: "Type command..."
                    color: "#FFFFFF"
                    font.family: "monospace"
                    font.pixelSize: 13
                    background: Rectangle { color: "transparent" }

                    onAccepted: {
                        if (text.length > 0) {
                            sessionModel.sendInput(text + "\n")
                            text = ""
                        }
                    }
                }
            }
        }
    }
}

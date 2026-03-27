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
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollView {
                anchors.fill: parent

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

            // Drag-and-drop overlay for file insertion into terminal
            DropArea {
                id: dropArea
                anchors.fill: parent
                keys: ["text/uri-list"]

                onEntered: function(drag) {
                    dropOverlay.visible = true
                    drag.accepted = true
                }

                onExited: {
                    dropOverlay.visible = false
                }

                onDropped: function(drop) {
                    dropOverlay.visible = false
                    if (drop.hasUrls) {
                        for (var i = 0; i < drop.urls.length; i++) {
                            var url = drop.urls[i]
                            // Convert file:// URL to local path
                            var path = url.toString()
                            if (path.startsWith("file://")) {
                                path = path.substring(7)
                            }
                            // Escape path for shell: wrap in single quotes
                            path = path.replace(/'/g, "'\\''")
                            var escaped = "'" + path + "' "
                            sessionModel.sendInput(escaped)
                        }
                    }
                    drop.accepted = true
                }
            }

            // Visual drop feedback overlay
            Rectangle {
                id: dropOverlay
                anchors.fill: parent
                visible: false
                color: "#1530D15820"
                border.color: "#30D158"
                border.width: 2
                radius: 4

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\u2193"
                        font.pixelSize: 32
                        color: "#30D158"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "Drop files into terminal"
                        font.pixelSize: 12
                        color: "#30D158"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
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

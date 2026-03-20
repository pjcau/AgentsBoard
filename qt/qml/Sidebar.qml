import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Rectangle {
    color: "#252525"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12

                Text {
                    text: "Sessions"
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "+"
                    flat: true
                    font.pixelSize: 18
                    onClicked: newSessionDialog.open()
                }
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#3D3D3D"
        }

        // Session list
        SessionList {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Select Working Directory"
        onAccepted: {
            // Convert file:///path to /path
            sessionWorkdirField.text = selectedFolder.toString().replace(/^file:\/\//, "")
        }
    }

    Dialog {
        id: newSessionDialog
        title: "New Session"
        anchors.centerIn: parent
        width: 400
        modal: true
        standardButtons: Dialog.Ok | Dialog.Cancel

        background: Rectangle {
            color: "#2D2D2D"
            border.color: "#555"
            radius: 8
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            Label {
                text: "Session Name"
                color: "#CCC"
                font.pixelSize: 12
            }
            TextField {
                id: sessionNameField
                Layout.fillWidth: true
                placeholderText: "e.g. claude-backend"
                color: "#FFF"
                font.pixelSize: 13
                background: Rectangle { color: "#1E1E1E"; radius: 4; border.color: "#555" }
            }

            Label {
                text: "Command"
                color: "#CCC"
                font.pixelSize: 12
            }
            TextField {
                id: sessionCommandField
                Layout.fillWidth: true
                placeholderText: "e.g. claude, codex, aider"
                text: "claude"
                color: "#FFF"
                font.pixelSize: 13
                background: Rectangle { color: "#1E1E1E"; radius: 4; border.color: "#555" }
            }

            Label {
                text: "Working Directory"
                color: "#CCC"
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                TextField {
                    id: sessionWorkdirField
                    Layout.fillWidth: true
                    placeholderText: "/home/user/project"
                    color: "#FFF"
                    font.pixelSize: 13
                    background: Rectangle { color: "#1E1E1E"; radius: 4; border.color: "#555" }
                }
                Button {
                    text: "Browse…"
                    onClicked: folderDialog.open()
                }
            }
        }

        onAccepted: {
            if (sessionCommandField.text.length > 0) {
                var sid = coreBridge.createSession(
                    sessionCommandField.text,
                    sessionNameField.text || sessionCommandField.text,
                    sessionWorkdirField.text
                )
                console.log("Created session:", sid)
            }
            sessionNameField.text = ""
            sessionCommandField.text = "claude"
            sessionWorkdirField.text = ""
        }
    }
}

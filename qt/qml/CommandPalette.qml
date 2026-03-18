import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: palette
    modal: true
    dim: true
    anchors.centerIn: parent
    width: 500
    height: 400

    background: Rectangle {
        color: "#2D2D2D"
        radius: 12
        border.color: "#3D3D3D"
        border.width: 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Search field
        TextField {
            id: searchField
            Layout.fillWidth: true
            placeholderText: "Type a command..."
            color: "#FFFFFF"
            font.pixelSize: 14
            background: Rectangle {
                color: "#1E1E1E"
                radius: 6
            }
            focus: true

            onTextChanged: {
                commandList.model = filterCommands(text)
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#3D3D3D"
        }

        // Command list
        ListView {
            id: commandList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: defaultCommands()
            currentIndex: 0

            delegate: Rectangle {
                width: commandList.width
                height: 44
                color: commandList.currentIndex === index ? "#007AFF" : "transparent"
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Text {
                        text: modelData.title
                        color: "#FFFFFF"
                        font.pixelSize: 14
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: modelData.shortcut || ""
                        color: "#8E8E93"
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        executeCommand(modelData.action)
                        palette.close()
                    }
                }
            }

            Keys.onUpPressed: {
                if (currentIndex > 0) currentIndex--
            }
            Keys.onDownPressed: {
                if (currentIndex < count - 1) currentIndex++
            }
            Keys.onReturnPressed: {
                if (currentIndex >= 0 && currentIndex < count) {
                    executeCommand(model[currentIndex].action)
                    palette.close()
                }
            }
        }
    }

    function defaultCommands() {
        return [
            { title: "New Session", shortcut: "Ctrl+N", action: "session.new" },
            { title: "Fleet Overview", shortcut: "Ctrl+Shift+F", action: "nav.fleet" },
            { title: "Activity Log", shortcut: "Ctrl+L", action: "nav.activity" },
            { title: "Cost Dashboard", shortcut: "", action: "nav.cost" },
            { title: "Settings", shortcut: "Ctrl+,", action: "nav.settings" },
        ]
    }

    function filterCommands(query) {
        if (!query || query.length === 0) return defaultCommands()
        var q = query.toLowerCase()
        return defaultCommands().filter(function(cmd) {
            return cmd.title.toLowerCase().indexOf(q) >= 0
        })
    }

    function executeCommand(action) {
        console.log("Command:", action)
        // TODO: Wire to CoreBridge actions
    }
}

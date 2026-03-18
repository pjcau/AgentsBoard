import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: "#1E1E1E"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header with stats
        RowLayout {
            Layout.fillWidth: true
            spacing: 24

            Text {
                text: "Fleet Overview"
                color: "#FFFFFF"
                font.pixelSize: 20
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            // Stats badges
            StatsLabel {
                label: "Active"
                value: coreBridge.activeCount
                color: "#30D158"
            }
            StatsLabel {
                label: "Needs Input"
                value: coreBridge.needsInputCount
                color: "#FF9F0A"
            }
            StatsLabel {
                label: "Errors"
                value: coreBridge.errorCount
                color: "#FF453A"
            }
            StatsLabel {
                label: "Total Cost"
                value: "$" + coreBridge.totalCost.toFixed(2)
                color: "#007AFF"
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#3D3D3D"
        }

        // Session cards grid
        GridView {
            id: gridView
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: fleetModel
            cellWidth: Math.max(350, width / Math.max(1, Math.floor(width / 400)))
            cellHeight: 200
            clip: true

            delegate: SessionCard {
                width: gridView.cellWidth - 12
                height: gridView.cellHeight - 12
                sessionId: model.sessionId
                sessionName: model.name
                sessionState: model.state
                sessionProvider: model.provider
                sessionCost: model.cost
                sessionProjectPath: model.projectPath
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                text: "No active agents.\nLaunch a session to get started."
                color: "#555555"
                font.pixelSize: 16
                horizontalAlignment: Text.AlignHCenter
                visible: gridView.count === 0
            }
        }
    }

    // Stats badge component
    component StatsLabel: RowLayout {
        property string label
        property var value
        property color color

        spacing: 6

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: parent.color
        }

        Text {
            text: parent.label + ": " + parent.value
            color: parent.color
            font.pixelSize: 13
        }
    }
}

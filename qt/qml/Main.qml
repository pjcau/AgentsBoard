import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    visible: true
    width: 1200
    height: 800
    minimumWidth: 800
    minimumHeight: 600
    title: "AgentsBoard — AI Agent Mission Control"
    color: "#1E1E1E"

    // Sidebar + Content layout
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Sidebar {
            Layout.preferredWidth: 240
            Layout.fillHeight: true
        }

        // Separator
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: "#3D3D3D"
        }

        // Main content
        FleetOverview {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    // Status bar
    footer: Rectangle {
        height: 28
        color: "#252525"

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            Text {
                text: "%1 sessions".arg(coreBridge.sessionCount)
                color: "#8E8E93"
                font.pixelSize: 12
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Needs Input: %1".arg(coreBridge.needsInputCount)
                color: coreBridge.needsInputCount > 0 ? "#FF9F0A" : "#8E8E93"
                font.pixelSize: 12
            }

            Text {
                text: "Errors: %1".arg(coreBridge.errorCount)
                color: coreBridge.errorCount > 0 ? "#FF453A" : "#8E8E93"
                font.pixelSize: 12
            }

            Text {
                text: "$%1".arg(coreBridge.totalCost.toFixed(2))
                color: "#30D158"
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                text: "v%1".arg(coreBridge.version)
                color: "#555"
                font.pixelSize: 11
            }
        }
    }
}

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    color: "#1E1E1E"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        Text {
            text: "Cost Dashboard"
            color: "#FFFFFF"
            font.pixelSize: 18
            font.bold: true
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#3D3D3D"
        }

        // Summary cards
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // Fleet total
            CostCard {
                Layout.fillWidth: true
                title: "Fleet Total"
                value: "$" + coreBridge.totalCost.toFixed(2)
                color: "#007AFF"
            }

            // Active sessions
            CostCard {
                Layout.fillWidth: true
                title: "Active Sessions"
                value: coreBridge.activeCount.toString()
                color: "#30D158"
            }

            // Needs Input
            CostCard {
                Layout.fillWidth: true
                title: "Needs Input"
                value: coreBridge.needsInputCount.toString()
                color: "#FF9F0A"
            }

            // Errors
            CostCard {
                Layout.fillWidth: true
                title: "Errors"
                value: coreBridge.errorCount.toString()
                color: "#FF453A"
            }
        }

        // Per-session cost list
        Text {
            text: "Cost per Session"
            color: "#FFFFFF"
            font.pixelSize: 14
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: fleetModel
            clip: true
            spacing: 4

            delegate: Rectangle {
                width: parent ? parent.width : 0
                height: 40
                color: "#2D2D2D"
                radius: 6

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12

                    Text {
                        text: model.name
                        color: "#FFFFFF"
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "$" + model.cost.toFixed(4)
                        color: "#30D158"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }
            }
        }
    }

    // Cost card component
    component CostCard: Rectangle {
        property string title
        property string value
        property color color

        height: 80
        radius: 8
        color: "#2D2D2D"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 4

            Text {
                text: parent.parent.title
                color: "#8E8E93"
                font.pixelSize: 11
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                text: parent.parent.value
                color: parent.parent.color
                font.pixelSize: 22
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}

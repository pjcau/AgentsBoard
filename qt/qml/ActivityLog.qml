import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: activityPanel
    color: "#1E1E1E"

    property string sessionFilter: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Activity Log"
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: sessionFilter.length > 0 ? "Filtered" : "All sessions"
                color: "#8E8E93"
                font.pixelSize: 12
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#3D3D3D"
        }

        // Events list
        ListView {
            id: activityList
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: activityModel
            clip: true
            spacing: 2

            delegate: Rectangle {
                width: activityList.width
                height: 48
                color: mouseArea.containsMouse ? "#2D2D2D" : "transparent"
                radius: 4

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 12

                    // Event type icon
                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: {
                            switch (model.eventType) {
                                case "fileChanged": return "#007AFF"
                                case "commandRun": return "#30D158"
                                case "error": return "#FF453A"
                                case "costDelta": return "#FF9F0A"
                                case "stateChange": return "#BF5AF2"
                                default: return "#8E8E93"
                            }
                        }
                    }

                    // Details
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: model.details || ""
                            color: "#FFFFFF"
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: {
                                var d = new Date(model.timestamp * 1000);
                                return d.toLocaleTimeString();
                            }
                            color: "#555555"
                            font.pixelSize: 11
                        }
                    }

                    // Cost badge
                    Text {
                        visible: model.cost > 0
                        text: "$" + model.cost.toFixed(4)
                        color: "#FF9F0A"
                        font.pixelSize: 11
                    }
                }
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                text: "No activity events yet."
                color: "#555555"
                font.pixelSize: 14
                visible: activityList.count === 0
            }
        }
    }
}

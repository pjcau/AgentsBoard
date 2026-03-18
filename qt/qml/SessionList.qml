import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ListView {
    id: sessionListView
    model: fleetModel
    clip: true

    delegate: Rectangle {
        width: sessionListView.width
        height: 56
        color: mouseArea.containsMouse ? "#333333" : "transparent"

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                sessionModel.sessionId = model.sessionId
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            // State indicator
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: {
                    switch (model.state) {
                        case 0: return "#30D158"   // working — green
                        case 1: return "#FF9F0A"   // needsInput — orange
                        case 2: return "#FF453A"   // error — red
                        default: return "#555555"   // inactive — gray
                    }
                }
            }

            // Name and path
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: model.name
                    color: "#FFFFFF"
                    font.pixelSize: 13
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: model.projectPath || ""
                    color: "#8E8E93"
                    font.pixelSize: 11
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                    visible: text.length > 0
                }
            }

            // Cost
            Text {
                text: "$" + model.cost.toFixed(2)
                color: "#8E8E93"
                font.pixelSize: 11
            }
        }

        // Bottom border
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#2D2D2D"
        }
    }

    // Empty state
    Text {
        anchors.centerIn: parent
        text: "No sessions.\nClick + to create one."
        color: "#555555"
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        visible: sessionListView.count === 0
    }
}

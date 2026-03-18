import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
                    onClicked: {
                        // TODO: Open new session dialog
                    }
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
}

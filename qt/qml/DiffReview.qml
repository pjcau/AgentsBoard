import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: diffPanel
    color: "#1E1E1E"

    property string sessionId: ""
    property string filePath: ""
    property var hunks: []  // Array of {oldStart, oldLines, newStart, newLines, lines: [{type, text}]}

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Diff Review"
                color: "#FFFFFF"
                font.pixelSize: 18
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: filePath
                color: "#8E8E93"
                font.pixelSize: 12
                font.family: "monospace"
            }
        }

        // Separator
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#3D3D3D"
        }

        // Diff content
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: diffList
                model: hunks.length > 0 ? hunks[0].lines : sampleDiff()
                clip: true

                delegate: Rectangle {
                    width: diffList.width
                    height: 24
                    color: {
                        if (modelData.type === "+") return "#0D2818"
                        if (modelData.type === "-") return "#2D0F0F"
                        return "transparent"
                    }

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Line type indicator
                        Text {
                            Layout.preferredWidth: 20
                            text: modelData.type || " "
                            color: {
                                if (modelData.type === "+") return "#30D158"
                                if (modelData.type === "-") return "#FF453A"
                                return "#555555"
                            }
                            font.pixelSize: 12
                            font.family: "monospace"
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // Content
                        Text {
                            Layout.fillWidth: true
                            text: modelData.text || ""
                            color: "#E0E0E0"
                            font.pixelSize: 12
                            font.family: "monospace"
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        // Action buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item { Layout.fillWidth: true }

            Button {
                text: "Reject"
                palette.buttonText: "#FF453A"
                onClicked: {
                    console.log("Diff rejected for", filePath)
                }
            }

            Button {
                text: "Approve"
                palette.buttonText: "#30D158"
                onClicked: {
                    console.log("Diff approved for", filePath)
                }
            }
        }
    }

    function sampleDiff() {
        return [
            { type: " ", text: "func calculate() {" },
            { type: "-", text: "    let result = oldMethod()" },
            { type: "+", text: "    let result = newMethod()" },
            { type: " ", text: "    return result" },
            { type: " ", text: "}" },
        ]
    }
}

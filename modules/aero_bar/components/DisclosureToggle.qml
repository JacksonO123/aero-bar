import QtQuick

// Win7's round chevron button with a label ("Show details" / "Hide details"); the whole row
// toggles `open`.
Item {
    id: root

    property bool open: false
    property string openText: ""
    property string closedText: ""

    implicitWidth: row.width
    implicitHeight: 22

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Rectangle {
            width: 18
            height: 18
            radius: 9
            border.width: 1
            border.color: mouse.containsMouse ? "#3c7fb1" : "#9a9a9a"
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#ffffff"
                }
                GradientStop {
                    position: 1
                    color: mouse.containsMouse ? "#cfe6f8" : "#d8d8d8"
                }
            }

            MediaGlyph {
                anchors.centerIn: parent
                width: 6
                height: 8
                kind: "play"
                color: "#4a4a4a"
                shadow: false
                rotation: root.open ? -90 : 90

                Behavior on rotation {
                    NumberAnimation {
                        duration: 150
                    }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.open ? root.openText : root.closedText
            color: mouse.containsMouse ? "#3399ff" : "#1e3c78"
            font.pixelSize: 12
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }
}

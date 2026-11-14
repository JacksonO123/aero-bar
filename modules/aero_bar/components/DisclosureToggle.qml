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

    readonly property alias hoverT: hp.hoverT
    readonly property alias pressedT: hp.pressedT

    HoverPress {
        id: hp
        hovered: mouse.containsMouse
        pressed: mouse.pressed
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Rectangle {
            width: 18
            height: 18
            radius: 9
            border.width: 1
            border.color: hp.shade("#9a9a9a", "#3c7fb1", "#2c628b")
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#ffffff"
                }
                GradientStop {
                    position: 1
                    color: hp.shade("#d8d8d8", "#cfe6f8", "#a9d3f2")
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
            color: hp.shade("#1e3c78", "#3399ff", "#1c5ea8")
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

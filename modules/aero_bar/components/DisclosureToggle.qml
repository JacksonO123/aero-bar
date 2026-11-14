import QtQuick
import "../../../utils/colors.js" as ColorUtils

// Win7's round chevron button with a label ("Show details" / "Hide details"); the whole row
// toggles `open`.
Item {
    id: root

    property bool open: false
    property string openText: ""
    property string closedText: ""

    implicitWidth: row.width
    implicitHeight: 22

    property real hoverT: mouse.containsMouse ? 1 : 0
    property real pressedT: mouse.pressed ? 1 : 0

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    Behavior on pressedT {
        NumberAnimation {
            duration: 80
            easing.type: Easing.OutQuad
        }
    }

    // a colour at rest, under the pointer and pressed
    function shade(rest, hot, pressed) {
        return ColorUtils.interpolateColors(ColorUtils.interpolateColors(rest, hot, hoverT), pressed, pressedT);
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
            border.color: root.shade("#9a9a9a", "#3c7fb1", "#2c628b")
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#ffffff"
                }
                GradientStop {
                    position: 1
                    color: root.shade("#d8d8d8", "#cfe6f8", "#a9d3f2")
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
            color: root.shade("#1e3c78", "#3399ff", "#1c5ea8")
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

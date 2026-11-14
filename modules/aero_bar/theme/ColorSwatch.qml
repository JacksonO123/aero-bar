import QtQuick
import "../components"

// One colour tile in the picker: the colour behind a glossy glass face, with Win7's blue
// selection frame when it is the current colour.
Item {
    id: root

    property color color: "#6b74b8fc"
    property bool selected: false

    signal clicked

    implicitWidth: 52
    implicitHeight: 52

    // selection / hover highlight
    RowHighlight {
        anchors.fill: parent
        radius: 4
        hot: mouse.containsMouse
        selected: root.selected
        hotColor: "#eef6fd"
    }

    Rectangle {
        id: tile
        anchors.fill: parent
        anchors.margins: 6
        radius: 3
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.55)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#f6f6f6"
            }
            GradientStop {
                position: 1
                color: "#bfc3c7"
            }
        }

        // the colour, a little stronger than its glass so pale ones still read
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 2
            color: Qt.rgba(root.color.r, root.color.g, root.color.b, Math.min(1, root.color.a * 1.7))
        }

        // gloss
        Rectangle {
            x: 1
            y: 1
            width: parent.width - 2
            height: parent.height * 0.48
            radius: 2
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.rgba(1, 1, 1, 0.65)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(1, 1, 1, 0.15)
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.45)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}

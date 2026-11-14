import QtQuick

// One picture in a picker's grid (Desktop Background, Change Your Picture): a framed thumbnail
// with a soft shadow and a touch of gloss, hot-tracking under the pointer, with Win7's blue
// selection and a ticked box when it's the chosen one. Size it to the grid's cells.
Item {
    id: root

    property string path: ""
    property bool selected: false

    signal clicked
    signal doubleClicked

    RowHighlight {
        anchors.fill: parent
        anchors.margins: 1
        glass: true
        hot: mouse.containsMouse
        selected: root.selected
    }

    // a soft shadow under the frame
    component Shadow: Rectangle {
        property real offset: 1
        x: 8
        y: 8 + offset
        width: parent.width - 16
        height: parent.height - 16
    }

    Shadow {
        offset: 2
        color: Qt.rgba(0, 0.05, 0.12, 0.06)
    }

    Shadow {
        offset: 1
        color: Qt.rgba(0, 0.05, 0.12, 0.14)
    }

    // the thumbnail, in a thin frame
    Rectangle {
        id: frame
        x: 8
        y: 8
        width: parent.width - 16
        height: parent.height - 16
        color: "#e9edf1"
        border.width: 1
        border.color: "#a3acb6"

        Image {
            id: picture
            anchors.fill: parent
            anchors.margins: 2
            source: root.path !== "" ? "file://" + root.path : ""
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            opacity: status === Image.Ready ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }
        }

        // a light two-tone gloss over the top of the picture
        Rectangle {
            x: picture.x
            y: picture.y
            width: picture.width
            height: picture.height * 0.46
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.rgba(1, 1, 1, 0.22)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(1, 1, 1, 0.05)
                }
            }
        }

        // a faint inner highlight over the picture's edge
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.6)
        }
    }

    // the tick, only on the chosen picture (only built there)
    Loader {
        x: 3
        y: 3
        active: root.selected

        sourceComponent: CheckBox {
            checked: true
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }
}

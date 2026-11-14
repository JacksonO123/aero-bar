import QtQuick
import "../components"

// One picture in the Desktop Background picker: a framed thumbnail that hot-tracks under the
// pointer, with Win7's blue selection and a ticked box when it's the chosen one.
Item {
    id: root

    property string path: ""
    property bool selected: false

    signal clicked

    implicitWidth: 166
    implicitHeight: 118

    RowHighlight {
        anchors.fill: parent
        anchors.margins: 1
        hot: mouse.containsMouse
        selected: root.selected
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

        // a faint inner highlight over the picture's edge
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.6)
        }
    }

    CheckBox {
        x: 3
        y: 3
        visible: root.selected
        checked: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}

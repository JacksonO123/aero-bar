import QtQuick

// The white list box of a picture picker (Desktop Background, Change Your Picture): PictureTiles
// `columns` wide with the slim scroll thumb. Add an empty-state message as a child.
Rectangle {
    id: root

    property var images: []
    // the picture shown as the chosen one
    property string selected: ""
    property int columns: 4
    property alias cellWidth: grid.cellWidth
    property alias cellHeight: grid.cellHeight

    // a picture was clicked, or double-clicked
    signal picked(string path)
    signal chosen(string path)

    // the grid, its inset, and room for the scroll thumb
    implicitWidth: grid.width + 22
    radius: 3
    border.width: 1
    border.color: "#9fb4ca"
    // white, with a faint inset along the top like a Win7 text box
    gradient: Gradient {
        GradientStop {
            position: 0
            color: "#eef3f8"
        }
        GradientStop {
            position: 0.03
            color: "#ffffff"
        }
    }

    GridView {
        id: grid
        x: 6
        y: 6
        width: cellWidth * root.columns
        height: parent.height - 12
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.images

        delegate: PictureTile {
            required property string modelData
            width: grid.cellWidth
            height: grid.cellHeight
            path: modelData
            selected: modelData === root.selected
            onClicked: root.picked(modelData)
            onDoubleClicked: root.chosen(modelData)
        }
    }

    ScrollThumb {
        anchors.right: parent.right
        anchors.rightMargin: 3
        flickable: grid
    }
}

import QtQuick
import "../components"

// Start menu entry on the white panel: icon + label, Win7 blue hot-track when hovered or selected.
Item {
    id: root

    property string label: ""
    property string sublabel: ""
    property string iconName: ""
    property string wmClass: ""
    property real iconSize: 32
    property real indent: 0
    property bool selected: false
    property bool bold: false
    property bool showArrow: false
    property bool arrowDown: false
    readonly property bool hot: mouse.containsMouse || selected

    signal activated

    implicitHeight: Math.max(iconSize + 8, 24)

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: 3
        border.width: 1
        border.color: "#7da2ce"
        opacity: root.hot ? 1 : 0

        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#ebf3fd"
            }
            GradientStop {
                position: 1
                color: "#cfe3fb"
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 90
            }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.7)
        }
    }

    ImageIcon {
        id: icon
        x: 6 + root.indent
        anchors.verticalCenter: parent.verticalCenter
        visible: root.iconSize > 0
        size: root.iconSize
        wmClass: root.wmClass
        desktopIcon: root.iconName
    }

    Column {
        x: (root.iconSize > 0 ? icon.x + root.iconSize + 8 : 10 + root.indent)
        width: root.width - x - (root.showArrow ? 22 : 8)
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: root.label
            elide: Text.ElideRight
            color: "#1a1a1a"
            font.pixelSize: 12
            font.bold: root.bold
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: root.sublabel
            elide: Text.ElideRight
            color: "#6d6d6d"
            font.pixelSize: 10
        }
    }

    MediaGlyph {
        visible: root.showArrow
        anchors.right: parent.right
        anchors.rightMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 8
        kind: "play"
        rotation: root.arrowDown ? 90 : 0
        color: "#3c3c3c"
        shadow: false

        Behavior on rotation {
            NumberAnimation {
                duration: 150
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}

import QtQuick
import "../../../utils/constants.js" as Constants

Rectangle {
    id: root
    signal clicked
    property bool active: false

    property real padding: 2
    implicitHeight: Constants.BAR_HEIGHT - padding * 2
    implicitWidth: implicitHeight
    anchors.verticalCenter: parent.verticalCenter
    width: height
    radius: height / 2
    color: "transparent"

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
            duration: 90
            easing.type: Easing.OutQuad
        }
    }

    Image {
        anchors.fill: root
        source: Qt.resolvedUrl("../../../assets/arch-orb.png")
        sourceSize: Qt.size(width * 2, height * 2)
        scale: 1 - (0.07 * root.pressedT)
    }

    Image {
        anchors.fill: root
        source: Qt.resolvedUrl("../../../assets/arch-orb-bright.png")
        sourceSize: Qt.size(width * 2, height * 2)
        opacity: Math.max(root.hoverT, root.active ? 1 : 0)
        scale: 1 - (0.07 * root.pressedT)
    }

    MouseArea {
        id: mouse
        anchors.fill: root
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()

        containmentMask: QtObject {
            function contains(point: point): bool {
                const r = root.width / 2;
                const dx = point.x - r;
                const dy = point.y - r;
                return dx * dx + dy * dy <= r * r;
            }
        }
    }
}

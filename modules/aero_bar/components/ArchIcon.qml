import QtQuick
import "../../../utils/constants.js" as Constants

Rectangle {
    id: root
    signal clicked

    property real padding: 2
    implicitHeight: Constants.BAR_HEIGHT - padding * 2
    implicitWidth: implicitHeight
    anchors.verticalCenter: parent.verticalCenter
    width: height
    radius: height / 2
    color: "transparent"

    property real hoverT: mouse.reallyContainsMouse ? 1 : 0
    property real pressedT: mouse.pressed ? 1 : 0

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0, 1.0, 1.0]
        }
    }

    Behavior on pressedT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.BezierSpline
            easing.bezierCurve: [0.25, 0.1, 0.25, 1.0, 1.0, 1.0]
        }
    }

    Image {
        id: image
        anchors.fill: root
        source: Qt.resolvedUrl("../../../assets/arch-orb.png")
        sourceSize: Qt.size(width * 2, height * 2)
        scale: 1 - (0.07 * root.pressedT)
    }

    Image {
        id: imageBright
        anchors.fill: root
        source: Qt.resolvedUrl("../../../assets/arch-orb-bright.png")
        sourceSize: Qt.size(width * 2, height * 2)
        opacity: root.hoverT
        scale: 1 - (0.07 * root.pressedT)
    }

    MouseArea {
        id: mouse
        anchors.fill: root
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()

        function isInsideCircle(mx, my) {
            var dx = mx - (root.width / 2);
            var dy = my - (root.height / 2);
            var r = root.width / 2;
            return (dx * dx + dy * dy) <= (r * r);
        }

        property bool reallyContainsMouse: {
            if (!containsMouse)
                return false;
            let pt = mapToItem(root, mouseX, mouseY);
            let dx = pt.x - (root.width / 2);
            let dy = pt.y - (root.height / 2);
            let r = root.width / 2;
            return (dx * dx + dy * dy) <= (r * r);
        }
    }
}

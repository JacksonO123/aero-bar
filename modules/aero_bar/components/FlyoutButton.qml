import QtQuick
import "../flyout"

Win7Frame {
    id: root

    required property Flyout flyoutEl
    readonly property bool active: flyoutEl.pinned && flyoutEl.current === root
    property var rightClick: null

    implicitWidth: 30
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 4
    anchors.bottomMargin: 4
    frameOpacity: Math.max(hoverT, active ? 1 : 0)

    onClicked: mouse => mouse.button === Qt.RightButton && rightClick ? rightClick() : flyoutEl.toggle(root)

    Win7Hover {
        radius: root.radius
        opacity: Math.max(root.hoverT, root.active ? 0.8 : 0)
        pressedT: root.pressedT
    }
}

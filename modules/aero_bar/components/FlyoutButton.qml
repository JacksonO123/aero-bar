import QtQuick
import "../flyout"

// A 30px taskbar button that pins its flyout pane open on click (Action Center, network,
// Bluetooth) and stays lit while that pane is showing. With `ownRightClick`, right-click emits
// `rightClicked` instead of toggling.
Win7Frame {
    id: root

    required property Flyout flyoutEl
    readonly property bool active: flyoutEl.pinned && flyoutEl.current === root
    property bool ownRightClick: false

    signal rightClicked

    implicitWidth: 30
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 4
    anchors.bottomMargin: 4
    frameOpacity: Math.max(hoverT, active ? 1 : 0)

    onClicked: mouse => mouse.button === Qt.RightButton && ownRightClick ? root.rightClicked() : flyoutEl.toggle(root)

    Win7Hover {
        radius: root.radius
        opacity: Math.max(root.hoverT, root.active ? 0.8 : 0)
        pressedT: root.pressedT
    }
}

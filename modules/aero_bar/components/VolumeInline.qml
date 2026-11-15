import QtQuick
import Quickshell
import "../flyout"
import "../../../services"
import "../../../utils/constants.js" as Constants

Win7Frame {
    id: root

    required property Flyout flyoutEl

    implicitWidth: 30
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 4
    anchors.bottomMargin: 4
    frameOpacity: hoverT

    onHoveredChanged: hovered ? flyoutEl.hover(root) : flyoutEl.unhover()

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            if (flyoutEl.current && flyoutEl.current !== root) {
                flyoutEl.close();
            }
            Audio.toggleMute();
        } else if (mouse.button === Qt.MiddleButton) {
            if (flyoutEl.current && flyoutEl.current !== root) {
                flyoutEl.close();
            }
            Quickshell.execDetached(Constants.VOLUME_MIXER_CMD);
        } else {
            if (flyoutEl.current && flyoutEl.current !== root) {
                flyoutEl.close();
            }
            flyoutEl.toggle(root);
        }
    }

    Win7Hover {
        radius: root.radius
        opacity: root.hoverT
        pressedT: root.pressedT
    }

    SpeakerGlyph {
        anchors.centerIn: parent
        width: 21
        height: 19
        level: Audio.volume
        muted: Audio.muted
    }

    WheelHandler {
        onWheel: event => Audio.adjust(event.angleDelta.y / 120 * 0.02)
    }
}

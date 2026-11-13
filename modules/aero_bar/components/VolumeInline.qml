import QtQuick
import Quickshell
import "../flyout"
import "../../../services"
import "../../../utils/constants.js" as Constants

// Speaker icon. Hover for the volume flyout, scroll to change volume,
// left click to mute, right click to open the mixer.
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
            Quickshell.execDetached(Constants.VOLUME_MIXER_CMD);
        } else if (mouse.button === Qt.LeftButton) {
            Audio.toggleMute();
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

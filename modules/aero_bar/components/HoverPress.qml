import QtQuick
import "../../../utils/colors.js" as ColorUtils

QtObject {
    id: root

    property bool hovered: false
    property bool pressed: false
    property int hoverDuration: 150

    property real hoverT: hovered ? 1 : 0
    property real pressedT: pressed ? 1 : 0

    function shade(rest, hot, pressedColor) {
        return ColorUtils.interpolateColors(ColorUtils.interpolateColors(rest, hot, hoverT), pressedColor, pressedT);
    }

    Behavior on hoverT {
        NumberAnimation {
            duration: root.hoverDuration
            easing.type: Easing.OutQuad
        }
    }

    Behavior on pressedT {
        NumberAnimation {
            duration: 80
            easing.type: Easing.OutQuad
        }
    }
}

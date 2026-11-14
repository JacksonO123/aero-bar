import QtQuick
import "../../../utils/colors.js" as ColorUtils

// The shell's hover / press fade: `hoverT` and `pressedT` ease between 0 and 1 as `hovered` and
// `pressed` change (Win7's timing: 150 ms for hover, 80 ms for a press), and `shade()` blends a
// colour through both.
QtObject {
    id: root

    property bool hovered: false
    property bool pressed: false
    property int hoverDuration: 150

    property real hoverT: hovered ? 1 : 0
    property real pressedT: pressed ? 1 : 0

    // the colour at rest, under the pointer, and pressed
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

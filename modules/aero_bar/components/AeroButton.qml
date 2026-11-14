import QtQuick
import "../../../utils/colors.js" as ColorUtils

// The Frutiger Aero action button, for a page's main action (Save changes, Change Picture): a
// glossy aqua capsule in a soft halo that breathes while it waits, brightening under the pointer
// with a shine sweeping across it, and white lettering.
Item {
    id: root

    property alias text: label.text

    signal clicked

    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed && mouse.containsMouse

    readonly property alias hoverT: hp.hoverT
    readonly property alias pressedT: hp.pressedT
    property real breath: 0

    HoverPress {
        id: hp
        hovered: root.hovered
        pressed: root.pressed
    }

    implicitWidth: Math.max(116, label.implicitWidth + 48)
    implicitHeight: 30
    opacity: enabled ? 1 : 0.5

    onHoveredChanged: {
        if (hovered && enabled) {
            sweep.restart();
        }
    }

    // (dialogs stay loaded while hidden: only breathe while the window is up)
    SequentialAnimation on breath {
        running: root.enabled && root.visible && (root.Window.window?.visible ?? false) && !root.hovered
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
            to: 1
            duration: 1600
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 0
            duration: 1600
            easing.type: Easing.InOutSine
        }
    }

    // ---- the halo ------------------------------------------------------------------------------

    SoftGlow {
        anchors.fill: parent
        radius: height / 2
        color: "#3cc4ff"
        spread: 10
        grow: 2
        opacity: root.enabled ? 0.45 + root.breath * 0.25 + root.hoverT * 0.3 : 0
    }

    // ---- the capsule ---------------------------------------------------------------------------

    // aqua glass, brighter under the pointer, deeper while pressed
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        gradient: SplitGradient {
            colors: {
                const rest = ["#8ddfff", "#2aa9ef", "#0680d1", "#2fbcf3"];
                const hot = ["#b0edff", "#4cc6ff", "#1199e8", "#5ad6ff"];
                const press = ["#62c3ee", "#1787cf", "#045f9f", "#1b96d6"];
                const shade = i => ColorUtils.interpolateColors(ColorUtils.interpolateColors(rest[i], hot[i], root.hoverT), press[i], root.pressedT);
                return [shade(0), shade(1), shade(2), shade(3)];
            }
        }
    }

    // light caught along the bottom of the glass
    Rectangle {
        x: root.height * 0.4
        y: root.height * 0.5
        width: root.width - x * 2
        height: root.height * 0.46
        radius: height / 2
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(0.6, 0.93, 1, 0)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(0.7, 0.96, 1, 0.65 - root.pressedT * 0.35)
            }
        }
    }

    // the gloss: a smaller capsule over the top half
    Rectangle {
        x: 3
        y: 1.5
        width: root.width - 6
        height: root.height * 0.47
        radius: height / 2
        gradient: Gradient {
            GradientStop {
                position: 0
                color: Qt.rgba(1, 1, 1, 0.88 - root.pressedT * 0.3)
            }
            GradientStop {
                position: 1
                color: Qt.rgba(1, 1, 1, 0.2)
            }
        }
    }

    // a shine that sweeps across as the pointer arrives (kept off the rounded ends)
    Item {
        id: shineArea
        x: root.height * 0.35
        y: 2
        width: root.width - x * 2
        height: root.height - 4
        clip: true

        Rectangle {
            id: shine
            x: -width * 2
            y: -root.height
            width: 14
            height: root.height * 3
            rotation: 24
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: Qt.rgba(1, 1, 1, 0)
                }
                GradientStop {
                    position: 0.5
                    color: Qt.rgba(1, 1, 1, 0.6)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(1, 1, 1, 0)
                }
            }
        }

        NumberAnimation {
            id: sweep
            target: shine
            property: "x"
            from: -shine.width * 2
            to: shineArea.width + shine.width
            duration: 700
            easing.type: Easing.InOutQuad
        }
    }

    Bevel {
        anchors.fill: parent
        radius: height / 2
        outerColor: ColorUtils.interpolateColors("#0a5d9c", "#064577", root.pressedT)
        innerColor: Qt.rgba(1, 1, 1, 0.5 - root.pressedT * 0.3)
        outlineOnTop: true
    }

    // ---- the lettering -------------------------------------------------------------------------

    Text {
        anchors.centerIn: label
        anchors.verticalCenterOffset: 1
        text: label.text
        font: label.font
        color: Qt.rgba(0, 0.2, 0.42, 0.6)
    }

    Text {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.pressed ? 1 : 0
        color: "white"
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

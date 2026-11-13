import QtQuick

// Recessed glass groove with an aqua fill; the knob is a glass orb that shows the value.
Item {
    id: root

    property real value: 0
    property real maximum: 1
    property bool muted: false
    property real knobSize: 30
    property real trackHeight: 8
    property real wheelStep: 0.02

    signal moved(real value)

    property bool dragging: false
    property real dragValue: 0
    property bool glide: false

    readonly property real shownValue: dragging ? dragValue : value
    readonly property real ratio: maximum > 0 ? Math.max(0, Math.min(1, shownValue / maximum)) : 0
    readonly property real travel: Math.max(0, width - knobSize)
    readonly property int percent: Math.round(shownValue * 100)

    implicitWidth: 220
    implicitHeight: knobSize + 6

    function valueAt(x) {
        return Math.max(0, Math.min(maximum, (x - knobSize / 2) / Math.max(1, travel) * maximum));
    }

    Rectangle {
        id: groove
        x: root.knobSize / 2 - root.trackHeight / 2
        width: root.width - root.knobSize + root.trackHeight
        height: root.trackHeight
        anchors.verticalCenter: parent.verticalCenter
        radius: height / 2
        border.width: 1
        border.color: "#8593a1"

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: "#a7b2bd"
            }
            GradientStop {
                position: 0.45
                color: "#d3d9df"
            }
            GradientStop {
                position: 1.0
                color: "#f4f6f8"
            }
        }
    }

    Item {
        id: fill
        x: groove.x + 1
        y: groove.y + 1
        height: groove.height - 2
        width: Math.max(0, knob.x + root.knobSize / 2 - x)
        clip: true

        Rectangle {
            width: groove.width - 2
            height: parent.height
            radius: height / 2

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: root.muted ? "#eceff1" : "#d6f7ff"
                }
                GradientStop {
                    position: 0.5
                    color: root.muted ? "#bcc2c8" : "#62d0f8"
                }
                GradientStop {
                    position: 0.51
                    color: root.muted ? "#9aa1a8" : "#1898e0"
                }
                GradientStop {
                    position: 1.0
                    color: root.muted ? "#b5bbc1" : "#4ec2f3"
                }
            }
        }
    }

    GlassOrb {
        id: knob
        size: root.knobSize
        x: root.ratio * root.travel
        anchors.verticalCenter: parent.verticalCenter
        hoverT: mouse.containsMouse ? 1 : 0
        pressedT: root.dragging ? 1 : 0
        scale: root.dragging ? 1.12 : (mouse.containsMouse ? 1.04 : 1)

        lightColor: root.muted ? "#f4f6f8" : "#a6f2ff"
        baseColor: root.muted ? "#98a2ac" : "#1f7ad8"
        darkColor: root.muted ? "#3a424b" : "#06215a"

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutBack
            }
        }

        Behavior on x {
            enabled: !root.dragging || root.glide
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 0.5
            text: root.percent
            color: "white"
            font.pixelSize: Math.round(root.knobSize * (root.percent >= 100 ? 0.33 : 0.38))
            font.bold: true
            style: Text.Outline
            styleColor: Qt.rgba(0, 0.07, 0.2, 0.55)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        property real grabOffset: 0

        onPressed: mouse => {
            const knobCenter = knob.x + root.knobSize / 2;
            if (Math.abs(mouse.x - knobCenter) <= root.knobSize / 2) {
                grabOffset = mouse.x - knobCenter;
                root.glide = false;
            } else {
                // clicked the groove: let the knob glide over before it starts tracking
                grabOffset = 0;
                root.glide = true;
                glideTimer.restart();
            }

            root.dragValue = root.valueAt(mouse.x - grabOffset);
            root.dragging = true;
            root.moved(root.dragValue);
        }

        onPositionChanged: mouse => {
            if (!root.dragging) {
                return;
            }
            root.dragValue = root.valueAt(mouse.x - grabOffset);
            root.moved(root.dragValue);
        }

        onReleased: root.dragging = false
        onCanceled: root.dragging = false

        onWheel: wheel => {
            const steps = wheel.angleDelta.y / 120;
            // a value already above `maximum` (set elsewhere) can still be scrolled down, not cut
            root.moved(Math.max(0, Math.min(Math.max(root.maximum, root.value), root.value + steps * root.wheelStep)));
        }
    }

    Timer {
        id: glideTimer
        interval: 170
        onTriggered: root.glide = false
    }
}

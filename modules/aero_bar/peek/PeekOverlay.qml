import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "../../../services"

// Aero Peek: on the peeked window's monitor, everything but that window turns into frosted glass
// with faint outlines where the other windows are, and the window itself is shown live on top.
// The taskbar stays usable (the overlay keeps out of its exclusive zone and takes no input).
// For real frosted glass add a blur layer rule for the "aero-peek" namespace.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property var client: Peek.address !== "" ? HyprState.clients.find(c => Taskbar.sameAddress(c.address, Peek.address)) ?? null : null
        readonly property var monitor: HyprState.monitors.find(m => m.name === modelData.name) ?? null
        readonly property bool wanted: client !== null && monitor !== null && client.monitorId === monitor.id
        // the overlay starts at the work area's corner, so window positions shift by the
        // reserved space on the left / top
        readonly property real originX: (monitor?.x ?? 0) + (monitor?.reserved?.[0] ?? 0)
        readonly property real originY: (monitor?.y ?? 0) + (monitor?.reserved?.[1] ?? 0)
        readonly property var toplevel: Peek.toplevel

        // the thumbnail flyout, cut out of the veil while it shows (a flyout on another screen
        // simply lands outside this window)
        readonly property bool hasHole: Peek.clearRect.width > 0 && veil.opacity > 0
        readonly property rect hole: Qt.rect(Peek.clearRect.x - originX, Peek.clearRect.y - originY, Peek.clearRect.width, Peek.clearRect.height)

        visible: wanted || veil.opacity > 0.01
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Normal
        color: "transparent"
        mask: Region {}

        WlrLayershell.namespace: "aero-peek"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: veil
            anchors.fill: parent
            opacity: window.wanted ? 1 : 0

            // cut the flyout's shape out, so the thumbnails stay in front
            layer.enabled: window.hasHole
            layer.effect: MultiEffect {
                maskEnabled: true
                maskInverted: true
                maskSource: holeMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Theme.tint.r * 0.25, Theme.tint.g * 0.25, Theme.tint.b * 0.3, 0.6)
            }

            // the other windows on screen, as glass sheets
            Repeater {
                model: window.wanted ? HyprState.clients.filter(c => c.monitorId === window.monitor.id && c.wsId === window.monitor.activeWorkspaceId && !Taskbar.sameAddress(c.address, Peek.address)) : []

                Rectangle {
                    required property var modelData
                    x: modelData.x - window.originX
                    y: modelData.y - window.originY
                    width: modelData.w
                    height: modelData.h
                    radius: 6
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.45)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 5
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.25)
                    }

                    Rectangle {
                        x: 1
                        y: 1
                        width: parent.width - 2
                        height: Math.min(28, parent.height * 0.3)
                        radius: 5
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.rgba(1, 1, 1, 0.16)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.rgba(1, 1, 1, 0)
                            }
                        }
                    }
                }
            }

            // the peeked window, live
            Item {
                visible: window.client !== null
                x: (window.client?.x ?? 0) - window.originX
                y: (window.client?.y ?? 0) - window.originY
                width: window.client?.w ?? 0
                height: window.client?.h ?? 0

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    radius: 7
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.5)
                }

                ScreencopyView {
                    anchors.fill: parent
                    captureSource: window.wanted ? window.toplevel?.wayland ?? null : null
                    live: true
                }
            }
        }

        Item {
            id: holeMask
            anchors.fill: parent
            visible: false
            layer.enabled: window.hasHole

            Rectangle {
                x: window.hole.x
                y: window.hole.y
                width: window.hole.width
                height: window.hole.height
                radius: 7
            }
        }
    }
}

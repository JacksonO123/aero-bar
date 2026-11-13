import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../../../services"

// Win7's Flip 3D: the windows stand in a tilted stack that recedes up and to the right; Tab /
// the wheel flips the front one to the back. Click one to switch to it.
Item {
    id: root

    readonly property int count: Switcher.windows.length
    readonly property real cardW: width * 0.5
    readonly property real cardH: height * 0.5

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0.02, 0.06, 0.62)
    }

    WheelHandler {
        onWheel: event => Switcher.step(event.angleDelta.y < 0 ? 1 : -1)
    }

    Repeater {
        model: Switcher.windows

        Item {
            id: card

            required property var modelData
            required property int index

            // 0 = front (selected), then further back
            readonly property int slot: (index - Switcher.index + root.count) % root.count
            readonly property real depth: Math.min(slot, 7)

            width: root.cardW
            height: root.cardH
            x: root.width * 0.2 + depth * root.width * 0.055
            y: root.height * 0.33 - depth * root.height * 0.055
            z: -slot
            scale: 1 - depth * 0.07
            opacity: slot > 7 ? 0 : 1 - depth * 0.08
            transformOrigin: Item.Left

            transform: Rotation {
                origin.x: 0
                origin.y: card.height / 2
                axis {
                    x: 0
                    y: 1
                    z: 0
                }
                angle: 32
            }

            Behavior on x {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                }
            }

            ScreencopyView {
                id: shot
                anchors.centerIn: parent
                captureSource: card.slot < 8 ? card.modelData.wayland : null
                live: card.slot < 3
                constraintSize: Qt.size(card.width, card.height)
                width: implicitWidth
                height: implicitHeight

                // glass edge
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -1
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.5)
                }
            }

            Rectangle {
                anchors.fill: parent
                visible: !shot.hasContent
                radius: 6
                color: Qt.rgba(0.85, 0.9, 0.95, 0.9)

                ImageIcon {
                    anchors.centerIn: parent
                    size: 96
                    wmClass: Taskbar.appIdOf(card.modelData)
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Switcher.select(card.modelData);
                    Switcher.commit();
                }
            }
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 60
        spacing: 10

        ImageIcon {
            anchors.verticalCenter: parent.verticalCenter
            size: 24
            wmClass: Taskbar.appIdOf(Switcher.current)
        }

        CaptionText {
            anchors.verticalCenter: parent.verticalCenter
            text: Switcher.current?.title ?? ""
            font.pixelSize: 16
        }
    }
}

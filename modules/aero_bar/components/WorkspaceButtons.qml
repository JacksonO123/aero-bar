import QtQuick
import Quickshell.Hyprland
import QtQuick.Layouts
import Quickshell.Widgets
import "../../../utils/colors.js" as ColorUtils
import "../../../services"
import "../../../utils/constants.js" as Constants

RowLayout {
    id: root
    spacing: 8

    readonly property bool hovered: hoverHandler.hovered
    property int highlightWorkspaceId: Constants.NO_WORKSPACE
    signal buttonClicked

    function workspaceAt(item, px, py) {
        for (let i = 0; i < workspaceButtonsRepeater.count; i++) {
            const button = workspaceButtonsRepeater.itemAt(i);
            if (!button) {
                continue;
            }
            const p = button.mapFromItem(item, px, py);
            if (p.x >= -4 && p.y >= -6 && p.x <= button.width + 4 && p.y <= button.height + 6) {
                return button.modelData;
            }
        }
        return null;
    }

    HoverHandler {
        id: hoverHandler
    }

    Repeater {
        id: workspaceButtonsRepeater
        model: Hyprland.workspaces

        Win7Frame {
            id: frame

            required property var modelData
            property real isActive: frame.modelData.active
            property real hasContent: frame.modelData.toplevels.values.length
            property real highlightT: root.highlightWorkspaceId === HyprState.keyOf(frame.modelData) ? 1 : 0

            Behavior on isActive {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutSine
                }
            }

            Behavior on hasContent {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutSine
                }
            }

            Behavior on highlightT {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutSine
                }
            }

            scale: 1 - (0.05 * frame.pressedT)

            implicitWidth: 46 + (frame.isActive * 12)
            implicitHeight: 22
            frameOpacity: 2 + frame.pressedT + (frame.hoverT / 2) + frame.highlightT

            onClicked: {
                frame.modelData.activate();
                root.buttonClicked();
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: frame.radius
                color: Qt.rgba(0.38, 0.56, 0.64, frame.isActive / 1.6)
            }

            ClippingRectangle {

                anchors.fill: parent
                color: Qt.rgba(1, 1, 1, 0.2 * frame.hoverT + 0.15 * frame.pressedT)
                radius: frame.radius

                TwoToneBackground {
                    type: "foreground"
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.55, 0.88, 1.0, 0.35 * frame.highlightT)
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: height / 2
                    anchors.centerIn: parent
                    color: ColorUtils.interpolateColors("gray", "white", frame.hasContent)
                }
            }
        }
    }
}

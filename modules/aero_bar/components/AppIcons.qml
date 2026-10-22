pragma ComponentBehavior: Bound

import Quickshell.Widgets
import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects
import "../../../utils/constants.js" as Constants

Row {
    id: root
    required property var apps
    spacing: 2
    height: Constants.BAR_HEIGHT
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    Repeater {
        model: root.apps

        AppIconFrame {
            id: entry

            required property var modelData

            implicitHeight: Constants.BAR_HEIGHT
            implicitWidth: Constants.ICON_BUTTON_WIDTH
            onClicked: Quickshell.execDetached(entry.modelData.cmd)
            frameOpacity: entry.hoverT

            Image {
                id: appImage
                property int size: entry.modelData.size

                anchors.centerIn: parent
                anchors.verticalCenterOffset: entry.modelData.offset

                source: entry.modelData.img
                sourceSize: Qt.size(width * 2, height * 2)
                width: size
                height: size * 2
            }

            Win7Hover {
                radius: entry.radius
                opacity: entry.hoverT
                pressedT: entry.pressedT
            }
        }
    }
}

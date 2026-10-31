pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../../utils/constants.js" as Constants

Row {
    id: root
    spacing: 2
    height: Constants.BAR_HEIGHT
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    Repeater {
        model: ToplevelManager.toplevels

        OpenAppIcon {
            required property var modelData

            size: 24
            wmClass: modelData.appId
            desktopIcon: wmClass !== "" ? (DesktopEntries.heuristicLookup(wmClass)?.icon ?? "") : ""
        }
    }
}

import QtQuick
import Quickshell.Services.SystemTray
import "../flyout"
import "./components"

Row {
    id: tray
    spacing: 8

    required property Flyout flyoutEl

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    Repeater {
        model: SystemTray.items

        TrayItem {
            required property var modelData

            trayItemData: modelData
            flyoutEl: tray.flyoutEl
        }
    }
}

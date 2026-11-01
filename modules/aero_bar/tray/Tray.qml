import QtQuick
import Quickshell.Services.SystemTray
import "./components"

Row {
    id: tray
    spacing: 8

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    Repeater {
        model: SystemTray.items

        TrayItem {
            required property var modelData

            trayItemData: modelData
        }
    }
}

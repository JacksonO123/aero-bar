import QtQuick
import Quickshell.Services.SystemTray

Row {
    id: tray
    spacing: 8

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    Repeater {
        id: r
        model: SystemTray.items

        TrayItem {
            required property var modelData

            Component.onCompleted: {
                console.log(JSON.stringify(modelData));
            }

            trayItemData: modelData
        }
    }
}

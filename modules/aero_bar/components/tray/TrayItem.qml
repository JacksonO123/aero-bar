import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import ".."

AppIconFrame {
    id: trayItem

    required property SystemTrayItem trayItemData

    width: 26
    height: 26

    anchors.top: parent.top
    anchors.bottom: parent.bottom

    anchors.margins: {
        top: 4;
        bottom: 4;
    }

    frameOpacity: trayItem.hoverT

    ImageIcon {
        wmClass: trayItem.trayItemData.id
        backupSource: trayItem.trayItemData.icon
        size: 18
        anchors.centerIn: parent
    }

    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton && trayItemData.hasMenu) {
            menu.open();
        }
    }

    Win7Hover {
        opacity: trayItem.hoverT
        radius: trayItem.radius
        pressedT: trayItem.pressedT
    }

    QsMenuAnchor {
        id: menu
        menu: trayItem.trayItemData.menu
        anchor.item: trayItem
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
    }
}

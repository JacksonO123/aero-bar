import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../components"

Win7Frame {
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

    function findPlayer() {
        const id = trayItemData.id.toLowerCase();
        for (const p of Mpris.players.values) {
            const de = (p.desktopEntry ?? "").toLowerCase();
            const name = (p.identity ?? "").toLowerCase();
            if ((de !== "" && id.includes(de)) || (name !== "" && id.includes(name))) {
                return p;
            }
        }
        return null;
    }

    IconImage {
        source: trayItem.trayItemData.icon
        implicitSize: 18
        anchors.centerIn: parent
    }

    onClicked: mouse => {
        const player = findPlayer();

        if (mouse.button === Qt.LeftButton) {
            if (trayItemData.id === "nm-applet") {
                Quickshell.execDetached(["nm-connection-editor"]);
            } else if (player && player.canRaise) {
                player.raise();
            } else if (trayItemData.onlyMenu && trayItemData.hasMenu) {
                menu.open();
            } else {
                trayItemData.activate();
            }
        } else if (mouse.button === Qt.MiddleButton) {
            trayItemData.secondaryActivate();
        } else if (mouse.button === Qt.RightButton && trayItemData.hasMenu) {
            menu.open();
        }
    }

    Win7Hover {
        opacity: trayItem.hoverT
        radius: trayItem.radius
        pressedT: trayItem.pressedT
    }

    WheelHandler {
        onWheel: event => trayItem.trayItemData.scroll(event.angleDelta.y, false)
    }

    WheelHandler {
        orientation: Qt.Horizontal
        onWheel: event => trayItem.trayItemData.scroll(event.angleDelta.x, true)
    }

    QsMenuAnchor {
        id: menu
        menu: trayItem.trayItemData.menu
        anchor.item: trayItem
        anchor.edges: Edges.Top
        anchor.gravity: Edges.Top
    }
}

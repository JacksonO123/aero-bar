import QtQuick
import "../flyout"
import "../../../services"

// The Action Center flag. Click for the notification list; right-click toggles do not disturb.
// A red glass badge counts notifications that arrived since it was last opened.
Win7Frame {
    id: root

    required property Flyout flyoutEl
    property bool active: false

    implicitWidth: 30
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.topMargin: 4
    anchors.bottomMargin: 4
    frameOpacity: Math.max(hoverT, active ? 1 : 0)

    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            Notifications.setDoNotDisturb(!Notifications.doNotDisturb);
        } else {
            flyoutEl.toggle(root);
        }
    }

    Win7Hover {
        radius: root.radius
        opacity: Math.max(root.hoverT, root.active ? 0.8 : 0)
        pressedT: root.pressedT
    }

    FlagGlyph {
        anchors.centerIn: parent
        width: 18
        height: 18
        quiet: Notifications.doNotDisturb
    }

    Rectangle {
        visible: Notifications.unread > 0
        x: parent.width - width - 1
        y: 1
        width: Math.max(14, badgeText.implicitWidth + 7)
        height: 14
        radius: 7
        border.width: 1
        border.color: Qt.rgba(0.35, 0, 0, 0.8)
        gradient: Gradient {
            GradientStop {
                position: 0
                color: "#ff9d8a"
            }
            GradientStop {
                position: 0.5
                color: "#e8401a"
            }
            GradientStop {
                position: 1
                color: "#b52a0c"
            }
        }

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: Notifications.unread > 9 ? "9+" : Notifications.unread
            color: "white"
            font.pixelSize: 9
            font.bold: true
        }
    }
}

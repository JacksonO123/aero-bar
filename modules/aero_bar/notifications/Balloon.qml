import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../components"
import "../../../services"
import "../../../utils/constants.js" as Constants

// A Windows 7 balloon tip for one notification. The newest one points its tail down at the
// Action Center flag. Hovering keeps it up; clicking runs the notification's default action.
Item {
    id: root

    property var notification: null
    property bool tail: false
    readonly property bool hovered: mouse.containsMouse || close.hovered
    readonly property real tailHeight: tail ? 10 : 0
    readonly property bool urgent: notification?.urgency === NotificationUrgency.Critical

    signal timedOut

    width: 330
    height: Math.max(icon.height, textColumn.height) + 24 + tailHeight

    // wait while hovered; critical notifications stay until dismissed
    Timer {
        running: root.notification !== null && !root.hovered && !root.urgent
        interval: (root.notification?.expireTimeout ?? 0) > 0 ? root.notification.expireTimeout * 1000 : Constants.NOTIFICATION_TIMEOUT
        onTriggered: root.timedOut()
    }

    Canvas {
        id: shape

        readonly property real pad: 10

        x: -pad
        y: -pad
        width: root.width + pad * 2
        height: root.height + pad * 2
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        property bool urgent: root.urgent
        onUrgentChanged: requestPaint()
        property real tailH: root.tailHeight
        onTailHChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const p = pad, w = root.width, h = root.height - tailH, r = 6;
            const tx = w - 34;   // tail tip, under the right end where the flag sits
            const outline = () => {
                ctx.beginPath();
                ctx.moveTo(p + r, p + 0.5);
                ctx.lineTo(p + w - r, p + 0.5);
                ctx.arcTo(p + w - 0.5, p + 0.5, p + w - 0.5, p + r, r);
                ctx.lineTo(p + w - 0.5, p + h - r);
                ctx.arcTo(p + w - 0.5, p + h - 0.5, p + w - r, p + h - 0.5, r);
                if (tailH > 0) {
                    ctx.lineTo(p + tx + 2, p + h - 0.5);
                    ctx.lineTo(p + tx + 2, p + h + tailH - 0.5);
                    ctx.lineTo(p + tx - 14, p + h - 0.5);
                }
                ctx.lineTo(p + r, p + h - 0.5);
                ctx.arcTo(p + 0.5, p + h - 0.5, p + 0.5, p + h - r, r);
                ctx.lineTo(p + 0.5, p + r);
                ctx.arcTo(p + 0.5, p + 0.5, p + r, p + 0.5, r);
                ctx.closePath();
            };

            ctx.save();
            ctx.shadowColor = Qt.rgba(0, 0, 0, 0.35);
            ctx.shadowBlur = 8;
            ctx.shadowOffsetY = 2;
            outline();
            const g = ctx.createLinearGradient(0, p, 0, p + h);
            g.addColorStop(0, "#ffffff");
            g.addColorStop(1, urgent ? "#fbeaea" : "#e6eaf2");
            ctx.fillStyle = g;
            ctx.fill();
            ctx.restore();

            outline();
            ctx.lineWidth = 1;
            ctx.strokeStyle = urgent ? "#b0473a" : "#767676";
            ctx.stroke();
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.bottomMargin: root.tailHeight
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.activate(root.notification)
    }

    NotificationIcon {
        id: icon
        x: 12
        y: 12
        size: 32
        notification: root.notification
    }

    Column {
        id: textColumn
        x: 54
        y: 10
        width: root.width - x - 30
        spacing: 2

        Text {
            width: parent.width
            text: root.notification?.appName ?? ""
            visible: text !== ""
            color: "#6b7785"
            font.pixelSize: 11
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.notification?.summary ?? ""
            color: "#1a1a1a"
            font.pixelSize: 12
            font.bold: true
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }

        Text {
            width: parent.width
            text: root.notification?.body ?? ""
            visible: text !== ""
            color: "#333"
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: 5
            elide: Text.ElideRight
            textFormat: Text.StyledText
            linkColor: "#0066cc"
            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        Flow {
            width: parent.width
            spacing: 6
            topPadding: 4
            visible: actionRepeater.count > 0

            Repeater {
                id: actionRepeater
                model: (root.notification?.actions ?? []).filter(a => a.identifier !== "default")

                PushButton {
                    required property var modelData
                    implicitHeight: 22
                    text: modelData.text
                    onClicked: modelData.invoke()
                }
            }
        }
    }

    SmallClose {
        id: close
        x: root.width - width - 8
        y: 8
        onClicked: Notifications.dismiss(root.notification)
    }
}

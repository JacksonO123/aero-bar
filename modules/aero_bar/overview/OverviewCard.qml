import QtQuick
import Quickshell.Widgets
import "../components"
import "../../../utils/constants.js" as Constants

// One workspace: a label and a miniature Aero desktop (sky gradient, aurora ribbons, taskbar).
Item {
    id: card

    required property var overview
    required property int wsId
    required property string name

    readonly property var entry: overview.layout.byId[wsId] ?? null
    readonly property real headerH: overview.headerH
    readonly property bool active: overview.activeWorkspaceIds.includes(wsId)
    readonly property bool focusedWs: overview.focusedWorkspaceId === wsId
    readonly property bool dropHot: overview.dropTarget !== null && overview.dropTarget.wsId === wsId && overview.dropTarget.type !== "swap"
    readonly property int windowCount: overview.windowCounts[wsId] ?? 0

    property real hoverT: hover.hovered && !overview.interacting ? 1 : 0
    property real dropT: dropHot ? 1 : 0
    property real activeT: focusedWs ? 1 : active ? 0.55 : 0

    readonly property var reserved: entry ? entry.mon.reserved : [0, 0, 0, 0]
    readonly property real s: entry ? entry.scale : 0

    x: entry ? entry.x : 0
    y: entry ? entry.y - headerH : 0
    width: entry ? entry.deskW : 0
    height: entry ? entry.deskH + headerH : 0
    opacity: entry ? 1 : 0

    // the geometry follows layout changes with this
    component Glide: NumberAnimation {
        duration: 280
        easing.type: Easing.OutCubic
    }

    Behavior on x {
        Glide {}
    }

    Behavior on y {
        Glide {}
    }

    Behavior on width {
        Glide {}
    }

    Behavior on height {
        Glide {}
    }

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    Behavior on dropT {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutQuad
        }
    }

    Behavior on activeT {
        NumberAnimation {
            duration: 200
            easing.type: Easing.OutQuad
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 1
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: card.name
        color: "white"
        font.pixelSize: 11
        font.bold: card.focusedWs
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.6)
        opacity: 0.75 + 0.25 * Math.max(card.activeT, card.hoverT)
    }

    Item {
        id: desk
        y: card.headerH
        width: card.width
        height: card.height - card.headerH

        // active workspace halo
        Rectangle {
            anchors.fill: parent
            anchors.margins: -3
            radius: 6
            color: "transparent"
            border.width: 2
            border.color: Qt.rgba(0.55, 0.86, 1.0, 0.85)
            opacity: card.activeT
        }

        ClippingRectangle {
            anchors.fill: parent
            radius: 3
            color: "#1b5f9c"

            Rectangle {
                anchors.fill: parent

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: "#2c86cf"
                    }
                    GradientStop {
                        position: 0.55
                        color: "#5fb2e6"
                    }
                    GradientStop {
                        position: 0.8
                        color: "#3f9b6a"
                    }
                    GradientStop {
                        position: 1.0
                        color: "#2b7a4b"
                    }
                }
            }

            Canvas {
                id: aurora
                anchors.fill: parent
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height;
                    if (w <= 0 || h <= 0) {
                        return;
                    }

                    const glow = ctx.createRadialGradient(w * 0.2, h * 0.1, 0, w * 0.2, h * 0.1, w * 0.6);
                    glow.addColorStop(0, Qt.rgba(1, 1, 1, 0.35));
                    glow.addColorStop(1, Qt.rgba(1, 1, 1, 0));
                    ctx.fillStyle = glow;
                    ctx.fillRect(0, 0, w, h);

                    const ribbon = (y0, y1, y2, thickness, color) => {
                        const g = ctx.createLinearGradient(0, 0, w, 0);
                        g.addColorStop(0, Qt.rgba(1, 1, 1, 0));
                        g.addColorStop(0.5, color);
                        g.addColorStop(1, Qt.rgba(1, 1, 1, 0));
                        ctx.fillStyle = g;
                        ctx.beginPath();
                        ctx.moveTo(0, y0 * h);
                        ctx.bezierCurveTo(w * 0.35, y1 * h, w * 0.65, y2 * h, w, y0 * h * 0.8);
                        ctx.lineTo(w, y0 * h * 0.8 + thickness * h);
                        ctx.bezierCurveTo(w * 0.65, y2 * h + thickness * h * 1.6, w * 0.35, y1 * h + thickness * h * 0.4, 0, y0 * h + thickness * h);
                        ctx.closePath();
                        ctx.fill();
                    };

                    ribbon(0.62, 0.35, 0.8, 0.06, Qt.rgba(0.85, 0.97, 1, 0.45));
                    ribbon(0.7, 0.5, 0.95, 0.04, Qt.rgba(0.7, 1, 0.75, 0.35));
                }
            }

            // reserved areas (bars) drawn as tiny taskbars
            Rectangle {
                visible: card.reserved[3] > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.max(2, card.reserved[3] * card.s)

                gradient: SplitGradient {
                    colors: [Qt.rgba(0.75, 0.75, 0.75, 0.9), Qt.rgba(0.2, 0.2, 0.2, 0.85), Qt.rgba(0.06, 0.06, 0.06, 0.85), Qt.rgba(0.06, 0.06, 0.06, 0.85)]
                }

                Rectangle {
                    x: 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(2, parent.height * 0.75)
                    height: width
                    radius: width / 2
                    color: "#4aa8ff"
                }
            }

            Rectangle {
                visible: card.reserved[1] > 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.max(2, card.reserved[1] * card.s)
                color: Qt.rgba(0.08, 0.08, 0.08, 0.8)
            }

            Text {
                anchors.centerIn: parent
                visible: card.windowCount === 0
                text: "Empty"
                color: "white"
                opacity: 0.55
                font.pixelSize: 11
                font.italic: true
                style: Text.Raised
                styleColor: Qt.rgba(0, 0, 0, 0.4)
            }

            Win7Hover {
                radius: 3
                opacity: card.hoverT * 0.8
                pressedT: deskMouse.pressed ? 1 : 0
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.55, 0.88, 1.0, 0.22)
                opacity: card.dropT
            }
        }

        Bevel {
            anchors.fill: parent
            radius: 3
            outerColor: Qt.rgba(0, 0, 0, 0.7)
            innerColor: Qt.rgba(1, 1, 1, 0.3 + 0.25 * card.hoverT)
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: 5
            color: "transparent"
            border.width: 2
            border.color: "#a8ecff"
            opacity: card.dropT
        }
    }

    HoverHandler {
        id: hover

        onHoveredChanged: {
            if (hovered) {
                card.overview.hoveredWorkspaceId = card.wsId;
            } else if (card.overview.hoveredWorkspaceId === card.wsId) {
                card.overview.hoveredWorkspaceId = Constants.NO_WORKSPACE;
            }
        }
    }

    MouseArea {
        id: deskMouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: card.overview.activateWorkspace(card.wsId)
    }
}

import QtQuick
import "../components"

// A window in the overview: a tiny Aero window (glass frame, caption, frosted client area with
// the app icon and its reflection). Handles its own drag / resize gestures and reports them to
// the overview, which owns the logic.
Item {
    id: win

    required property var overview
    required property string address
    required property string cls
    required property string title
    required property int wsId
    required property real gx
    required property real gy
    required property real gw
    required property real gh
    required property bool floating
    required property bool fullscreen
    required property int focusHistoryId

    readonly property var target: overview.windowRect(wsId, gx, gy, gw, gh)
    property var lastTarget: ({
            x: 0,
            y: 0,
            w: 0,
            h: 0
        })
    onTargetChanged: {
        if (target) {
            lastTarget = target;
        }
    }
    readonly property var geo: target ?? lastTarget

    // `held` = geometry is being driven by the pointer, so don't animate it
    property bool held: false
    readonly property bool animate: !held && !overview.resizing
    readonly property bool dragging: overview.dragInfo !== null && overview.dragInfo.address === address
    readonly property bool resizingThis: overview.resizeInfo !== null && overview.resizeInfo.address === address
    readonly property bool focused: overview.focusedAddress === address
    readonly property bool swapTarget: overview.dropTarget !== null && overview.dropTarget.type === "swap" && overview.dropTarget.address === address

    property real vx: geo.x
    property real vy: geo.y
    property real vw: geo.w
    property real vh: geo.h

    function rebind() {
        vx = Qt.binding(() => win.geo.x);
        vy = Qt.binding(() => win.geo.y);
        vw = Qt.binding(() => win.geo.w);
        vh = Qt.binding(() => win.geo.h);
    }

    Behavior on vx {
        enabled: win.animate
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Behavior on vy {
        enabled: win.animate
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Behavior on vw {
        enabled: win.animate
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Behavior on vh {
        enabled: win.animate
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    x: vx
    y: vy
    width: vw
    height: vh
    visible: target !== null || held
    z: dragging ? 1000 : floating ? 300 - Math.min(focusHistoryId, 200) : 10

    property real hoverT: mouse.containsMouse && !overview.interacting ? 1 : 0
    property real swapT: swapTarget ? 1 : 0
    property bool spawned: false
    Component.onCompleted: spawned = true

    Behavior on hoverT {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    Behavior on swapT {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutQuad
        }
    }

    readonly property real borderW: vw > 60 ? 2.5 : 1.5
    readonly property real captionH: vh >= 46 ? Math.max(8, Math.min(13, vh * 0.12)) : Math.max(2, vh * 0.08)
    readonly property real iconSize: Math.max(10, Math.min(44, Math.min(vw - 2 * borderW, vh - captionH - borderW) * 0.46))

    Item {
        id: body
        anchors.fill: parent
        scale: win.dragging ? 1.06 : 1
        opacity: win.spawned ? (win.dragging ? 0.93 : 1) : 0

        Behavior on scale {
            NumberAnimation {
                duration: 160
                easing.type: Easing.OutBack
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }
        }

        // drop shadow
        Rectangle {
            x: 1
            y: win.dragging ? 4 : 2
            width: parent.width
            height: parent.height
            radius: 4
            color: Qt.rgba(0, 0, 0, win.dragging ? 0.45 : win.floating ? 0.32 : 0.2)
        }

        // focused window halo
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: 5
            color: "transparent"
            border.width: 1.5
            border.color: Qt.rgba(0.6, 0.9, 1.0, 0.9)
            visible: win.focused && !win.dragging
        }

        // glass frame, two-tone like the Win7 caption
        Rectangle {
            anchors.fill: parent
            radius: 3

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0.82, 0.92, 1.0, win.focused ? 0.85 : 0.7)
                }
                GradientStop {
                    position: 0.45
                    color: Qt.rgba(0.58, 0.76, 0.93, win.focused ? 0.75 : 0.6)
                }
                GradientStop {
                    position: 0.451
                    color: Qt.rgba(0.38, 0.58, 0.8, win.focused ? 0.75 : 0.6)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0.48, 0.68, 0.88, win.focused ? 0.8 : 0.65)
                }
            }
        }

        Text {
            x: win.borderW + 2
            width: parent.width - 2 * win.borderW - 4 - (closeButton.visible ? closeButton.width + 2 : 0)
            height: win.captionH
            verticalAlignment: Text.AlignVCenter
            visible: win.captionH >= 9 && width > 18
            text: win.title
            elide: Text.ElideRight
            color: "#0b1a2b"
            font.pixelSize: Math.max(7, win.captionH - 4)
            style: Text.Outline
            styleColor: Qt.rgba(1, 1, 1, 0.45)
        }

        // frosted client area
        Rectangle {
            id: client
            x: win.borderW
            y: win.captionH
            width: Math.max(0, parent.width - 2 * win.borderW)
            height: Math.max(0, parent.height - win.captionH - win.borderW)
            radius: 1.5
            color: Qt.rgba(0.95, 0.97, 0.99, 0.82)
            border.width: 1
            border.color: Qt.rgba(0.08, 0.18, 0.3, 0.5)

            ImageIcon {
                id: icon
                anchors.centerIn: parent
                anchors.verticalCenterOffset: reflection.visible ? -reflection.height * 0.45 : 0
                size: win.iconSize
                wmClass: win.cls
            }

            Reflection {
                id: reflection
                anchors.top: icon.bottom
                anchors.horizontalCenter: icon.horizontalCenter
                target: icon
                fraction: 0.4
                strength: 0.3
                visible: client.height > win.iconSize * 1.7
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 3
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.65)
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.45)
        }

        Win7Hover {
            radius: 3
            opacity: win.hoverT * 0.9
            pressedT: mouse.pressed ? 1 : 0
        }

        // "drop here to swap" highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: -2
            radius: 5
            color: Qt.rgba(0.5, 0.88, 1.0, 0.25)
            border.width: 2
            border.color: "#a8ecff"
            opacity: win.swapT

            GlassOrb {
                anchors.centerIn: parent
                size: Math.max(16, Math.min(24, Math.min(parent.width, parent.height) * 0.4))
                lightColor: "#d9fbff"
                baseColor: "#2aa6e6"

                Text {
                    anchors.centerIn: parent
                    text: "⇄"
                    color: "white"
                    font.pixelSize: parent.width * 0.62
                    font.bold: true
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 0.1, 0.25, 0.5)
                }
            }
        }

        // live size readout while resizing
        Rectangle {
            anchors.centerIn: parent
            visible: win.resizingThis
            width: sizeText.implicitWidth + 10
            height: sizeText.implicitHeight + 4
            radius: 3
            color: Qt.rgba(0.02, 0.06, 0.12, 0.75)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.3)

            Text {
                id: sizeText
                anchors.centerIn: parent
                text: `${Math.round(win.gw)} × ${Math.round(win.gh)}`
                color: "white"
                font.pixelSize: 10
            }
        }

        // Win7 thumbnail close button
        SmallClose {
            id: closeButton
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 1
            anchors.rightMargin: win.borderW
            width: 20
            height: Math.max(10, Math.min(13, win.captionH))
            visible: win.vw >= 44 && win.vh >= 30 && (win.hoverT > 0.05 || hovered)
            opacity: Math.max(win.hoverT, hovered ? 1 : 0)
            lit: true
            onClicked: win.overview.closeWindow(win.address)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: -2
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        z: -1 // keep the close button on top

        property string edge: ""
        property string mode: ""
        property real pressX: 0
        property real pressY: 0

        readonly property string activeEdge: mode === "resize" ? (win.overview.resizeInfo?.edge ?? edge) : edge

        cursorShape: {
            if (mode === "move") {
                return Qt.ClosedHandCursor;
            }
            switch (activeEdge) {
            case "l":
            case "r":
                return Qt.SizeHorCursor;
            case "t":
            case "b":
                return Qt.SizeVerCursor;
            case "tl":
            case "br":
                return Qt.SizeFDiagCursor;
            case "tr":
            case "bl":
                return Qt.SizeBDiagCursor;
            }
            return Qt.PointingHandCursor;
        }

        function edgeAt(mx, my) {
            // the area extends 2px past the window on each side
            const x = mx - 2, y = my - 2;
            const allowed = win.overview.resizableEdges(win);
            const m = Math.max(3, Math.min(6, win.width / 5, win.height / 5));
            let v = "", h = "";
            if (allowed.t && y < m) {
                v = "t";
            } else if (allowed.b && y > win.height - m) {
                v = "b";
            }
            if (allowed.l && x < m) {
                h = "l";
            } else if (allowed.r && x > win.width - m) {
                h = "r";
            }
            return v + h;
        }

        onPositionChanged: mouse => {
            if (!pressed) {
                edge = win.overview.interacting ? "" : edgeAt(mouse.x, mouse.y);
                return;
            }

            const p = mapToItem(win.overview.windowLayerItem, mouse.x, mouse.y);
            if (mode === "pending" && Math.hypot(p.x - pressX, p.y - pressY) > 4) {
                mode = edge !== "" ? "resize" : "move";
                if (mode === "move") {
                    win.overview.beginDrag(win, pressX, pressY);
                } else {
                    win.overview.beginResize(win, edge, pressX, pressY);
                }
            }

            if (mode === "move") {
                win.overview.updateDrag(win, p.x, p.y);
            } else if (mode === "resize") {
                win.overview.updateResize(p.x, p.y);
            }
        }

        onPressed: mouse => {
            if (mouse.button !== Qt.LeftButton) {
                return;
            }
            const p = mapToItem(win.overview.windowLayerItem, mouse.x, mouse.y);
            pressX = p.x;
            pressY = p.y;
            mode = "pending";
        }

        onReleased: mouse => {
            if (mouse.button === Qt.MiddleButton) {
                win.overview.closeWindow(win.address);
                return;
            }

            const p = mapToItem(win.overview.windowLayerItem, mouse.x, mouse.y);
            const finished = mode;
            mode = "";

            if (finished === "move") {
                win.overview.endDrag(win, p.x, p.y, false);
            } else if (finished === "resize") {
                win.overview.endResize(false);
            } else if (finished === "pending") {
                win.overview.focusWindow(win.address);
            }
        }

        onCanceled: {
            const finished = mode;
            mode = "";
            if (finished === "move") {
                win.overview.endDrag(win, 0, 0, true);
            } else if (finished === "resize") {
                win.overview.endResize(true);
            }
        }
    }
}

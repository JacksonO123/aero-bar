import QtQuick
import "../components"

Item {
    id: root

    default property alias panes: holder.data
    property alias aeroframe: frame

    property Item current: null
    property Item last: null

    readonly property Item pane: paneFromOwner(current)

    // set in show(), not bound, so it holds while the flyout fades out
    property bool glass: false

    property bool pinned: false

    property int holdCount: 0

    readonly property bool keepOpen: pinned || holdCount > 0 || frame.hovered

    readonly property real edgeMargin: 10
    readonly property real windowWidth: parent ? parent.width : 0
    readonly property int closeDelay: 500

    property real centerX: 0
    property real animatedCenterX: centerX
    readonly property real anchorX: last === null ? centerX : animatedCenterX

    property real targetWidth: pane ? pane.width + frame.frameWidth * 2 : 0
    property real targetHeight: pane ? pane.height + frame.frameWidth + frame.topFrameWidth : 0

    component Glide: NumberAnimation {
        duration: 110
        easing.type: Easing.InOutCubic
    }

    Behavior on targetHeight {
        Glide {}
    }

    Behavior on targetWidth {
        Glide {}
    }

    Behavior on animatedCenterX {
        Glide {}
    }

    onKeepOpenChanged: keepOpen ? closeTimer.stop() : closeTimer.restart()

    Connections {
        target: root.current

        function onVisibleChanged() {
            if (!root.current.visible) {
                root.close();
            }
        }
    }

    function paneFromOwner(owner) {
        if (owner === null) {
            return null;
        }
        for (let i = 0; i < holder.children.length; i++) {
            const child = holder.children[i];
            if (child.owner === owner) {
                return child;
            }
        }
        return null;
    }

    function show(item) {
        closeTimer.stop();
        last = current;
        current = item;
        centerX = item.mapToItem(root.parent, item.width / 2, 0).x;
        glass = pane?.glass ?? false;
    }

    function hover(item) {
        if (!pinned) {
            show(item);
        }
    }

    function unhover() {
        // the pointer can enter the flyout before the module reports it left
        if (!keepOpen) {
            closeTimer.restart();
        }
    }

    function toggle(item) {
        if (pinned && current === item) {
            close();
            return;
        }

        // before show(), which reads the app pane's glass (bound to !pinned)
        pinned = true;
        show(item);
    }

    function close() {
        // current first: the app pane reads `pinned` while it's showing
        current = null;
        last = null;
        pinned = false;
        // after pinned = false, which restarts the timer via onKeepOpenChanged
        closeTimer.stop();
    }

    Timer {
        id: closeTimer
        interval: root.closeDelay
        // a module's hover can arrive before the previous one's leave
        onTriggered: {
            if (!root.keepOpen && !(root.current?.hovered ?? false)) {
                root.close();
            }
        }
    }

    Aeroframe {
        id: frame

        anchors.bottom: parent.bottom
        width: root.targetWidth
        height: root.targetHeight
        // the (1 - scale) term offsets scaling toward the bottom-right corner
        x: Math.max(root.edgeMargin, Math.min(root.windowWidth - frame.width - root.edgeMargin, root.anchorX - frame.width / 2 - (frame.width / 2) * (1 - frame.scale)))
        scale: root.current === null ? 0.75 : 1
        transformOrigin: Item.BottomRight

        frameOpacity: root.current === null ? 0 : 1
        showContentFrame: !root.glass
        // glass panes keep clear of the corners, so no rounding mask is needed
        clipContent: !root.glass

        Behavior on frameOpacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutCubic
            }
        }

        // read by FlyoutPane as parent.activeOwner
        Item {
            id: holder
            property Item activeOwner: root.current
        }
    }
}

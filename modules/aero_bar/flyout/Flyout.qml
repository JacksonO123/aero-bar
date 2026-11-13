import QtQuick
import "../components"

// The glass flyout above the taskbar. Modules hover() / unhover() it (media, volume, taskbar
// apps) or toggle() it pinned open (calendar, Action Center, network, ...); it shows the
// FlyoutPane whose owner is the current module, sliding and resizing between panes.
Item {
    id: root

    default property alias panes: holder.data
    property alias aeroframe: frame

    // the module whose pane is showing, and the one before it (to slide over from)
    property Item current: null
    property Item last: null

    readonly property Item pane: paneFromOwner(current)

    // whether the frame is glass only (no content well, no clip pass). Set when a pane is shown
    // and left alone on close, so it can't change while the flyout fades out.
    property bool glass: false

    // click-opened panes (the calendar) pin the flyout: hovering other modules is ignored and
    // it stays until toggled again or close() is called (e.g. on a click outside)
    property bool pinned: false

    // interactions in progress (e.g. a slider being dragged; panes count them with an
    // OpenCounter): the flyout doesn't close if the pointer wanders outside it mid-drag
    property int holdCount: 0

    // whatever keeps the flyout open right now; once nothing does, it closes after a moment
    readonly property bool keepOpen: pinned || holdCount > 0 || frame.hovered

    readonly property real edgeMargin: 10
    readonly property real windowWidth: parent ? parent.width : 0
    readonly property int closeDelay: 500 // ms

    // where the frame is centred: it jumps to the first module, then slides between modules
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

    // show `item`'s pane, sliding over from the one showing
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
        // the pointer can enter the flyout before the module reports that it left
        if (!keepOpen) {
            closeTimer.restart();
        }
    }

    function toggle(item) {
        if (pinned && current === item) {
            close();
            return;
        }

        // before show(): it reads the pane's glass, which the app pane binds to !pinned
        pinned = true;
        show(item);
    }

    function close() {
        // current first: the app pane reads `pinned` (jump list or thumbnails) while it's showing
        current = null;
        last = null;
        pinned = false;
        // after clearing pinned, which restarts the timer through onKeepOpenChanged
        closeTimer.stop();
    }

    Timer {
        id: closeTimer
        interval: root.closeDelay
        onTriggered: {
            if (!root.keepOpen) {
                root.close();
            }
        }
    }

    Aeroframe {
        id: frame

        anchors.bottom: parent.bottom
        width: root.targetWidth
        height: root.targetHeight
        // the frame scales toward its bottom-right corner; the (1 - scale) term keeps it centred
        // on the module (and flush against the screen edge when clamped there)
        x: Math.max(root.edgeMargin, Math.min(root.windowWidth - frame.width - root.edgeMargin, root.anchorX - frame.width / 2 - (frame.width / 2) * (1 - frame.scale)))
        scale: root.current === null ? 0.75 : 1
        transformOrigin: Item.BottomRight

        frameOpacity: root.current === null ? 0 : 1
        showContentFrame: !root.glass
        // glass-only panes keep clear of the corners, so skip the rounding mask pass
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

        // FlyoutPanes compare their owner with activeOwner (through their parent)
        Item {
            id: holder
            property Item activeOwner: root.current
        }
    }
}

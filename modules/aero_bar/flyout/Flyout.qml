import QtQuick
import "../components"

Item {
    id: root

    default property alias panes: holder.data
    property alias aeroframe: frame
    property Item last: null
    property Item current: null
    property real centerX: 0
    property real animatedCenterX: centerX

    readonly property real edgeMargin: 10
    readonly property real windowWidth: parent ? parent.width : 0
    readonly property real closeDelay: 500

    function paneFromOwner(owner) {
        for (let i = 0; i < holder.children.length; i++) {
            const child = holder.children[i];
            if (owner !== null && child.owner === owner) {
                return child;
            }
        }

        return null;
    }

    readonly property Item pane: paneFromOwner(current)
    // whether the frame is glass only (no content well, no clip pass). Taken from the pane while
    // one shows and kept while the flyout fades out, so it can't flip mid-fade (the app pane's
    // `glass` follows `pinned`, which close() clears).
    property bool glass: false

    Binding on glass {
        when: root.pane !== null
        // with no pane, the current value: whichever of `when`/`value` updates first, nothing
        // changes on the way out
        value: root.pane ? root.pane.glass : root.glass
        restoreMode: Binding.RestoreNone
    }

    property real targetWidth: pane ? pane.width + frame.frameWidth * 2 : 0
    property real targetHeight: pane ? pane.height + frame.frameWidth + frame.topFrameWidth : 0

    Behavior on targetHeight {
        NumberAnimation {
            duration: 110
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on targetWidth {
        NumberAnimation {
            duration: 110
            easing.type: Easing.InOutCubic
        }
    }

    Behavior on animatedCenterX {
        NumberAnimation {
            duration: 110
            easing.type: Easing.InOutCubic
        }
    }

    function hover(item) {
        if (pinned) {
            return;
        }
        closeTimer.stop();
        last = current;
        current = item;
        centerX = item.mapToItem(root.parent, item.width / 2, 0).x;
    }

    function unhover() {
        // the pointer can enter the flyout before the module reports that it left
        if (!pinned && !frame.hovered) {
            closeTimer.restart();
        }
    }

    // click-opened panes (the calendar) pin the flyout: hovering other modules is ignored and
    // it stays until toggled again or close() is called (e.g. on a click outside)
    property bool pinned: false

    function toggle(item) {
        if (pinned && current === item) {
            close();
            return;
        }

        closeTimer.stop();
        pinned = true;
        last = current;
        current = item;
        centerX = item.mapToItem(root.parent, item.width / 2, 0).x;
    }

    function close() {
        // current first: the panes' state (e.g. glass) must not change on the way out
        current = null;
        last = null;
        pinned = false;
        closeTimer.stop();
    }

    // interactions in progress (e.g. a slider being dragged; panes count them with an
    // OpenCounter): the flyout doesn't close if the pointer wanders outside it mid-drag
    property int holdCount: 0

    onHoldCountChanged: {
        if (holdCount > 0) {
            closeTimer.stop();
        } else if (!frame.hovered) {
            closeTimer.restart();
        }
    }

    Timer {
        id: closeTimer
        interval: root.closeDelay
        onTriggered: {
            if (root.holdCount > 0 || root.pinned || frame.hovered) {
                return;
            }
            root.current = null;
            root.last = null;
        }
    }

    Aeroframe {
        id: frame

        anchors.bottom: parent.bottom
        frameOpacity: root.current === null ? 0 : 1
        showContentFrame: !root.glass
        // glass-only panes keep clear of the corners, so skip the rounding mask pass
        clipContent: !root.glass
        width: root.targetWidth
        height: root.targetHeight
        x: Math.max(root.edgeMargin, Math.min(root.windowWidth - frame.width - root.edgeMargin, (root.last === null ? root.centerX : root.animatedCenterX) - (frame.width / 2) - (frame.width / 2) * (1 - frame.scale)))
        scale: root.current === null ? 0.75 : 1
        transformOrigin: Qt.BottomEdge

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

        Item {
            id: holder
            property Item activeOwner: root.current
        }

        onHoveredChanged: {
            if (hovered) {
                closeTimer.stop();
            } else if (root.holdCount === 0 && !root.pinned) {
                closeTimer.restart();
            }
        }
    }
}

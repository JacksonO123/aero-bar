pragma ComponentBehavior: Bound

import Quickshell
import QtQuick
import "../flyout"
import "../../../services"
import "../../../utils/constants.js" as Constants

// Pinned taskbar apps. Running ones get a glass button (with a stacked edge for several
// windows). Hover for window thumbnails, click to launch / switch windows, middle-click for a
// new window, right-click for the jump list.
Row {
    id: root
    required property var apps
    required property Flyout flyoutEl
    spacing: 2
    height: Constants.BAR_HEIGHT
    anchors.top: parent.top
    anchors.bottom: parent.bottom

    Repeater {
        model: root.apps

        Win7Frame {
            id: entry

            required property var modelData

            readonly property bool isAppButton: true
            readonly property var app: modelData
            readonly property var windows: Taskbar.windowsFor(modelData)
            readonly property bool running: windows.length > 0
            readonly property bool active: windows.some(t => t.activated)

            anchors.top: parent.top
            anchors.topMargin: -1
            implicitHeight: Constants.BAR_HEIGHT + 1
            implicitWidth: Constants.ICON_BUTTON_WIDTH
            frameOpacity: Math.max(entry.hoverT, running ? (active ? 0.9 : 0.6) : 0)

            function focusNext() {
                const i = windows.findIndex(t => t.activated);
                const next = windows[(i + 1) % windows.length];
                HyprState.focusWindow(Taskbar.hyprAddress(next));
            }

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.flyoutEl.toggle(entry);
                    return;
                }
                root.flyoutEl.close();
                if (mouse.button === Qt.MiddleButton || !running) {
                    Quickshell.execDetached(entry.modelData.cmd);
                } else {
                    focusNext();
                }
            }

            // the first thumbnails wait a moment; once showing, they follow the pointer at once
            onHoveredChanged: {
                if (hovered) {
                    if (root.flyoutEl.current?.isAppButton) {
                        root.flyoutEl.hover(entry);
                    } else {
                        showTimer.restart();
                    }
                } else {
                    showTimer.stop();
                    root.flyoutEl.unhover();
                }
            }

            Timer {
                id: showTimer
                interval: Constants.THUMBNAIL_DELAY
                onTriggered: {
                    if (entry.hovered) {
                        root.flyoutEl.hover(entry);
                    }
                }
            }

            // a second window peeks out behind the button, like Win7's stacked taskbar buttons
            Rectangle {
                visible: entry.windows.length > 1
                x: parent.width - 3
                y: 4
                width: 3
                height: parent.height - 8
                radius: 2
                color: Qt.rgba(1, 1, 1, 0.12)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.3)
            }

            Image {
                id: appImage
                property int size: entry.modelData.size

                anchors.centerIn: parent
                anchors.verticalCenterOffset: entry.modelData.offset

                source: entry.modelData.img
                sourceSize: Qt.size(width * 2, height * 2)
                width: size
                height: size * 2
            }

            Win7Hover {
                radius: entry.radius
                opacity: entry.hoverT
                pressedT: entry.pressedT
            }
        }
    }
}

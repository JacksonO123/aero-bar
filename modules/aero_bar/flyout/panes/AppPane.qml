import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../components"
import "../../startmenu"
import "../../../../services"
import "../../../../utils/constants.js" as Constants

// The pane for a hovered taskbar app. Hover: Win7 thumbnails of the app's windows on the glass
// (or just its name when it isn't running); hovering a thumbnail Aero Peeks at that window.
// Right-click (pinned): the jump list, with the app's own tasks, launch and close.
Item {
    id: root

    required property var flyoutEl
    // the hovered taskbar button (the pane's owner), or null
    property Item button: null
    // the bar window's top-left corner in layout coordinates, so Aero Peek can keep this flyout
    // uncovered
    property point windowOrigin: Qt.point(0, 0)

    readonly property var app: button?.app ?? null
    readonly property var windows: button?.windows ?? []
    readonly property bool jump: flyoutEl.pinned
    readonly property bool shown: button !== null
    readonly property var entry: app ? Taskbar.entryFor(app) : null

    readonly property real thumbW: 196
    readonly property real thumbH: 124

    width: jump ? jumpList.width : windows.length > 0 ? thumbs.width + 12 : nameLabel.implicitWidth + 24
    height: jump ? jumpList.height : windows.length > 0 ? thumbs.height + 10 : 30

    onShownChanged: {
        if (!shown) {
            Peek.hide();
        }
    }

    onJumpChanged: Peek.hide()

    // ---- name only (not running) ---------------------------------------------------------------

    CaptionText {
        id: nameLabel
        anchors.centerIn: parent
        visible: !root.jump && root.windows.length === 0
        text: root.app?.name ?? root.entry?.name ?? ""
    }

    // ---- thumbnails ----------------------------------------------------------------------------

    Row {
        id: thumbs
        x: 6
        y: 4
        spacing: 4
        visible: !root.jump && root.windows.length > 0

        Repeater {
            model: root.jump ? [] : root.windows

            Win7Frame {
                id: thumb

                required property var modelData
                readonly property var toplevel: modelData
                readonly property string address: Taskbar.hyprAddress(toplevel)

                width: root.thumbW
                height: root.thumbH + 28
                frameOpacity: Math.max(hoverT, toplevel.activated ? 0.5 : 0)

                onHoveredChanged: {
                    if (hovered) {
                        peekTimer.restart();
                    } else {
                        peekTimer.stop();
                        if (Peek.toplevel === toplevel) {
                            Peek.hide();
                        }
                    }
                }

                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                        HyprState.closeWindow(address);
                        return;
                    }
                    Peek.hide();
                    HyprState.focusWindow(address);
                    root.flyoutEl.close();
                }

                Timer {
                    id: peekTimer
                    interval: Constants.PEEK_DELAY
                    onTriggered: {
                        const frame = root.flyoutEl.aeroframe;
                        const p = frame.mapToItem(null, 0, 0);
                        Peek.show(thumb.toplevel, Qt.rect(root.windowOrigin.x + p.x, root.windowOrigin.y + p.y, frame.width, frame.height));
                    }
                }

                Win7Hover {
                    radius: thumb.radius
                    opacity: thumb.hoverT
                    pressedT: thumb.pressedT
                }

                ImageIcon {
                    x: 7
                    y: 6
                    size: 16
                    wmClass: Taskbar.appIdOf(thumb.toplevel)
                }

                CaptionText {
                    x: 28
                    y: 6
                    width: parent.width - x - 26
                    text: thumb.toplevel.title
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Item {
                    x: 6
                    y: 25
                    width: root.thumbW - 12
                    height: root.thumbH - 4

                    ScreencopyView {
                        id: preview
                        anchors.centerIn: parent
                        captureSource: root.shown ? thumb.toplevel.wayland : null
                        live: true
                        constraintSize: Qt.size(parent.width, parent.height)
                        width: implicitWidth
                        height: implicitHeight
                    }

                    ImageIcon {
                        anchors.centerIn: parent
                        visible: !preview.hasContent
                        size: 48
                        wmClass: Taskbar.appIdOf(thumb.toplevel)
                    }
                }

                // above the thumbnail's click area, or the click would focus the window instead
                overlay: SmallClose {
                    x: thumb.width - 21
                    y: 5
                    visible: thumb.hoverT > 0.5
                    lit: true
                    onClicked: HyprState.closeWindow(thumb.address)
                }
            }
        }
    }

    // ---- jump list ------------------------------------------------------------------------------

    Column {
        id: jumpList
        visible: root.jump
        width: 250
        topPadding: 8
        bottomPadding: 6

        SectionHeader {
            x: 10
            width: parent.width - 20
            visible: tasks.count > 0
            text: "Tasks"
        }

        Repeater {
            id: tasks
            model: root.jump ? (root.entry?.actions ?? []) : []

            MenuItem {
                required property var modelData
                width: jumpList.width
                height: 28
                iconSize: 16
                label: modelData.name
                iconName: modelData.icon || root.entry?.icon || ""
                onActivated: {
                    modelData.execute();
                    root.flyoutEl.close();
                }
            }
        }

        Rectangle {
            x: 8
            width: parent.width - 16
            height: 1
            visible: tasks.count > 0
            color: Qt.rgba(0.6, 0.72, 0.85, 0.6)
        }

        MenuItem {
            width: parent.width
            height: 30
            iconSize: 16
            label: root.app?.name ?? root.entry?.name ?? "Open"
            iconName: root.entry?.icon ?? ""
            bold: true
            onActivated: {
                Quickshell.execDetached(root.app.cmd);
                root.flyoutEl.close();
            }
        }

        MenuItem {
            width: parent.width
            height: 28
            iconSize: 16
            visible: root.windows.length > 0
            label: root.windows.length > 1 ? "Close all windows" : "Close window"
            iconName: "window-close"
            onActivated: {
                for (const t of root.windows) {
                    HyprState.closeWindow(Taskbar.hyprAddress(t));
                }
                root.flyoutEl.close();
            }
        }
    }
}

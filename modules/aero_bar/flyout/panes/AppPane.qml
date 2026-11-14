import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."
import "../../components"
import "../../startmenu"
import "../../../../services"
import "../../../../utils/constants.js" as Constants

FlyoutPane {
    id: root

    required property var flyoutEl
    // bar window's top-left in Hyprland layout coordinates
    property point windowOrigin: Qt.point(0, 0)

    readonly property var app: owner?.app ?? null
    readonly property var windows: owner?.windows ?? []
    readonly property bool jump: flyoutEl.pinned
    readonly property var entry: app ? Taskbar.entryFor(app) : null

    readonly property real thumbW: 196
    readonly property real thumbH: 124

    owner: flyoutEl.current?.isAppButton ? flyoutEl.current : null
    glass: !jump

    width: jump ? jumpList.width : windows.length > 0 ? thumbs.width + 12 : nameLabel.implicitWidth + 24
    height: jump ? jumpList.height : windows.length > 0 ? thumbs.height + 10 : 30

    CaptionText {
        id: nameLabel
        anchors.centerIn: parent
        visible: !root.jump && root.windows.length === 0
        text: root.app?.name ?? root.entry?.name ?? ""
    }

    Row {
        id: thumbs
        x: 6
        y: 4
        spacing: 4
        visible: !root.jump && root.windows.length > 0

        Repeater {
            // ScriptModel keeps delegates (and live captures) as windows come and go
            model: ScriptModel {
                values: root.jump ? [] : root.windows
            }

            Win7Frame {
                id: thumb

                required property var modelData
                readonly property var toplevel: modelData
                readonly property string address: Taskbar.hyprAddress(toplevel)

                width: root.thumbW
                height: root.thumbH + 28
                frameOpacity: Math.max(hoverT, toplevel.wayland?.activated ? 0.5 : 0)

                Component.onDestruction: Peek.hide(toplevel)

                onHoveredChanged: {
                    if (hovered) {
                        Peek.prepare();
                        peekTimer.restart();
                    } else {
                        peekTimer.stop();
                        Peek.hide(toplevel);
                    }
                }

                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton) {
                        HyprState.closeWindow(address);
                        return;
                    }
                    if (mouse.button !== Qt.LeftButton) {
                        return;
                    }
                    HyprState.focusWindow(address, true);
                    root.flyoutEl.close();
                }

                Timer {
                    id: peekTimer
                    interval: Constants.PEEK_DELAY
                    onTriggered: Peek.show(thumb.toplevel, root.flyoutEl.aeroframe, root.windowOrigin)
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
                        captureSource: root.active ? thumb.toplevel.wayland : null
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

                // in overlay, above the click area, or the click would focus the window
                overlay: SmallClose {
                    x: thumb.width - 21
                    y: 5
                    opacity: thumb.hoverT
                    visible: opacity > 0
                    lit: true
                    onClicked: HyprState.closeWindow(thumb.address)
                }
            }
        }
    }

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

        FlyoutRule {
            x: 8
            width: parent.width - 16
            visible: tasks.count > 0
            alpha: 0.6
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
                HyprState.closeWindows(root.windows.map(Taskbar.hyprAddress));
                root.flyoutEl.close();
            }
        }
    }
}

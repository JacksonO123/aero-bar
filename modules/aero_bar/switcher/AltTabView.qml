import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../../../services"
import "../../../utils/constants.js" as Constants

// Win7's Alt+Tab with Aero: live thumbnails on a glass panel, the selected one framed, its
// title on top. Resting on a window for a moment Aero Peeks at it.
Item {
    id: root

    property real maxWidth: 1400
    readonly property real cellW: 180
    readonly property real cellH: 132
    readonly property int columns: Math.max(1, Math.min(Switcher.windows.length, Math.floor((maxWidth - 48) / cellW)))

    width: grid.width + 48
    height: grid.height + 74

    Timer {
        id: peekTimer
        interval: Constants.PEEK_DELAY + 300
        onTriggered: {
            if (Switcher.current) {
                Peek.show("0x" + Switcher.current.address);
            }
        }
    }

    Connections {
        target: Switcher

        function onSelectedChanged() {
            Peek.hide();
            peekTimer.restart();
        }
    }

    Component.onCompleted: peekTimer.restart()

    Aeroframe {
        anchors.fill: parent
        radius: 8
        frameWidth: 0
        topFrameWidth: 0
        showContentFrame: false
    }

    CaptionText {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 14
        width: Math.min(implicitWidth, parent.width - 40)
        text: Switcher.current?.title ?? ""
        font.pixelSize: 14
        elide: Text.ElideRight
    }

    Grid {
        id: grid
        x: 24
        y: 48
        columns: root.columns
        spacing: 0

        Repeater {
            model: Switcher.windows

            Item {
                id: cell

                required property var modelData
                required property int index
                readonly property bool selected: Switcher.selected === modelData.address

                width: root.cellW
                height: root.cellH

                // Win7's selection: a bright glass frame
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 5
                    visible: cell.selected || cellMouse.containsMouse
                    color: Qt.rgba(1, 1, 1, cell.selected ? 0.16 : 0.08)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, cell.selected ? 0.75 : 0.4)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 4
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(0, 0, 0, 0.3)
                    }

                    Rectangle {
                        x: 2
                        y: 2
                        width: parent.width - 4
                        height: parent.height * 0.45
                        radius: 4
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.rgba(1, 1, 1, 0.3)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.rgba(1, 1, 1, 0.04)
                            }
                        }
                    }
                }

                ScreencopyView {
                    id: shot
                    anchors.centerIn: parent
                    captureSource: cell.modelData.wayland
                    live: true
                    constraintSize: Qt.size(root.cellW - 20, root.cellH - 22)
                    width: implicitWidth
                    height: implicitHeight
                }

                ImageIcon {
                    anchors.centerIn: parent
                    visible: !shot.hasContent
                    size: 48
                    wmClass: Taskbar.appIdOf(cell.modelData)
                }

                ImageIcon {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    visible: shot.hasContent
                    size: 26
                    wmClass: Taskbar.appIdOf(cell.modelData)
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        Switcher.select(cell.modelData);
                        Switcher.commit();
                    }
                }
            }
        }
    }
}

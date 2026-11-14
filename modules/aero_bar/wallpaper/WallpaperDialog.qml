import Quickshell
import Quickshell.Wayland
import QtQuick
import "../components"
import "../../../services"

// "Desktop Background": pick the wallpaper from a folder of pictures. Clicking one applies it
// (through Wallpaper.setCommand); Save keeps it, Cancel / Esc / close puts the old one back.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: window

        required property var modelData
        screen: modelData

        readonly property bool wanted: Wallpaper.dialogOpen && Wallpaper.screen === modelData.name
        readonly property real shadowMargin: 24

        visible: wanted || dialog.opacity > 0.01
        exclusiveZone: 0
        implicitWidth: dialog.width + shadowMargin * 2
        implicitHeight: dialog.height + shadowMargin * 2
        color: "transparent"

        WlrLayershell.namespace: "aero-dialog"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: wanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        onWantedChanged: {
            if (wanted) {
                dialog.forceActiveFocus();
            }
        }

        AeroWindow {
            id: dialog

            x: window.shadowMargin
            y: window.shadowMargin + (window.wanted ? 0 : 10)
            // four columns of pictures, with room for the scroll thumb
            width: grid.cellWidth * 4 + 22 + 32 + 18
            opacity: window.wanted ? 1 : 0
            title: "Desktop Background"
            focus: true
            onCloseClicked: Wallpaper.cancel()

            Keys.onReturnPressed: Wallpaper.save()
            Keys.onEnterPressed: Wallpaper.save()

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                }
            }
            Behavior on y {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Item {
                id: body
                width: parent.width
                height: footer.y + footer.height

                Text {
                    id: heading
                    x: 20
                    y: 16
                    text: "Choose your desktop background"
                    color: "#1e3c78"
                    font.pixelSize: 15
                }

                Text {
                    id: hint
                    x: 20
                    y: heading.y + heading.height + 6
                    text: "Click a picture to make it your desktop background."
                    color: "#333"
                    font.pixelSize: 12
                }

                Row {
                    id: location
                    x: 20
                    y: hint.y + hint.height + 14
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Picture location:"
                        color: "#1a1a1a"
                        font.pixelSize: 12
                    }

                    TextField {
                        id: folder
                        anchors.verticalCenter: parent.verticalCenter
                        width: 452
                        text: Wallpaper.directory
                        placeholder: "Folder with your pictures"
                        onAccepted: Wallpaper.setDirectory(text)
                    }

                    PushButton {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Wallpaper.canBrowse
                        text: "Browse…"
                        onClicked: Wallpaper.browse()
                    }
                }

                // the pictures, in a white list box
                Rectangle {
                    id: listBox
                    x: 16
                    y: location.y + location.height + 12
                    width: parent.width - 32
                    height: 372
                    color: "white"
                    border.width: 1
                    border.color: "#828790"

                    GridView {
                        id: grid
                        x: 6
                        y: 6
                        width: cellWidth * 4
                        height: parent.height - 12
                        cellWidth: 166
                        cellHeight: 118
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: Wallpaper.images

                        delegate: WallpaperTile {
                            required property string modelData
                            path: modelData
                            selected: modelData === Wallpaper.selected
                            onClicked: Wallpaper.pick(modelData)
                        }
                    }

                    // slim Aero scroll thumb
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 3
                        y: grid.y + grid.visibleArea.yPosition * grid.height
                        width: 4
                        height: grid.visibleArea.heightRatio * grid.height
                        radius: 2
                        visible: grid.contentHeight > grid.height
                        color: Qt.rgba(0.3, 0.42, 0.55, 0.45)
                    }

                    // nothing to show yet, or nothing there
                    Text {
                        anchors.centerIn: parent
                        visible: Wallpaper.images.length === 0
                        text: Wallpaper.scanning ? "Looking for pictures…" : Wallpaper.missing ? "This folder can't be opened." : "There are no pictures in this folder."
                        color: "#6d6d6d"
                        font.pixelSize: 12
                    }
                }

                Text {
                    id: count
                    x: 20
                    y: listBox.y + listBox.height + 8
                    visible: Wallpaper.images.length > 0
                    text: Wallpaper.images.length === 1 ? "1 picture" : Wallpaper.images.length + " pictures"
                    color: "#6d6d6d"
                    font.pixelSize: 11
                }

                DialogFooter {
                    id: footer
                    y: count.y + count.height + 12
                    width: parent.width

                    // Win7's Personalization links: on to the glass colour (keeping the picture)
                    leading: LinkText {
                        text: "Window Color"
                        onClicked: {
                            const screen = Wallpaper.screen;
                            Wallpaper.save();
                            Theme.openDialog(screen);
                        }
                    }

                    PushButton {
                        text: "Save changes"
                        isDefault: true
                        onClicked: Wallpaper.save()
                    }
                    PushButton {
                        text: "Cancel"
                        onClicked: Wallpaper.cancel()
                    }
                }
            }
        }
    }
}

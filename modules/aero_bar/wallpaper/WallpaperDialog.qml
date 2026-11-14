import Quickshell
import QtQuick
import "../components"
import "../../../services"

// "Desktop Background": pick the wallpaper from a folder of pictures. Clicking one applies it
// (through Wallpaper.setCommand); Save keeps it, Cancel / Esc / close puts the old one back.
Variants {
    model: Quickshell.screens

    // a little glass screen showing the chosen picture (top right of the dialog)
    component ScreenPreview: Item {
        id: preview

        property string path: ""

        width: 96
        height: 66

        // the bezel
        Rectangle {
            id: bezel
            width: parent.width
            height: 60
            radius: 4
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#5b6875"
                }
                GradientStop {
                    position: 1
                    color: "#1d242b"
                }
            }

            // the picture, or a plain Aero sky before one is chosen
            Rectangle {
                id: screenArea
                anchors.fill: parent
                anchors.margins: 4
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#3d79c2"
                    }
                    GradientStop {
                        position: 1
                        color: "#a8d6f5"
                    }
                }

                Image {
                    anchors.fill: parent
                    source: preview.path !== "" ? "file://" + preview.path : ""
                    sourceSize: Qt.size(width * 2, height * 2)
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    mipmap: true
                }
            }

            // glass over the screen's top half
            Rectangle {
                x: screenArea.x
                y: screenArea.y
                width: screenArea.width
                height: screenArea.height * 0.46
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.rgba(1, 1, 1, 0.3)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(1, 1, 1, 0.06)
                    }
                }
            }

            Bevel {
                anchors.fill: parent
                radius: 4
                outerColor: "#10161b"
                innerColor: Qt.rgba(1, 1, 1, 0.22)
            }
        }

        // the stand
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: bezel.height
            width: 26
            height: 5
            radius: 1
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#3b454f"
                }
                GradientStop {
                    position: 1
                    color: "#7d8994"
                }
            }
        }
    }

    DialogWindow {
        id: window
        service: Wallpaper
        title: "Desktop Background"
        // four columns of pictures, with room for the scroll thumb
        dialogWidth: grid.cellWidth * 4 + 22 + 32 + 18

        Item {
            id: body
            width: parent.width
            height: footer.y + footer.height

            // a soft Aero band along the top, with the chosen picture on its little screen
            Rectangle {
                id: band
                width: parent.width
                height: 86
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#ffffff"
                    }
                    GradientStop {
                        position: 1
                        color: "#e4eef9"
                    }
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: "#c5d5e8"
                }

                Text {
                    id: heading
                    x: 20
                    y: 20
                    text: "Choose your desktop background"
                    color: "#1e3c78"
                    font.pixelSize: 15
                }

                Text {
                    x: 20
                    y: heading.y + heading.height + 6
                    text: "Click a picture to make it your desktop background."
                    color: "#333"
                    font.pixelSize: 12
                }

                ScreenPreview {
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    path: Wallpaper.selected
                }
            }

            Row {
                id: location
                x: 20
                y: band.height + 14
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
                    placeholder: "Your pictures folder (leave empty for the default)"
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
                radius: 3
                border.width: 1
                border.color: "#9fb4ca"
                // white, with a faint inset along the top like a Win7 text box
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "#eef3f8"
                    }
                    GradientStop {
                        position: 0.03
                        color: "#ffffff"
                    }
                }

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
                    // only while this screen shows the dialog (and fades it out)
                    model: window.visible ? Wallpaper.images : []

                    delegate: PictureTile {
                        required property string modelData
                        width: grid.cellWidth
                        height: grid.cellHeight
                        path: modelData
                        selected: modelData === Wallpaper.selected
                        onClicked: Wallpaper.pick(modelData)
                    }
                }

                ScrollThumb {
                    anchors.right: parent.right
                    anchors.rightMargin: 3
                    flickable: grid
                }

                // nothing to show yet, or nothing there
                Text {
                    anchors.centerIn: parent
                    visible: Wallpaper.images.length === 0
                    text: {
                        if (Wallpaper.scanning) {
                            return "Looking for pictures…";
                        }
                        return Wallpaper.missing ? "This folder can't be opened." : "There are no pictures in this folder.";
                    }
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

                // Win7's Personalization links: on to the glass colour or your account picture
                // (keeping the background)
                leading: Row {
                    spacing: 18

                    LinkText {
                        text: "Window Color"
                        onClicked: window.switchTo(Theme)
                    }

                    LinkText {
                        text: "Account Picture"
                        onClicked: window.switchTo(AccountPicture)
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

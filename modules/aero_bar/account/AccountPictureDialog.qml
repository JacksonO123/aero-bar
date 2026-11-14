import Quickshell
import QtQuick
import "../components"
import "../../../services"

// "Change Your Picture": choose your account picture from the pictures in ACCOUNT_PICTURES_DIR
// (the Windows 7 ones), or browse for another. Change Picture, Enter or a double-click keeps it;
// Cancel, Esc or the close button leave the old one.
Variants {
    model: Quickshell.screens

    DialogWindow {
        id: window
        service: AccountPicture
        title: "Change Your Picture"
        // six columns of pictures, with room for the scroll thumb
        dialogWidth: grid.cellWidth * 6 + 22 + 32 + 18

        // the picture you'll have: the one clicked, else the one you have now
        readonly property string shown: AccountPicture.selection || StartMenuState.picture

        Item {
            id: body
            width: parent.width
            height: footer.y + footer.height

            // a soft Aero band along the top, with the picture in its Win7 frame and your name
            Rectangle {
                id: band
                width: parent.width
                height: 112
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
                    y: 24
                    text: "Choose a new picture for your account"
                    color: "#1e3c78"
                    font.pixelSize: 15
                }

                Text {
                    x: 20
                    y: heading.y + heading.height + 6
                    width: you.x - x - 20
                    wrapMode: Text.Wrap
                    text: "Your picture will appear on the Welcome screen and on the Start menu."
                    color: "#333"
                    font.pixelSize: 12
                }

                Column {
                    id: you
                    anchors.right: parent.right
                    anchors.rightMargin: 28
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    ProfileTile {
                        anchors.horizontalCenter: parent.horizontalCenter
                        size: 72
                        picture: window.shown
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: StartMenuState.displayName
                        color: "#1a1a1a"
                        font.pixelSize: 12
                    }
                }
            }

            // the pictures, in a white list box
            Rectangle {
                id: listBox
                x: 16
                y: band.height + 16
                width: parent.width - 32
                // three and a half rows, so it's clear there are more
                height: grid.cellHeight * 3.5 + 12
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
                    width: cellWidth * 6
                    height: parent.height - 12
                    cellWidth: 100
                    cellHeight: 100
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    // only while this screen shows the dialog (and fades it out)
                    model: window.visible ? AccountPicture.images : []

                    delegate: PictureTile {
                        required property string modelData
                        width: grid.cellWidth
                        height: grid.cellHeight
                        path: modelData
                        selected: modelData === window.shown
                        onClicked: AccountPicture.select(modelData)
                        onDoubleClicked: {
                            AccountPicture.select(modelData);
                            AccountPicture.save();
                        }
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
                    width: parent.width - 80
                    visible: AccountPicture.images.length === 0
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    lineHeight: 1.3
                    text: {
                        if (AccountPicture.scanning) {
                            return "Looking for pictures…";
                        }
                        const browse = AccountPicture.canBrowse ? ", or browse for a picture of your own" : "";
                        return `Put the Windows 7 account pictures in ${AccountPicture.directory}${browse}.`;
                    }
                    color: "#6d6d6d"
                    font.pixelSize: 12
                }
            }

            DialogFooter {
                id: footer
                y: listBox.y + listBox.height + 14
                width: parent.width

                leading: LinkText {
                    visible: AccountPicture.canBrowse
                    text: "Browse for more pictures…"
                    onClicked: AccountPicture.browse()
                }

                PushButton {
                    text: "Change Picture"
                    isDefault: true
                    enabled: AccountPicture.selection !== ""
                    onClicked: AccountPicture.save()
                }
                PushButton {
                    text: "Cancel"
                    onClicked: AccountPicture.cancel()
                }
            }
        }
    }
}

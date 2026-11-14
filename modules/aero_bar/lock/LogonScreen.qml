import QtQuick
import "../components"
import "../../../services"
import "../../../utils/constants.js" as Constants
import "../../../utils/path.js" as PathUtils

Item {
    id: root

    default property alias content: center.data
    property alias controls: controlsRow.data
    // anything with sleep(), restart() and shutDown(); null hides the power button
    property var power: null
    property bool clockShown: true
    // shown over the aurora once loaded
    property string wallpaper: ""
    property bool shown: true
    property bool entered: false

    signal backgroundClicked

    anchors.fill: parent
    opacity: shown && entered ? 1 : 0
    visible: opacity > 0
    Component.onCompleted: entered = true

    Behavior on opacity {
        NumberAnimation {
            duration: 350
        }
    }

    LogonBackground {
        anchors.fill: parent
        visible: picture.opacity < 1
    }

    Image {
        id: picture
        anchors.fill: parent
        source: PathUtils.fileUrl(root.wallpaper)
        sourceSize: Qt.size(width, height)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 250
            }
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: Qt.rgba(0.02, 0.08, 0.2, 0.3)
                }
                GradientStop {
                    position: 0.5
                    color: Qt.rgba(0.02, 0.08, 0.2, 0.42)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0.02, 0.06, 0.16, 0.6)
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            powerMenu.visible = false;
            root.backgroundClicked();
        }
    }

    Column {
        id: center
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -40
        spacing: 14
    }

    Column {
        x: 48
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        spacing: 2
        visible: root.clockShown

        CaptionText {
            text: Qt.formatTime(Clock.date, Constants.TIME_FORMAT)
            font.pixelSize: 60
            font.weight: Font.Light
        }
        CaptionText {
            text: Qt.formatDate(Clock.date, "dddd, MMMM d")
            font.pixelSize: 18
        }
    }

    CaptionText {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 44
        text: "Arch Linux"
        font.pixelSize: 22
        font.weight: Font.Light
        color: Qt.rgba(1, 1, 1, 0.85)
    }

    Row {
        id: controlsRow
        anchors.right: powerButton.left
        anchors.rightMargin: 18
        anchors.verticalCenter: powerButton.verticalCenter
        spacing: 18
    }

    GlassOrb {
        id: powerButton
        visible: root.power !== null
        anchors.right: parent.right
        anchors.rightMargin: 48
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 46
        size: 38
        lightColor: "#ffc2a8"
        baseColor: "#d8401c"
        darkColor: "#5a0c00"
        glowColor: Qt.rgba(1, 0.8, 0.7, 0.9)
        hoverT: powerMouse.containsMouse ? 1 : 0
        pressedT: powerMouse.pressed ? 1 : 0

        PowerGlyph {
            anchors.centerIn: parent
            width: 18
            height: 18
        }

        MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: powerMenu.visible = !powerMenu.visible
        }
    }

    LogonMenu {
        id: powerMenu
        anchors.right: powerButton.right
        anchors.bottom: powerButton.top
        anchors.bottomMargin: 8
        actions: [
            {
                label: "Sleep",
                command: root.power?.sleep
            },
            {
                label: "Restart",
                command: root.power?.restart
            },
            {
                label: "Shut down",
                command: root.power?.shutDown
            }
        ]
    }
}

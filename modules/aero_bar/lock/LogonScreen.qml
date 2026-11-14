import QtQuick
import "../components"
import "../../../services"
import "../../../utils/constants.js" as Constants

Item {
    id: root

    default property alias content: center.data
    property alias controls: controlsRow.data
    required property var power

    signal backgroundClicked

    anchors.fill: parent
    opacity: 0
    Component.onCompleted: opacity = 1

    Behavior on opacity {
        NumberAnimation {
            duration: 350
        }
    }

    LogonBackground {
        anchors.fill: parent
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
                command: root.power.sleep
            },
            {
                label: "Restart",
                command: root.power.restart
            },
            {
                label: "Shut down",
                command: root.power.shutDown
            }
        ]
    }
}

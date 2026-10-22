import QtQuick

AppIconFrame {
    id: root

    required property var date
    property real padding: (root.height - timeText.height) / 1.2

    property bool showDate: false
    property real mix: showDate ? 1 : 0

    Behavior on mix {
        NumberAnimation {
            duration: 220
            easing.type: Easing.InOutQuad
        }
    }

    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    anchors.margins: 4

    frameOpacity: 1

    width: (timeText.contentWidth * (1 - mix) + dateText.contentWidth * mix) + padding * 2

    onClicked: root.showDate = !root.showDate

    Text {
        id: timeText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root.mix * 6
        text: Qt.formatDateTime(root.date, "hh:mm ap")
        color: "white"
        font.bold: false
        font.pointSize: 10.5
        opacity: 1 - root.mix
    }

    Text {
        id: dateText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: (1 - root.mix) * 6
        text: Qt.formatDate(root.date, "dd/M/yy")
        color: "white"
        font.bold: false
        font.pointSize: 10.5
        opacity: root.mix
    }

    Win7Hover {
        radius: root.radius
        opacity: root.hoverT
        pressedT: root.pressedT
    }
}

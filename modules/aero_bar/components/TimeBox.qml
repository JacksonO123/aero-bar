import QtQuick

Rectangle {
    id: root

    required property var date
    property real padding_n: (root.height - timeText.height) / 1.2

    width: Math.max(timeText.contentWidth, dateText.contentWidth) + padding_n * 2

    color: "transparent"

    Text {
        id: timeText
        text: Qt.formatDateTime(root.date, "h:mm ap")
        color: "white"
        font.bold: false
        font.pointSize: 10.5
        anchors.top: root.top
        anchors.right: root.right
        anchors.rightMargin: 4
    }

    Text {
        id: dateText
        text: Qt.formatDate(root.date, "dd/M/yy")
        color: "white"
        font.bold: false
        font.pointSize: 10.5
        anchors.bottom: root.bottom
        anchors.right: root.right
        anchors.rightMargin: 4
    }
}

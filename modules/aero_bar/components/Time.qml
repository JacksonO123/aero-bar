import QtQuick

Rectangle {
    id: root

    required property var date
    property real paddingRight: 4

    width: Math.max(timeText.contentWidth, dateText.contentWidth) + paddingRight

    color: "transparent"

    Text {
        id: timeText
        text: Qt.formatDateTime(root.date, "h:mm AP")
        color: "white"
        font.bold: false
        font.pointSize: 10.5
        anchors.top: root.top
        anchors.topMargin: -1
        anchors.right: root.right
        anchors.rightMargin: root.paddingRight
    }

    Text {
        id: dateText
        text: Qt.formatDate(root.date, "dd/M/yy")
        color: "white"
        font.bold: false
        font.pointSize: 10.5
        anchors.bottom: root.bottom
        anchors.right: root.right
        anchors.rightMargin: root.paddingRight
        anchors.bottomMargin: -1
    }
}

import QtQuick
import "../../../utils/constants.js" as Constants

// Clock in the corner. Click to pin the calendar flyout open.
Win7Frame {
    id: root

    required property var date
    property real paddingRight: 4
    // true while the calendar it opened is showing
    property bool active: false

    implicitWidth: Math.max(timeText.contentWidth, dateText.contentWidth) + paddingRight + 10
    frameOpacity: Math.max(hoverT, active ? 1 : 0)

    Win7Hover {
        radius: root.radius
        opacity: Math.max(root.hoverT, root.active ? 0.85 : 0)
        pressedT: Math.max(root.pressedT, root.active ? 0.6 : 0)
    }

    Text {
        id: timeText
        text: Qt.formatDateTime(root.date, Constants.TIME_FORMAT)
        color: "white"
        font.pointSize: 10.5
        anchors.top: parent.top
        anchors.topMargin: -1
        anchors.right: parent.right
        anchors.rightMargin: root.paddingRight + 4
    }

    Text {
        id: dateText
        text: Qt.formatDate(root.date, "dd/M/yy")
        color: "white"
        font.pointSize: 10.5
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.rightMargin: root.paddingRight + 4
        anchors.bottomMargin: -1
    }
}

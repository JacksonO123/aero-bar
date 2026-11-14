import QtQuick

Rectangle {
    id: root

    default property alias buttons: buttonRow.data
    property alias leading: leadingHolder.data

    height: 46
    color: "#f0f0f0"

    Rectangle {
        width: parent.width
        height: 1
        color: "#dfdfdf"
    }

    Item {
        id: leadingHolder
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }

    Row {
        id: buttonRow
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }
}

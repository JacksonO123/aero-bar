import QtQuick

// The grey command area along the bottom of a Win7 dialog: buttons on the right, and an
// optional item (e.g. a DisclosureToggle) on the left.
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

import QtQuick

// a sibling of the flickable, not a child: a Flickable scrolls its children
Rectangle {
    required property Flickable flickable

    y: flickable.y + flickable.visibleArea.yPosition * flickable.height
    width: 4
    height: flickable.visibleArea.heightRatio * flickable.height
    radius: 2
    visible: flickable.contentHeight > flickable.height
    color: Qt.rgba(0.3, 0.42, 0.55, 0.45)
}

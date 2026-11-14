import QtQuick

// The slim Aero scroll thumb, showing only while `flickable` has more than fits. Place it
// beside the flickable (as a sibling, not inside it: a Flickable scrolls its children) and
// anchor it to the right edge.
Rectangle {
    required property Flickable flickable

    y: flickable.y + flickable.visibleArea.yPosition * flickable.height
    width: 4
    height: flickable.visibleArea.heightRatio * flickable.height
    radius: 2
    visible: flickable.contentHeight > flickable.height
    color: Qt.rgba(0.3, 0.42, 0.55, 0.45)
}

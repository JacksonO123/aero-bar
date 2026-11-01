import QtQuick

Item {
    id: root

    required property Item owner
    readonly property bool active: owner === parent.activeOwner

    opacity: active ? 1 : 0
    visible: opacity > 0

    width: childrenRect.width
    height: childrenRect.height

    Behavior on opacity {
        NumberAnimation {
            duration: 110
            easing: Easing.InOutCubic
        }
    }
}

import QtQuick

Item {
    id: root

    // the module this pane belongs to, or `accepts` for a pane shared by many (taskbar apps)
    property Item owner: null
    property var accepts: null
    // glass only, no light content well (the taskbar thumbnails)
    property bool glass: false
    readonly property bool active: parent.activeOwner !== null && (owner === parent.activeOwner || (accepts !== null && accepts(parent.activeOwner)))

    opacity: active ? 1 : 0
    visible: opacity > 0

    width: childrenRect.width
    height: childrenRect.height

    Behavior on opacity {
        NumberAnimation {
            duration: 110
            easing.type: Easing.InOutCubic
        }
    }
}

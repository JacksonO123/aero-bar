import QtQuick

Item {
    id: root

    // the module this pane belongs to (can change: the taskbar apps share one pane)
    property Item owner: null
    // glass only, no light content well (the taskbar thumbnails)
    property bool glass: false
    // the pane has text input, so the bar must take keyboard focus while it is pinned open
    property bool wantsKeyboard: false
    readonly property bool active: owner !== null && owner === parent.activeOwner

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

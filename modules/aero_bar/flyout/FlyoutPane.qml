import QtQuick

// The base of every Flyout pane (MediaPane, CalendarPane, ...): shown while its owner is the
// flyout's current module. Its parent is the Flyout's holder, whose activeOwner is that module.
Item {
    id: root

    // the module this pane belongs to (can change: the taskbar apps share one pane)
    property Item owner: null

    // glass only, no light content well (the taskbar thumbnails). Read when the pane is shown
    // (Flyout.show()); a later change applies on the next show.
    property bool glass: false

    // the pane has text input, so the bar must take keyboard focus while it is pinned open
    property bool wantsKeyboard: false

    readonly property bool active: owner !== null && owner === parent.activeOwner

    // (each pane sets its own width and height)
    opacity: active ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: 110
            easing.type: Easing.InOutCubic
        }
    }
}

import QtQuick

// Adds one to `target[counter]` while `when` is true, and takes it back when `when` turns false
// or this is destroyed. Services count their open per-screen panes this way (to stop work while
// none is open); the flyout counts holds (holdCount) the same way.
QtObject {
    id: root

    required property QtObject target
    required property string counter
    property bool when: false

    property bool counted: false

    function sync() {
        if (when !== counted) {
            target[counter] += when ? 1 : -1;
            counted = when;
        }
    }

    onWhenChanged: sync()
    Component.onCompleted: sync()
    Component.onDestruction: {
        if (counted) {
            target[counter] -= 1;
        }
    }
}

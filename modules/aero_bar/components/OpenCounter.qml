import QtQuick

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

import QtQuick

Item {
    id: root

    property Item owner: null

    // read on Flyout.show(); a later change applies on the next show
    property bool glass: false

    property bool wantsKeyboard: false

    readonly property bool active: owner !== null && owner === parent.activeOwner

    opacity: active ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation {
            duration: 110
            easing.type: Easing.InOutCubic
        }
    }
}

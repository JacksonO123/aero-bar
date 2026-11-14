import QtQuick
import "../../../services"

Item {
    readonly property bool showing: loader.active

    anchors.fill: parent
    Component.onCompleted: loader.active = SessionEnd.active

    Loader {
        id: loader
        anchors.fill: parent
        active: false
        sourceComponent: SessionEndView {}
    }

    Connections {
        target: SessionEnd

        function onActiveChanged() {
            if (SessionEnd.active) {
                unload.stop();
                loader.active = true;
            } else {
                unload.restart();
            }
        }
    }

    // outlasts LogonScreen's 350 ms fade-out
    Timer {
        id: unload
        interval: 400
        onTriggered: loader.active = SessionEnd.active
    }
}

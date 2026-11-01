import QtQuick
import "../flyout/components"
import "../flyout"

Rectangle {
    id: root

    required property Flyout flyoutEl

    width: text.width
    height: text.height
    color: hoverHandler.hovered ? "red" : "blue"

    Text {
        id: text
        text: "audio_module"
    }

    FlyoutHoverHandler {
        id: hoverHandler
        rootEl: root
        flyoutEl: root.flyoutEl
    }
}

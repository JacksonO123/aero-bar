import QtQuick
import ".."

HoverHandler {
    required property Flyout flyoutEl
    required property Item rootEl

    onHoveredChanged: hovered ? flyoutEl.hover(rootEl) : flyoutEl.unhover()
}

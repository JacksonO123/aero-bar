import Quickshell
import Quickshell.Wayland
import QtQuick

// A Win7 dialog in its own window on one screen (Window Color, Desktop Background, Change Your
// Picture): the glass AeroWindow fades and drops in while `service.dialogOpen` and the service's
// screen is this one. Enter saves; Esc and the close button cancel. `service` has dialogOpen,
// screen, save() and cancel(), and `browsing` if it opens a file chooser.
PanelWindow {
    id: window

    required property var modelData
    required property var service

    default property alias content: dialog.content
    property alias title: dialog.title
    property alias dialogWidth: dialog.width

    readonly property bool wanted: service.dialogOpen && service.screen === modelData.name
    readonly property real shadowMargin: 24

    screen: modelData
    visible: wanted || dialog.opacity > 0.01
    exclusiveZone: 0
    implicitWidth: dialog.width + shadowMargin * 2
    implicitHeight: dialog.height + shadowMargin * 2
    color: "transparent"

    WlrLayershell.namespace: "aero-dialog"
    // while the service's file chooser is open, it goes under the windows and lets go of the
    // keyboard, so the chooser can be seen and typed in
    readonly property bool browsing: service.browsing ?? false
    WlrLayershell.layer: browsing ? WlrLayer.Bottom : WlrLayer.Top
    WlrLayershell.keyboardFocus: wanted && !browsing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onWantedChanged: {
        if (wanted) {
            dialog.forceActiveFocus();
        }
    }

    // Win7's Personalization links: keep what's chosen here and open `other` (a service with
    // openDialog()) on the same screen
    function switchTo(other) {
        service.save();
        other.openDialog(service.screen);
    }

    AeroWindow {
        id: dialog

        x: window.shadowMargin
        y: window.shadowMargin + (window.wanted ? 0 : 10)
        opacity: window.wanted ? 1 : 0
        focus: true
        onCloseClicked: window.service.cancel()

        Keys.onReturnPressed: window.service.save()
        Keys.onEnterPressed: window.service.save()

        Behavior on opacity {
            NumberAnimation {
                duration: 160
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
    }
}

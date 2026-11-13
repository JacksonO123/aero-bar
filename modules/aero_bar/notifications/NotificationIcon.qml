import QtQuick
import Quickshell
import "../components"

// The picture for a notification: its image if it sent one, else the app's icon.
Item {
    id: root

    property var notification: null
    property real size: 32

    readonly property string image: notification?.image ?? ""
    readonly property string appIcon: notification?.appIcon ?? ""
    readonly property bool appIconIsUrl: appIcon.startsWith("file:") || appIcon.startsWith("image:") || appIcon.startsWith("/")
    readonly property string entryIcon: {
        DesktopEntries.applications.values;
        const id = notification?.desktopEntry ?? "";
        return id !== "" ? (DesktopEntries.byId(id)?.icon ?? DesktopEntries.heuristicLookup(id)?.icon ?? "") : "";
    }

    implicitWidth: size
    implicitHeight: size

    Image {
        id: picture
        anchors.fill: parent
        visible: status === Image.Ready
        source: root.image !== "" ? root.image : root.appIconIsUrl ? (root.appIcon.startsWith("/") ? "file://" + root.appIcon : root.appIcon) : ""
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
        mipmap: true
    }

    ImageIcon {
        anchors.fill: parent
        visible: !picture.visible
        size: root.size
        desktopIcon: !root.appIconIsUrl && root.appIcon !== "" ? root.appIcon : root.entryIcon !== "" ? root.entryIcon : "dialog-information"
        backupSource: Quickshell.iconPath("dialog-information", true)
    }
}

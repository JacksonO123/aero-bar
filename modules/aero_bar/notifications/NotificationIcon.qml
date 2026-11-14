import QtQuick
import Quickshell
import "../components"
import "../../../services"
import "../../../utils/path.js" as PathUtils

Item {
    id: root

    property var notification: null
    property real size: 32

    readonly property string image: notification?.image ?? ""

    readonly property string appIcon: notification?.appIcon ?? ""
    readonly property bool appIconIsUrl: appIcon.startsWith("file:") || appIcon.startsWith("image:") || appIcon.startsWith("/")
    readonly property string appIconUrl: !appIconIsUrl ? "" : appIcon.startsWith("/") ? PathUtils.fileUrl(appIcon) : appIcon

    readonly property string entryIcon: Taskbar.entryById(notification?.desktopEntry ?? "")?.icon ?? ""

    readonly property string iconName: !appIconIsUrl && appIcon !== "" ? appIcon : entryIcon || "dialog-information"

    implicitWidth: size
    implicitHeight: size

    Image {
        id: picture
        anchors.fill: parent
        visible: status === Image.Ready
        source: root.image || root.appIconUrl
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        asynchronous: true
        mipmap: true
    }

    ImageIcon {
        anchors.fill: parent
        visible: !picture.visible
        size: root.size
        desktopIcon: root.iconName
        backupSource: Quickshell.iconPath("dialog-information", true)
    }
}

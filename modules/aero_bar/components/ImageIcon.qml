import QtQuick
import Quickshell
import Quickshell.Widgets
import "../../../utils/path.js" as PathUtils

IconImage {
    id: root

    property string wmClass: ""
    property string desktopIcon: ""
    property int size: 24
    property string backupSource: ""

    implicitSize: size
    asynchronous: true

    readonly property var entry: {
        if (wmClass.length === 0) {
            return null;
        }
        DesktopEntries.applications.values; // look again when the entry list changes
        return DesktopEntries.heuristicLookup(wmClass);
    }

    source: {
        const names = [desktopIcon, entry?.icon, wmClass, wmClass.toLowerCase()];
        for (const name of names) {
            if (!name) {
                continue;
            }

            // desktop files may point straight at an image file
            if (name.startsWith("/")) {
                return PathUtils.fileUrl(name);
            }

            const path = Quickshell.iconPath(name, true);

            if (path !== "") {
                return path;
            }
        }

        if (backupSource !== "") {
            return backupSource;
        }

        return Quickshell.iconPath("application-x-executable");
    }
}

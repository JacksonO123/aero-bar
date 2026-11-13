import QtQuick
import Quickshell
import Quickshell.Widgets

IconImage {
    id: root

    property string wmClass: ""
    property string desktopIcon: ""
    property int size: 24
    property string backupSource: ""

    implicitSize: size
    asynchronous: true

    readonly property var entry: {
        DesktopEntries.applications.values;
        return wmClass.length > 0 ? DesktopEntries.heuristicLookup(wmClass) : null;
    }

    source: {
        const names = [desktopIcon, entry?.icon, wmClass, wmClass.toLowerCase()];
        for (const name of names) {
            if (!name) {
                continue;
            }

            // desktop files may point straight at an image file
            if (name.startsWith("/")) {
                return "file://" + name;
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

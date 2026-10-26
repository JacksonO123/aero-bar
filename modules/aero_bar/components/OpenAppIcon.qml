import QtQuick
import Quickshell

Image {
    id: root

    property string wmClass: ""
    property string desktopIcon: ""
    property int size: 24

    width: size
    height: size
    sourceSize.width: size * 2
    sourceSize.height: size * 2
    fillMode: Image.PreserveAspectFit
    asynchronous: true
    cache: true

    readonly property var iconDirs: [
        {
            path: "/home/jotto/.local/share/icons/crystal-remix-icon-theme/40x40/apps",
            ext: "png"
        },
        {
            path: "/home/jotto/.local/share/icons/Tela-circle/scalable/apps",
            ext: "svg"
        },
        {
            path: "/home/jotto/.local/share/icons/Tela-circle-dark/scalable/apps",
            ext: "svg"
        },
        {
            path: "/usr/share/icons/breeze/apps/48",
            ext: "svg"
        },
        {
            path: "/usr/share/icons/Adwaita/scalable/apps",
            ext: "svg"
        },
        {
            path: "/usr/share/icons/hicolor/scalable/apps",
            ext: "svg"
        }
    ]

    readonly property var names: {
        let list = [];

        if (desktopIcon.length > 0) {
            list.push(desktopIcon);
        }

        if (wmClass.length > 0) {
            list.push(wmClass);
            list.push(wmClass.toLowerCase());
        }

        return [...new Set(list)];
    }

    readonly property var candidates: {
        let icons = [];
        for (const pathInfo of iconDirs) {
            for (const name of names) {
                icons.push("file://" + pathInfo.path + "/" + name + "." + pathInfo.ext);
            }
        }
        icons.push(Quickshell.iconPath(names[0] ?? "", "application-x-executable"));
        return icons;
    }

    property int tryIndex: 0
    source: names.length > 0 ? candidates[Math.min(tryIndex, candidates.length - 1)] : ""

    onStatusChanged: {
        if (status === Image.Error && tryIndex < candidates.length - 1)
            tryIndex++;
    }

    onCandidatesChanged: tryIndex = 0

    MouseArea {
        anchors.fill: parent

        onClicked: {
            console.log('hi');
        }
    }
}

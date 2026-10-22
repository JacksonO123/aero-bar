pragma Singleton

import Quickshell
import QtQuick
import "../utils/path.js" as PathUtils

Singleton {
    id: root

    property var apps: [
        {
            cmd: [PathUtils.pathRelativeToHome(".local/bin/spotlight"), "--config", PathUtils.pathRelativeToHome(".config/jotto-utils/spotlight/desktop.conf")],
            img: Qt.resolvedUrl("../assets/magnifying-glass-icon-reflect.png"),
            offset: 10,
            size: 22
        },
        {
            cmd: ["alacritty"],
            img: Qt.resolvedUrl("../assets/term-icon-reflect.png"),
            offset: 10,
            size: 23
        },
        {
            cmd: ["dolphin"],
            img: Qt.resolvedUrl("../assets/files-icon-reflect.png"),
            offset: 10,
            size: 23
        },
        {
            cmd: ["spotify-launcher"],
            img: Qt.resolvedUrl("../assets/music-icon-reflect.png"),
            offset: 10,
            size: 22
        },
        {
            cmd: ["google-chrome-stable"],
            img: Qt.resolvedUrl("../assets/browser-icon-reflect.png"),
            offset: 10,
            size: 26
        },
    ]
}

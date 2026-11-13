pragma Singleton

import Quickshell
import QtQuick
import "../utils/path.js" as PathUtils

// Pinned taskbar apps. `appIds` are the window classes (`hyprctl clients`) that belong to the
// app: those windows show as thumbnails when hovering it, and mark it as running.
Singleton {
    id: root

    property var apps: [
        {
            cmd: [PathUtils.pathRelativeToHome(".local/bin/spotlight"), "--config", PathUtils.pathRelativeToHome(".config/jotto-utils/spotlight/desktop.conf")],
            name: "Search",
            img: Qt.resolvedUrl("../assets/magnifying-glass-icon-reflect.png"),
            offset: 10,
            size: 22
        },
        {
            cmd: ["alacritty"],
            name: "Alacritty",
            appIds: ["Alacritty"],
            img: Qt.resolvedUrl("../assets/term-icon-reflect.png"),
            offset: 10,
            size: 23
        },
        {
            cmd: ["dolphin"],
            name: "Dolphin",
            appIds: ["org.kde.dolphin", "dolphin"],
            img: Qt.resolvedUrl("../assets/files-icon-reflect.png"),
            offset: 10,
            size: 23
        },
        {
            cmd: ["spotify-launcher"],
            name: "Spotify",
            appIds: ["spotify", "Spotify"],
            img: Qt.resolvedUrl("../assets/music-icon-reflect.png"),
            offset: 10,
            size: 22
        },
        {
            cmd: ["google-chrome-stable"],
            name: "Google Chrome",
            appIds: ["google-chrome", "Google-chrome", "google-chrome-stable"],
            img: Qt.resolvedUrl("../assets/browser-icon-reflect.png"),
            offset: 10,
            size: 26
        },
    ]
}

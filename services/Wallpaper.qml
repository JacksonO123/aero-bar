pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/path.js" as PathUtils
import "../utils/constants.js" as Constants

// Open from outside: qs ipc call wallpaper open
Singleton {
    id: root

    readonly property var setCommand: Constants.WALLPAPER_SET_CMD.map(PathUtils.expandHome)
    readonly property string defaultDirectory: PathUtils.expandHome(Constants.WALLPAPER_DIR)

    // `saved` can be gone while the shell is torn down
    readonly property string directory: saved?.directory || defaultDirectory
    readonly property string current: saved?.current ?? ""

    property bool dialogOpen: false
    property string dialogScreen: ""
    readonly property string screen: Screens.resolve(dialogScreen)

    property string preview: ""
    readonly property string selected: preview || current

    readonly property var images: folder.images
    readonly property bool scanning: folder.scanning
    readonly property bool missing: folder.missing
    readonly property bool canBrowse: chooser.available
    readonly property bool browsing: chooser.busy

    function openDialog(screenName) {
        preview = "";
        dialogScreen = screenName || Screens.focused;
        refreshActive();
        // before dialogOpen, so the grid doesn't build tiles for a stale list
        folder.scan();
        dialogOpen = true;
        chooser.check();
    }

    function pick(path) {
        preview = path;
        apply(path);
    }

    function save() {
        if (preview !== "") {
            saved.current = preview;
            refreshActive();
        }
        preview = "";
        dialogOpen = false;
    }

    // back to what hyprpaper showed when the picker opened (current can be stale or unset)
    function cancel() {
        const before = active[screen] || active[""] || current;
        if (preview !== "" && before !== "" && preview !== before) {
            apply(before);
        }
        preview = "";
        dialogOpen = false;
    }

    // what hyprpaper shows on each monitor ("" for all)
    property var active: ({})

    Component.onCompleted: refreshActive()

    function pathFor(screenName) {
        return active[screenName] || active[""] || current;
    }

    function refreshActive() {
        activeQuery.running = true;
    }

    function apply(path) {
        Quickshell.execDetached(setCommand.concat([path]));
    }

    function setDirectory(path) {
        const dir = path.trim();
        saved.directory = dir === "" ? "" : PathUtils.expandHome(dir.replace(/\/+$/, "") || "/");
        folder.scan();
    }

    function browse() {
        chooser.chooseFolder(directory);
    }

    PictureFolder {
        id: folder
        directory: root.directory
    }

    FileChooser {
        id: chooser
        onChosen: path => root.setDirectory(path)
    }

    Process {
        id: activeQuery
        command: ["hyprctl", "hyprpaper", "listactive"]

        // "DP-1: /path" per line ("DP-1 = /path" before hyprpaper 0.8)
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {};
                for (const line of text.split("\n")) {
                    const match = line.match(/^\s*([^:=]*?)\s*[:=]\s*(\/.*\S)\s*$/);
                    if (match) {
                        map[match[1]] = match[2];
                    }
                }
                root.active = map;
            }
        }
    }

    FileView {
        path: Quickshell.statePath("wallpaper.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: saved

            property string directory: ""
            property string current: ""
        }
    }

    IpcHandler {
        target: "wallpaper"

        function open(): void {
            root.openDialog("");
        }
    }
}

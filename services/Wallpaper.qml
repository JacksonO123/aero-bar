pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/path.js" as PathUtils
import "../utils/constants.js" as Constants

// The desktop background, like Win7's "Desktop Background" page: pictures from a folder of your
// choice, set with your own script. Clicking a picture applies it straight away (as a preview);
// Save keeps it, Cancel puts the old one back.
//
// Open the picker from "Window Color and Appearance", or with:
//   qs ipc call wallpaper open
Singleton {
    id: root

    // set in utils/constants.js: the script that sets the wallpaper, and the folder to look in
    // until you choose another one
    readonly property var setCommand: Constants.WALLPAPER_SET_CMD.map(expandHome)
    readonly property string defaultDirectory: expandHome(Constants.WALLPAPER_DIR)

    function expandHome(path) {
        return path.startsWith("~") ? PathUtils.pathRelativeToHome(path.slice(1)) : path;
    }

    // ---- saved ------------------------------------------------------------------------------

    // the folder you chose, else the default (`saved` can be gone while the shell is torn down)
    readonly property string directory: saved?.directory || defaultDirectory
    // the picture last saved (the one to go back to on Cancel)
    readonly property string current: saved?.current ?? ""

    // ---- the picker -------------------------------------------------------------------------

    property bool dialogOpen: false
    property string dialogScreen: ""
    // where the dialog shows (dialogScreen, or the focused screen if that one is gone)
    readonly property string screen: Screens.resolve(dialogScreen)

    // the picture clicked in the picker (and already applied), "" if none yet
    property string preview: ""
    readonly property string selected: preview || current

    // the pictures in `directory` (and the folders below it), sorted by name
    property var images: []
    property bool scanning: false
    // the folder couldn't be read
    property bool missing: false
    // the folder chooser for "Browse…" (zenity or kdialog), looked for each time the picker opens
    property string chooserTool: ""
    readonly property bool canBrowse: chooserTool !== ""

    function openDialog(screenName) {
        preview = "";
        // stay on this screen, even if focus moves to another one while it is open
        dialogScreen = screenName || Screens.focused;
        // before it shows, so the grid doesn't build tiles for the old list first
        scan();
        dialogOpen = true;
        chooserCheck.running = true;
    }

    // click a picture: it becomes the background right away, like Win7
    function pick(path) {
        preview = path;
        apply(path);
    }

    function save() {
        if (preview !== "") {
            saved.current = preview;
        }
        preview = "";
        dialogOpen = false;
    }

    function cancel() {
        if (preview !== "" && preview !== current && current !== "") {
            apply(current);
        }
        preview = "";
        dialogOpen = false;
    }

    function apply(path) {
        Quickshell.execDetached(setCommand.concat([path]));
    }

    // an empty path goes back to the default folder
    function setDirectory(path) {
        const dir = path.trim();
        saved.directory = dir === "" ? "" : expandHome(dir.replace(/\/+$/, "") || "/");
        scan();
    }

    function scan() {
        images = [];
        missing = false;
        scanning = true;
        scanner.running = false;
        scanner.running = true;
    }

    function browse() {
        chooser.running = true;
    }

    // a script listing the pictures under $1 (exit status 3: the folder isn't there or can't be
    // read)
    function findPictures() {
        const types = ["jpg", "jpeg", "png", "webp", "bmp", "gif"].map(t => `-iname "*.${t}"`).join(" -o ");
        return `test -d "$1" && test -r "$1" || exit 3; find -L "$1" -maxdepth 3 -type f \\( ${types} \\) 2>/dev/null`;
    }

    function chooserCommand() {
        if (chooserTool.endsWith("kdialog")) {
            return [chooserTool, "--getexistingdirectory", directory];
        }
        return [chooserTool, "--file-selection", "--directory", "--filename=" + directory + "/"];
    }

    Process {
        id: scanner

        command: ["sh", "-c", root.findPictures(), "sh", root.directory]

        stdout: StdioCollector {
            onStreamFinished: {
                const byName = (a, b) => a.localeCompare(b, undefined, {
                        numeric: true,
                        sensitivity: "base"
                    });
                root.images = text.split("\n").filter(line => line !== "").sort(byName);
                root.scanning = false;
            }
        }

        onExited: code => {
            if (code === 3) {
                root.missing = true;
                root.scanning = false;
            }
        }
    }

    Process {
        id: chooserCheck
        command: ["sh", "-c", "command -v zenity || command -v kdialog"]

        stdout: StdioCollector {
            onStreamFinished: root.chooserTool = text.trim().split("\n")[0]
        }
    }

    Process {
        id: chooser

        // prints the chosen folder
        command: root.chooserCommand()

        stdout: StdioCollector {
            onStreamFinished: {
                const dir = text.trim();
                if (dir !== "") {
                    root.setDirectory(dir);
                }
            }
        }
    }

    FileView {
        path: Quickshell.statePath("wallpaper.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: saved

            // "" while you haven't chosen a folder: the default from constants.js applies
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

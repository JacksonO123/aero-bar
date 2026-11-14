pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/path.js" as PathUtils

// The desktop background, like Win7's "Desktop Background" page: pictures from a folder of your
// choice, set with your own script. Clicking a picture applies it straight away (as a preview);
// Save keeps it, Cancel puts the old one back.
//
// Open the picker from "Window Color and Appearance", or with:
//   qs ipc call wallpaper open
Singleton {
    id: root

    // your script that sets the wallpaper; it gets the picture's path as its last argument
    property var setCommand: [PathUtils.pathRelativeToHome(".local/bin/set-wallpaper")]

    // ---- saved ------------------------------------------------------------------------------

    // (`saved` can be gone while the shell is being torn down)
    readonly property string directory: saved?.directory ?? ""
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
    // a folder chooser (zenity or kdialog) is installed, for "Browse…"
    property bool canBrowse: false

    function openDialog(screenName) {
        preview = "";
        // stay on this screen, even if focus moves to another one while it is open
        dialogScreen = screenName || Screens.focused;
        dialogOpen = true;
        scan();
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

    function setDirectory(path) {
        const dir = path.trim().replace(/\/+$/, "") || "/";
        saved.directory = dir.startsWith("~") ? PathUtils.pathRelativeToHome(dir.slice(1)) : dir;
        scan();
    }

    function scan() {
        images = [];
        missing = false;
        scanning = true;
        scanner.running = false;
        scanner.running = true;
    }

    // a folder chooser, if one is installed (zenity or kdialog)
    function browse() {
        chooser.running = true;
    }

    Process {
        id: scanner

        // exit status 3: the folder isn't there (or can't be read)
        command: ["sh", "-c", 'test -d "$1" && test -r "$1" || exit 3; ' + 'find -L "$1" -maxdepth 3 -type f \\( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" ' + '-o -iname "*.webp" -o -iname "*.bmp" -o -iname "*.gif" \\) 2>/dev/null', "sh", root.directory]

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
            onStreamFinished: root.canBrowse = text.trim() !== ""
        }
    }

    Process {
        id: chooser

        // prints the chosen folder; exit status 127: no chooser installed
        command: ["sh", "-c", 'if command -v zenity >/dev/null; then exec zenity --file-selection --directory --filename="$1/"; ' + 'elif command -v kdialog >/dev/null; then exec kdialog --getexistingdirectory "$1"; else exit 127; fi', "sh", root.directory]

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

            property string directory: PathUtils.pathRelativeToHome("Pictures/Wallpapers")
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

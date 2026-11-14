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
    readonly property var setCommand: Constants.WALLPAPER_SET_CMD.map(PathUtils.expandHome)
    readonly property string defaultDirectory: PathUtils.expandHome(Constants.WALLPAPER_DIR)

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
    readonly property var images: folder.images
    readonly property bool scanning: folder.scanning
    // the folder couldn't be read
    readonly property bool missing: folder.missing
    // "Browse…" for another folder (the chooser is looked for each time the picker opens), and
    // whether it's open (the picker lets go of the keyboard meanwhile)
    readonly property bool canBrowse: chooser.available
    readonly property bool browsing: chooser.busy

    function openDialog(screenName) {
        preview = "";
        // stay on this screen, even if focus moves to another one while it is open
        dialogScreen = screenName || Screens.focused;
        // before it shows, so the grid doesn't build tiles for the old list first
        folder.scan();
        dialogOpen = true;
        chooser.check();
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

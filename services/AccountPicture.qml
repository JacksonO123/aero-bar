pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/path.js" as PathUtils
import "../utils/constants.js" as Constants

// Your account picture, like Win7's "Change Your Picture": one of the pictures in
// ACCOUNT_PICTURES_DIR (utils/constants.js), or any other you browse for. It shows in the start
// menu and on the lock screen, and AccountsService gets a copy for the login screen.
//
// Open the picker by clicking your picture in the start menu, or with:
//   qs ipc call accountpicture open
Singleton {
    id: root

    readonly property string directory: PathUtils.expandHome(Constants.ACCOUNT_PICTURES_DIR)

    // the picture you chose, "" until you choose one (the start menu shows ~/.face or
    // AccountsService's picture then). `saved` can be gone while the shell is torn down.
    readonly property string picture: saved?.picture ?? ""

    // ---- the picker -------------------------------------------------------------------------

    property bool dialogOpen: false
    property string dialogScreen: ""
    // where the dialog shows (dialogScreen, or the focused screen if that one is gone)
    readonly property string screen: Screens.resolve(dialogScreen)

    // the picture clicked in the picker (or browsed for), "" if none yet
    property string selection: ""

    // the pictures to choose from, sorted by name
    readonly property var images: folder.images
    readonly property bool scanning: folder.scanning
    // the folder couldn't be read
    readonly property bool missing: folder.missing
    // "Browse for more pictures…" (the chooser is looked for each time the picker opens)
    readonly property bool canBrowse: chooser.available

    function openDialog(screenName) {
        selection = "";
        // stay on this screen, even if focus moves to another one while it is open
        dialogScreen = screenName || Screens.focused;
        // before it shows, so the grid doesn't build tiles for an old list first
        folder.scan();
        dialogOpen = true;
        chooser.check();
    }

    function select(path) {
        selection = path;
    }

    // "Change Picture"
    function save() {
        if (selection !== "") {
            saved.picture = selection;
            // the login screen reads AccountsService's copy (it can't read your home directory)
            Quickshell.execDetached(["sh", "-c", `command -v busctl >/dev/null || exit 0
busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User SetIconFile s "$1"`, "sh", selection]);
        }
        selection = "";
        dialogOpen = false;
    }

    function cancel() {
        selection = "";
        dialogOpen = false;
    }

    function browse() {
        chooser.chooseFile(PathUtils.expandHome("~/Pictures"), "Pictures", folder.types);
    }

    PictureFolder {
        id: folder
        directory: root.directory
    }

    FileChooser {
        id: chooser
        onChosen: path => root.select(path)
    }

    FileView {
        path: Quickshell.statePath("account.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: saved

            property string picture: ""
        }
    }

    IpcHandler {
        target: "accountpicture"

        function open(): void {
            root.openDialog("");
        }
    }
}

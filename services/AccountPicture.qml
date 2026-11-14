pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/path.js" as PathUtils
import "../utils/constants.js" as Constants

// Your account picture, like Win7's "Change Your Picture": one of the pictures in
// ACCOUNT_PICTURES_DIR (utils/constants.js), or any other you browse for. The shell keeps a copy
// of it (in its state directory), which shows in the start menu and on the lock screen, and
// AccountsService gets that copy for the login screen.
//
// Open the picker by clicking your picture in the start menu, or with:
//   qs ipc call accountpicture open
Singleton {
    id: root

    readonly property string directory: PathUtils.expandHome(Constants.ACCOUNT_PICTURES_DIR)

    // the copy of the picture you chose, "" until you choose one (the start menu shows ~/.face
    // or AccountsService's picture then). `saved` can be gone while the shell is torn down.
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
    // "Browse for more pictures…" (the chooser is looked for each time the picker opens), and
    // whether it's open (the picker lets go of the keyboard meanwhile)
    readonly property bool canBrowse: chooser.available
    readonly property bool browsing: chooser.busy

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

    // "Change Picture": keep a copy (named anew each time, so the pictures showing it reload)
    function save() {
        if (selection !== "") {
            keeper.command = ["sh", "-c", keepScript, "sh", selection, Quickshell.statePath(`account-picture-${Date.now()}`)];
            keeper.running = true;
        }
        selection = "";
        dialogOpen = false;
    }

    function cancel() {
        selection = "";
        dialogOpen = false;
    }

    function browse() {
        chooser.chooseFile(PathUtils.pathRelativeToHome("Pictures"), "Pictures", folder.types);
    }

    PictureFolder {
        id: folder
        directory: root.directory
    }

    FileChooser {
        id: chooser
        // (a picture chosen after the picker was closed is dropped)
        onChosen: path => {
            if (root.dialogOpen) {
                root.select(path);
            }
        }
    }

    // ---- keeping the picture --------------------------------------------------------------------

    // copies $1 to $2 (plus its extension), drops the older copies and prints the new one's path.
    // With ImageMagick it's a PNG of at most 512 px, small enough for AccountsService (it refuses
    // icons over 1 MB). AccountsService then stores a copy of its own for the login screen, which
    // can't read your home directory (it would only note the path of a picture under /usr/share).
    readonly property string keepScript: `src=$1 base=$2
mkdir -p "$(dirname "$base")" || exit 1
if command -v magick >/dev/null; then
    dest=$base.png; magick "$src[0]" -thumbnail '512x512>' "$dest" || exit 1
elif command -v convert >/dev/null; then
    dest=$base.png; convert "$src[0]" -thumbnail '512x512>' "$dest" || exit 1
else
    name=\${src##*/}
    case $name in *.*) dest=$base.\${name##*.} ;; *) dest=$base ;; esac
    cp "$src" "$dest" || exit 1
fi
for old in "\${base%-*}"-*; do [ "$old" = "$dest" ] || rm -f "$old"; done
echo "$dest"
command -v busctl >/dev/null && busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User SetIconFile s "$dest" >/dev/null 2>&1
exit 0`

    Process {
        id: keeper

        stdout: StdioCollector {
            onStreamFinished: {
                const copy = text.trim();
                if (copy !== "") {
                    saved.picture = copy;
                }
            }
        }
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

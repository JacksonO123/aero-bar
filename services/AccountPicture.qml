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
    // or AccountsService's picture then), and the picture it's a copy of (the picker shows that
    // one chosen). `saved` can be gone while the shell is torn down.
    readonly property string picture: saved?.picture ?? ""
    readonly property string source: saved?.source ?? ""

    // ---- the picker -------------------------------------------------------------------------

    property bool dialogOpen: false
    property string dialogScreen: ""
    // where the dialog shows (dialogScreen, or the focused screen if that one is gone)
    readonly property string screen: Screens.resolve(dialogScreen)

    // the picture clicked in the picker (or browsed for), "" if none yet
    property string selection: ""
    // the picture being kept (Change Picture was clicked and its copy isn't made yet), else ""
    property string saving: ""

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

    // "Change Picture": keep a copy (named anew each time, so the pictures showing it reload; a
    // copy still being made for an earlier choice is dropped)
    function save() {
        if (selection !== "") {
            keeper.running = false;
            saving = selection;
            keeper.command = ["sh", "-c", keepScript, "sh", selection, Quickshell.statePath("account-picture"), String(Date.now())];
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

    // copies $1 to $2-$3, drops the older copies and prints the copy's path and $1 (nothing if
    // it fails). When ImageMagick can read it, the copy is a PNG of at most 512 px, small enough
    // for AccountsService (it refuses icons over 1 MB); otherwise it's the picture as it is.
    // AccountsService then stores a copy of its own for the login screen, which can't read your
    // home directory (it would only note the path of a picture under /usr/share).
    readonly property string keepScript: `src=$1 prefix=$2 base=$2-$3
mkdir -p "$(dirname "$base")" || exit 1
if im=$(command -v magick || command -v convert) && "$im" "$src[0]" -thumbnail '512x512>' "$base.png" 2>/dev/null; then
    dest=$base.png
else
    rm -f "$base.png"
    name=\${src##*/}
    case $name in *.*) dest=$base.\${name##*.} ;; *) dest=$base ;; esac
    cp "$src" "$dest" || exit 1
fi
for old in "$prefix"-*; do [ "$old" = "$dest" ] || rm -f "$old"; done
printf '%s\\n%s\\n' "$dest" "$src"
command -v busctl >/dev/null && busctl call org.freedesktop.Accounts "/org/freedesktop/Accounts/User$(id -u)" org.freedesktop.Accounts.User SetIconFile s "$dest" >/dev/null 2>&1 &
exit 0`

    Process {
        id: keeper

        // the copy, and the picture it came from (the picker shows that one chosen)
        stdout: StdioCollector {
            onStreamFinished: {
                const [copy, source] = text.split("\n");
                if (copy && source) {
                    saved.picture = copy;
                    saved.source = source;
                }
                root.saving = "";
            }
        }

        onExited: code => {
            if (code !== 0) {
                root.saving = "";
            }
        }
    }

    FileView {
        path: Quickshell.statePath("account.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: saved

            property string picture: ""
            property string source: ""
        }
    }

    IpcHandler {
        target: "accountpicture"

        function open(): void {
            root.openDialog("");
        }
    }
}

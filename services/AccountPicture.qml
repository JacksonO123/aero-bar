pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/path.js" as PathUtils
import "../utils/constants.js" as Constants

// Open from outside: qs ipc call accountpicture open
Singleton {
    id: root

    readonly property string directory: PathUtils.expandHome(Constants.ACCOUNT_PICTURES_DIR)

    // `saved` can be gone while the shell is torn down
    readonly property string picture: saved?.picture ?? ""
    readonly property string source: saved?.source ?? ""

    property bool dialogOpen: false
    property string dialogScreen: ""
    readonly property string screen: Screens.resolve(dialogScreen)

    property string selection: ""
    property string saving: ""

    readonly property var images: folder.images
    readonly property bool scanning: folder.scanning
    readonly property bool canBrowse: chooser.available
    readonly property bool browsing: chooser.busy

    function openDialog(screenName) {
        selection = "";
        dialogScreen = screenName || Screens.focused;
        // before dialogOpen, so the grid doesn't build tiles for a stale list
        folder.scan();
        dialogOpen = true;
        chooser.check();
    }

    function select(path) {
        selection = path;
    }

    // a new file name each time, or Images showing the picture won't reload
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
        onChosen: path => {
            if (root.dialogOpen) {
                root.select(path);
            }
        }
    }

    // at most 512 px: AccountsService refuses icons over 1 MB
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

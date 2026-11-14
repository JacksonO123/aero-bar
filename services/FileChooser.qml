import Quickshell
import Quickshell.Io
import QtQuick

// The desktop's own file chooser (zenity or kdialog, whichever is installed) for "Browse…".
// check() looks for one; chooseFolder() / chooseFile() open it, and `chosen` gives the path.
Scope {
    id: root

    // the chooser found by check(), "" if there's none (hide "Browse…" then)
    property string tool: ""
    readonly property bool available: tool !== ""
    readonly property bool isKdialog: tool.endsWith("kdialog")
    // it's open
    readonly property bool busy: dialog.running

    signal chosen(string path)

    function check() {
        finder.running = true;
    }

    function chooseFolder(start) {
        open(isKdialog ? [tool, "--getexistingdirectory", start] : [tool, "--file-selection", "--directory", `--filename=${start}/`]);
    }

    // `name` and `types` make the filter, e.g. "Pictures", ["png", "jpg"] (upper case too: GTK's
    // patterns are case-sensitive, and cameras write IMG_0001.JPG)
    function chooseFile(start, name, types) {
        const patterns = types.map(t => `*.${t} *.${t.toUpperCase()}`).join(" ");
        open(isKdialog ? [tool, "--getopenfilename", start, `${name} (${patterns})`] : [tool, "--file-selection", `--filename=${start}/`, `--file-filter=${name} | ${patterns}`]);
    }

    function open(command) {
        if (available) {
            dialog.command = command;
            dialog.running = true;
        }
    }

    Process {
        id: finder
        command: ["sh", "-c", "command -v zenity || command -v kdialog"]

        stdout: StdioCollector {
            onStreamFinished: root.tool = text.trim().split("\n")[0]
        }
    }

    Process {
        id: dialog

        // prints the chosen path
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path !== "") {
                    root.chosen(path);
                }
            }
        }
    }
}

import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    property string tool: ""
    readonly property bool available: tool !== ""
    readonly property bool isKdialog: tool.endsWith("kdialog")
    readonly property bool busy: dialog?.running ?? false

    signal chosen(string path)

    function check() {
        finder.running = true;
    }

    function chooseFolder(start) {
        open(isKdialog ? [tool, "--getexistingdirectory", start] : [tool, "--file-selection", "--directory", `--filename=${start}/`]);
    }

    // GTK patterns are case-sensitive (cameras write .JPG): match any case
    function chooseFile(start, name, types) {
        const anyCase = type => type.split("").map(c => `[${c}${c.toUpperCase()}]`).join("");
        const patterns = types.map(t => `*.${anyCase(t)}`).join(" ");
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

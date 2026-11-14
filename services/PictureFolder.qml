import Quickshell
import Quickshell.Io
import QtQuick

// The pictures in a folder (and the folders below it, three deep), sorted by name. Reads the
// folder on scan().
Scope {
    id: root

    required property string directory

    // the file types it finds (also the filter for picking a single picture)
    readonly property var types: ["jpg", "jpeg", "png", "webp", "bmp", "gif"]

    // full paths
    property var images: []
    property bool scanning: false
    // the folder couldn't be read
    property bool missing: false

    function scan() {
        images = [];
        missing = false;
        scanning = true;
        scanner.running = false;
        scanner.running = true;
    }

    // a script listing the pictures under $1 (exit status 3: the folder isn't there or can't be
    // read)
    function findScript() {
        const names = types.map(t => `-iname "*.${t}"`).join(" -o ");
        return `test -d "$1" && test -r "$1" || exit 3; find -L "$1" -maxdepth 3 -type f \\( ${names} \\) 2>/dev/null`;
    }

    Process {
        id: scanner

        command: ["sh", "-c", root.findScript(), "sh", root.directory]

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
}

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

    // full paths, in natural order ("2.jpg" before "10.jpg")
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
                // Qt's localeCompare ignores options like `numeric`, so pad the numbers instead
                const keyed = text.split("\n").filter(line => line !== "").map(path => ({
                            path,
                            key: path.replace(/\d+/g, n => n.padStart(12, "0"))
                        }));
                root.images = keyed.sort((a, b) => a.key.localeCompare(b.key)).map(entry => entry.path);
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

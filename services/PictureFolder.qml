import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root

    required property string directory

    readonly property var types: ["jpg", "jpeg", "png", "webp", "bmp", "gif"]

    property var images: []
    property bool scanning: false
    property bool missing: false

    // the saved folder can be read after a scan started: rescan
    onDirectoryChanged: {
        if (scanning) {
            scan();
        }
    }

    function scan() {
        images = [];
        missing = false;
        scanning = true;
        scanner.running = false;
        scanner.running = true;
    }

    function findScript() {
        const names = types.map(t => `-iname "*.${t}"`).join(" -o ");
        return `test -d "$1" && test -r "$1" || exit 3; printf '%s\\n' "$1"; find -L "$1" -maxdepth 3 -type f \\( ${names} \\) 2>/dev/null`;
    }

    Process {
        id: scanner

        command: ["sh", "-c", root.findScript(), "sh", root.directory]

        stdout: StdioCollector {
            onStreamFinished: {
                // a scan killed for a newer one still reports its partial output: skip it
                if (!text.startsWith(root.directory + "\n")) {
                    return;
                }

                const paths = text.slice(root.directory.length + 1).split("\n");

                // Qt's localeCompare ignores `numeric`, so pad the numbers instead
                const keyed = paths.filter(line => line !== "").map(path => ({
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

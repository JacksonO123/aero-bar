pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import "../utils/path.js" as PathUtils
import "../utils/constants.js" as Constants

// Everything the start menu needs that isn't drawing: which screen it is open on, the user,
// launch history ("frequent programs"), search and the All Programs categories.
//
// Open it from hyprland with either of:
//   bindr = SUPER, SUPER_L, global, quickshell:startmenu
//   bind  = SUPER, D, exec, qs ipc call startmenu toggle
Singleton {
    id: root

    property bool open: false
    property string screenName: ""
    property double closedAt: 0

    // ---- editable lists ------------------------------------------------------------------------

    // shown (in this order) until there is enough launch history to fill the list
    property var defaultApps: ["google-chrome", "Alacritty", "org.kde.dolphin", "spotify", "code", "firefox", "steam", "discord"]
    property int maxFrequent: 9

    function userDir(kind, fallback) {
        return ["sh", "-c", `d=$(xdg-user-dir ${kind} 2>/dev/null); xdg-open "\${d:-$HOME/${fallback}}"`];
    }

    property var places: [
        {
            label: "Documents",
            icon: "folder-documents",
            command: userDir("DOCUMENTS", "Documents")
        },
        {
            label: "Pictures",
            icon: "folder-pictures",
            command: userDir("PICTURES", "Pictures")
        },
        {
            label: "Music",
            icon: "folder-music",
            command: userDir("MUSIC", "Music")
        },
        {
            label: "Downloads",
            icon: "folder-download",
            command: userDir("DOWNLOAD", "Downloads")
        }
    ]

    property var systemLinks: [
        {
            label: "Computer",
            icon: "computer",
            command: ["xdg-open", "/"]
        },
        {
            label: "Control Panel",
            icon: "preferences-system",
            command: [PathUtils.pathRelativeToHome(".local/bin/control-center")]
        },
        {
            label: "Terminal",
            icon: "utilities-terminal",
            command: ["alacritty"]
        }
    ]

    property var shutdownCommand: ["systemctl", "poweroff"]
    property var powerActions: [
        {
            label: "Lock",
            command: ["loginctl", "lock-session"]
        },
        {
            label: "Log off",
            // the Lua config takes Lua dispatchers over IPC
            command: Hyprland.usingLua ? ["hyprctl", "dispatch", "hl.dsp.exit()"] : ["hyprctl", "dispatch", "exit"]
        },
        {
            label: "Sleep",
            command: ["systemctl", "suspend"]
        },
        {
            label: "Restart",
            command: ["systemctl", "reboot"]
        }
    ]

    // ---- open / close --------------------------------------------------------------------------

    function show(screen) {
        screenName = screen || (Hyprland.focusedMonitor?.name ?? "");
        open = true;
    }

    function close() {
        if (open) {
            open = false;
            closedAt = Date.now();
        }
    }

    function toggle(screen) {
        if (open) {
            close();
        } else if (Date.now() - closedAt > 300) {
            // a click on the orb that just dismissed the menu (outside click) must not reopen it
            show(screen);
        }
    }

    GlobalShortcut {
        name: "startmenu"
        description: "Toggle the Aero start menu"
        onPressed: root.toggle("")
    }

    IpcHandler {
        target: "startmenu"

        function toggle(): void {
            root.toggle("");
        }

        function show(): void {
            root.show("");
        }

        function hide(): void {
            root.close();
        }
    }

    // ---- the user ------------------------------------------------------------------------------

    property string userName: Quickshell.env("USER") ?? "user"
    property string fullName: ""
    property string picture: ""
    readonly property string displayName: fullName || userName

    Process {
        running: true
        command: ["sh", "-c", 'echo "name:$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)"; ' + 'for f in "$HOME/.face" "$HOME/.face.icon" "/var/lib/AccountsService/icons/$USER"; do ' + 'if [ -r "$f" ] && [ -s "$f" ]; then echo "pic:$f"; break; fi; done']

        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.split("\n")) {
                    if (line.startsWith("name:")) {
                        root.fullName = line.slice(5).trim();
                    } else if (line.startsWith("pic:")) {
                        root.picture = line.slice(4).trim();
                    }
                }
            }
        }
    }

    // ---- launching + history -------------------------------------------------------------------

    FileView {
        id: historyFile
        path: Quickshell.statePath("start-menu.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: history
            property var counts: ({})
        }
    }

    function run(command) {
        Quickshell.execDetached(command);
        close();
    }

    function launch(entry) {
        if (!entry) {
            return;
        }

        if (entry.runInTerminal) {
            Quickshell.execDetached(Constants.TERMINAL_CMD.concat(entry.command));
        } else {
            entry.execute();
        }

        const counts = Object.assign({}, history?.counts ?? {});
        counts[entry.id] = (counts[entry.id] ?? 0) + 1;
        history.counts = counts;
        close();
    }

    readonly property var applications: DesktopEntries.applications.values

    readonly property var frequentApps: {
        const counts = history?.counts ?? {};
        const byId = new Map(applications.map(e => [e.id, e]));
        const list = Object.keys(counts).filter(id => byId.has(id)).sort((a, b) => counts[b] - counts[a]).map(id => byId.get(id));

        for (const name of defaultApps) {
            if (list.length >= maxFrequent) {
                break;
            }
            const entry = DesktopEntries.heuristicLookup(name);
            if (entry && !list.some(e => e.id === entry.id)) {
                list.push(entry);
            }
        }

        return list.slice(0, maxFrequent);
    }

    function search(query) {
        const q = query.trim().toLowerCase();
        if (q === "") {
            return [];
        }

        const counts = history?.counts ?? {};
        const scored = [];
        for (const e of applications) {
            const name = (e.name ?? "").toLowerCase();
            let score = -1;
            if (name.startsWith(q)) {
                score = 100;
            } else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) {
                score = 80;
            } else if (name.includes(q)) {
                score = 60;
            } else if ((e.genericName ?? "").toLowerCase().includes(q)) {
                score = 40;
            } else if ((e.keywords ?? []).some(k => String(k).toLowerCase().startsWith(q))) {
                score = 30;
            } else if ((e.comment ?? "").toLowerCase().includes(q)) {
                score = 10;
            }

            if (score >= 0) {
                scored.push({
                    entry: e,
                    score: score + Math.min(15, counts[e.id] ?? 0) - name.length * 0.05
                });
            }
        }

        return scored.sort((a, b) => b.score - a.score).slice(0, 10).map(s => s.entry);
    }

    // freedesktop main categories -> Win7-ish folder names
    readonly property var categoryNames: [["AudioVideo", "Multimedia"], ["Audio", "Multimedia"], ["Video", "Multimedia"], ["Development", "Development"], ["Game", "Games"], ["Graphics", "Graphics"], ["Network", "Internet"], ["Office", "Office"], ["Education", "Education"], ["Science", "Science"], ["Settings", "Settings"], ["System", "System Tools"], ["Utility", "Accessories"]]

    readonly property var categories: {
        const groups = {};
        for (const e of applications) {
            const cats = e.categories ?? [];
            const match = categoryNames.find(([key]) => cats.includes(key));
            const name = match ? match[1] : "Other";
            (groups[name] = groups[name] ?? []).push(e);
        }

        return Object.keys(groups).sort((a, b) => a === "Other" ? 1 : b === "Other" ? -1 : a.localeCompare(b)).map(name => ({
                    name,
                    entries: groups[name].sort((a, b) => a.name.localeCompare(b.name))
                }));
    }
}

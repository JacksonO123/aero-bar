pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// The glass colour every frame, flyout, menu and the taskbar share, like Windows 7's "Window
// Color and Appearance". The choice is saved to Quickshell.statePath("theme.json").
//
// Open the picker from the start menu ("Personalization") or with:
//   qs ipc call theme open
Singleton {
    id: root

    // Windows 7's colours; the alpha is each one's default intensity. Graphite is the shell's
    // original smoky glass and leaves the taskbar its own grey.
    readonly property var swatches: [
        {
            name: "Graphite",
            color: "#6b333333"
        },
        {
            name: "Sky",
            color: "#6b74b8fc"
        },
        {
            name: "Twilight",
            color: "#a80046ad"
        },
        {
            name: "Sea",
            color: "#8032cdcd"
        },
        {
            name: "Leaf",
            color: "#6614a600"
        },
        {
            name: "Lime",
            color: "#6697d937"
        },
        {
            name: "Sun",
            color: "#54fadc0e"
        },
        {
            name: "Pumpkin",
            color: "#80ff9c00"
        },
        {
            name: "Ruby",
            color: "#a8ce0f0f"
        },
        {
            name: "Fuchsia",
            color: "#66ff0099"
        },
        {
            name: "Blush",
            color: "#70fcc7f8"
        },
        {
            name: "Violet",
            color: "#856e3ba1"
        },
        {
            name: "Lavender",
            color: "#528d5a94"
        },
        {
            name: "Taupe",
            color: "#6698844c"
        },
        {
            name: "Chocolate",
            color: "#a84f1b1b"
        },
        {
            name: "Slate",
            color: "#80555555"
        },
        {
            name: "Frost",
            color: "#54fcfcfc"
        }
    ]

    // ---- current look (the picker previews by writing the `preview*` values) -------------------

    property bool previewing: false
    property string previewName: ""
    property color previewTint: "#333333"
    property real previewIntensity: 0.42
    property bool previewTransparency: true

    readonly property string colorName: previewing ? previewName : saved.name
    readonly property color tint: previewing ? previewTint : saved.tint
    readonly property real intensity: previewing ? previewIntensity : saved.intensity
    readonly property bool transparency: previewing ? previewTransparency : saved.transparency

    // the frame glass. Without transparency it becomes a solid mix of the colour and pale grey,
    // like Win7 with transparency turned off.
    readonly property color glassColor: transparency ? Qt.rgba(tint.r, tint.g, tint.b, intensity) : mix(Qt.rgba(0.78, 0.81, 0.85, 1), tint, Math.min(1, 0.25 + intensity))

    // laid over the taskbar's grey glass
    readonly property color barTint: colorName === "Graphite" ? "transparent" : Qt.rgba(tint.r, tint.g, tint.b, Math.min(0.85, intensity * (transparency ? 0.7 : 1.1)))

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    function swatch(name) {
        return swatches.find(s => s.name === name) ?? null;
    }

    // ---- picker --------------------------------------------------------------------------------

    property bool dialogOpen: false
    property string dialogScreen: ""

    function openDialog(screenName) {
        previewName = saved.name;
        previewTint = saved.tint;
        previewIntensity = saved.intensity;
        previewTransparency = saved.transparency;
        previewing = true;
        dialogScreen = screenName ?? "";
        dialogOpen = true;
    }

    function pick(name) {
        const s = swatch(name);
        if (!s) {
            return;
        }
        const c = Qt.color(s.color);
        previewName = name;
        previewTint = Qt.rgba(c.r, c.g, c.b, 1);
        previewIntensity = c.a;
    }

    function setCustom(color) {
        previewName = "Custom";
        previewTint = Qt.rgba(color.r, color.g, color.b, 1);
    }

    function save() {
        saved.name = previewName;
        saved.tint = previewTint.toString();
        saved.intensity = previewIntensity;
        saved.transparency = previewTransparency;
        previewing = false;
        dialogOpen = false;
    }

    function cancel() {
        previewing = false;
        dialogOpen = false;
    }

    FileView {
        path: Quickshell.statePath("theme.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: saved

            property string name: "Graphite"
            property string tint: "#333333"
            property real intensity: 0.42
            property bool transparency: true
        }
    }

    IpcHandler {
        target: "theme"

        function open(): void {
            root.openDialog("");
        }
    }
}

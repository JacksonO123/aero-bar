pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/colors.js" as ColorUtils

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

    // ---- current look (while the picker is open it previews the `preview*` values) -------------

    // the shell's original look, used until something is saved
    readonly property var defaults: ({
            name: "Graphite",
            tint: "#333333",
            intensity: 0.42,
            transparency: true
        })

    // set by openDialog() before they're read
    property string previewName
    property color previewTint
    property real previewIntensity
    property bool previewTransparency

    // `saved` can be gone while the shell is being torn down
    readonly property string colorName: dialogOpen ? previewName : saved?.name ?? defaults.name
    readonly property color tint: dialogOpen ? previewTint : saved?.tint ?? defaults.tint
    readonly property real intensity: dialogOpen ? previewIntensity : saved?.intensity ?? defaults.intensity
    readonly property bool transparency: dialogOpen ? previewTransparency : saved?.transparency ?? defaults.transparency

    // the frame glass. Without transparency it becomes a solid mix of the colour and pale grey,
    // like Win7 with transparency turned off.
    readonly property color glassColor: transparency ? Qt.rgba(tint.r, tint.g, tint.b, intensity) : ColorUtils.interpolateColors(Qt.rgba(0.78, 0.81, 0.85, 1), tint, 0.25 + intensity)

    // laid over the taskbar's grey glass
    readonly property color barTint: colorName === "Graphite" ? "transparent" : Qt.rgba(tint.r, tint.g, tint.b, Math.min(0.85, intensity * (transparency ? 0.7 : 1.1)))

    function swatch(name) {
        return swatches.find(s => s.name === name) ?? null;
    }

    // ---- picker --------------------------------------------------------------------------------

    property bool dialogOpen: false
    property string dialogScreen: ""
    // where the dialog actually shows (dialogScreen, or the focused screen if that one is gone)
    readonly property string screen: Screens.resolve(dialogScreen)

    function openDialog(screenName) {
        previewName = saved.name;
        previewTint = saved.tint;
        previewIntensity = saved.intensity;
        previewTransparency = saved.transparency;
        // stay on this screen, even if focus moves to another one while it is open
        dialogScreen = screenName || Screens.focused;
        dialogOpen = true;
        syncMix();
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
        syncMix();
    }

    // the colour mixer's hue / saturation / brightness. Kept here rather than read back from the
    // tint: a grey has no hue, which would lose it. Shared by the dialog on every screen.
    property var mix: ({
            hsvHue: 0,
            hsvSaturation: 0,
            hsvValue: 0
        })

    function syncMix() {
        const t = previewTint;
        mix = {
            hsvHue: t.hsvHue >= 0 ? t.hsvHue : mix.hsvHue,
            hsvSaturation: t.hsvSaturation,
            hsvValue: t.hsvValue
        };
    }

    function setMix(key, value) {
        const m = Object.assign({}, mix);
        m[key] = Math.min(0.999, value);
        mix = m;
        setCustom(Qt.hsva(m.hsvHue, m.hsvSaturation, m.hsvValue, 1));
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
        dialogOpen = false;
    }

    function cancel() {
        dialogOpen = false;
    }

    FileView {
        path: Quickshell.statePath("theme.json")
        onAdapterUpdated: writeAdapter()

        adapter: JsonAdapter {
            id: saved

            property string name: root.defaults.name
            property string tint: root.defaults.tint
            property real intensity: root.defaults.intensity
            property bool transparency: root.defaults.transparency
        }
    }

    IpcHandler {
        target: "theme"

        function open(): void {
            root.openDialog("");
        }
    }
}

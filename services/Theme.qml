pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "../utils/colors.js" as ColorUtils

// open the picker with: qs ipc call theme open
Singleton {
    id: root

    // #AARRGGBB: the alpha is each colour's default intensity
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

    readonly property var defaults: ({
            name: "Graphite",
            tint: "#333333",
            intensity: 0.42,
            transparency: true
        })

    property string previewName
    property color previewTint
    property real previewIntensity
    property bool previewTransparency

    // saved can be null while the shell is torn down
    readonly property string colorName: dialogOpen ? previewName : saved?.name ?? defaults.name
    readonly property color tint: dialogOpen ? previewTint : saved?.tint ?? defaults.tint
    readonly property real intensity: dialogOpen ? previewIntensity : saved?.intensity ?? defaults.intensity
    readonly property bool transparency: dialogOpen ? previewTransparency : saved?.transparency ?? defaults.transparency

    readonly property color glassColor: transparency ? Qt.rgba(tint.r, tint.g, tint.b, intensity) : ColorUtils.interpolateColors(Qt.rgba(0.78, 0.81, 0.85, 1), tint, 0.25 + intensity)

    readonly property color barTint: colorName === "Graphite" ? "transparent" : Qt.rgba(tint.r, tint.g, tint.b, Math.min(0.85, intensity * (transparency ? 0.7 : 1.1)))

    function swatch(name) {
        return swatches.find(s => s.name === name) ?? null;
    }

    property bool dialogOpen: false
    property string dialogScreen: ""
    readonly property string screen: Screens.resolve(dialogScreen)

    function openDialog(screenName) {
        previewName = saved.name;
        previewTint = saved.tint;
        previewIntensity = saved.intensity;
        previewTransparency = saved.transparency;
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

    // kept apart from the tint: a grey has no hue, so reading it back would lose it
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
        // 1.0 would wrap the hue back to red
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

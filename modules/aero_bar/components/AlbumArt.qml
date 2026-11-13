import QtQuick
import Quickshell.Widgets

// Album art tile with a Win7 thumbnail frame and two-tone sheen. Crossfades between tracks and
// falls back to the music orb when the player provides no art.
Item {
    id: root

    property string source: ""
    property real radius: 3

    property Image current: null
    property Image loading: null
    readonly property bool hasArt: current !== null

    onSourceChanged: load()
    Component.onCompleted: load()

    // two images crossfade: the next track's art loads into the hidden one, then fades in
    component ArtImage: Image {
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        mipmap: true
        opacity: 0
        sourceSize: Qt.size(Math.max(64, width * 2), Math.max(64, height * 2))

        Behavior on opacity {
            NumberAnimation {
                duration: 280
            }
        }
    }

    function load() {
        if (source === "") {
            clear();
            return;
        }

        const next = current === imageA ? imageB : imageA;
        loading = next;
        next.source = source;
        // the spare image may hold this URL already, so no status change is coming
        if (next.status === Image.Ready) {
            reveal(next);
        } else if (next.status === Image.Error) {
            clear();
        }
    }

    function reveal(image) {
        if (current && current !== image) {
            current.opacity = 0;
        }
        image.opacity = 1;
        current = image;
        loading = null;
    }

    function imageStatusChanged(image) {
        if (image.status === Image.Ready && loading === image) {
            reveal(image);
        } else if (image.status === Image.Error && loading === image) {
            clear();
        }
    }

    // no art: fade it out and let the music orb show
    function clear() {
        loading = null;
        if (current) {
            current.opacity = 0;
        }
        current = null;
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: root.radius
        color: "#1d3346"

        Rectangle {
            anchors.fill: parent
            opacity: root.hasArt ? 0 : 1

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#eef7fd"
                }
                GradientStop {
                    position: 1.0
                    color: "#b4d0e4"
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 260
                }
            }

            // the asset includes its own reflection underneath; crop to the top half
            Image {
                anchors.centerIn: parent
                width: parent.width * 0.8
                height: width
                source: Qt.resolvedUrl("../../../assets/music-icon-reflect.png")
                fillMode: Image.PreserveAspectCrop
                verticalAlignment: Image.AlignTop
                sourceSize.width: width * 2
                mipmap: true
            }
        }

        ArtImage {
            id: imageA
            onStatusChanged: root.imageStatusChanged(imageA)
        }

        ArtImage {
            id: imageB
            onStatusChanged: root.imageStatusChanged(imageB)
        }

        Rectangle {
            anchors.fill: parent

            gradient: SplitGradient {
                split: 0.47
                splitEnd: 0.471
                colors: [Qt.rgba(1, 1, 1, 0.4), Qt.rgba(1, 1, 1, 0.12), Qt.rgba(1, 1, 1, 0.0), Qt.rgba(1, 1, 1, 0.0)]
            }
        }
    }

    Bevel {
        anchors.fill: parent
        radius: root.radius
        outerColor: Qt.rgba(0, 0, 0, 0.55)
        innerColor: Qt.rgba(1, 1, 1, 0.35)
    }
}

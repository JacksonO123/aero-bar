import QtQuick
import Quickshell.Widgets

// Album art tile with a Win7 thumbnail frame and two-tone sheen. Crossfades between tracks and
// falls back to the music orb when the player provides no art.
Item {
    id: root

    property string source: ""
    property real radius: 3
    property bool showSheen: true
    property bool showFrame: true

    property Image current: null
    property Image loading: null
    readonly property bool hasArt: current !== null

    onSourceChanged: load()
    Component.onCompleted: load()

    function load() {
        if (source === "") {
            loading = null;
            if (current) {
                current.opacity = 0;
            }
            current = null;
            return;
        }

        const next = current === imageA ? imageB : imageA;
        loading = next;
        next.source = source;
        if (next.status === Image.Ready) {
            reveal(next);
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

    function failed(image) {
        if (loading !== image) {
            return;
        }
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

        Image {
            id: imageA
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            opacity: 0
            sourceSize: Qt.size(Math.max(64, root.width * 2), Math.max(64, root.height * 2))

            onStatusChanged: {
                if (status === Image.Ready && root.loading === imageA) {
                    root.reveal(imageA);
                } else if (status === Image.Error) {
                    root.failed(imageA);
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 280
                }
            }
        }

        Image {
            id: imageB
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            opacity: 0
            sourceSize: Qt.size(Math.max(64, root.width * 2), Math.max(64, root.height * 2))

            onStatusChanged: {
                if (status === Image.Ready && root.loading === imageB) {
                    root.reveal(imageB);
                } else if (status === Image.Error) {
                    root.failed(imageB);
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 280
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: root.showSheen

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, 0.4)
                }
                GradientStop {
                    position: 0.47
                    color: Qt.rgba(1, 1, 1, 0.12)
                }
                GradientStop {
                    position: 0.471
                    color: Qt.rgba(1, 1, 1, 0.0)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(1, 1, 1, 0.0)
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        visible: root.showFrame
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.55)
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        visible: root.showFrame
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.35)
    }
}

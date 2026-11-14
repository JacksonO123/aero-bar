import QtQuick
import "../../../utils/path.js" as PathUtils

// One picture in a picker's grid (Desktop Background, Change Your Picture): a framed thumbnail
// with a soft shadow and a touch of gloss that lifts a little under the pointer, with Win7's
// blue selection, an aqua glow and a glossy green tick when it's the chosen one. Size it to the
// grid's cells.
Item {
    id: root

    property string path: ""
    property bool selected: false

    signal clicked
    signal doubleClicked

    HoverPress {
        id: hp
        hovered: mouse.containsMouse
    }

    RowHighlight {
        anchors.fill: parent
        anchors.margins: 1
        glass: true
        hot: mouse.containsMouse
        selected: root.selected
    }

    // the framed picture, with its shadow, raised a touch under the pointer
    Item {
        id: card
        anchors.fill: parent
        scale: 1 + hp.hoverT * 0.035

        // an aqua glow around the chosen picture (only built there)
        Loader {
            anchors.fill: frame
            active: root.selected

            sourceComponent: SoftGlow {
                spread: 9
                grow: 3
                opacity: 0.8
            }
        }

        Shadow {
            offset: 2 + hp.hoverT * 2
            color: Qt.rgba(0, 0.05, 0.12, 0.06 + hp.hoverT * 0.04)
        }

        Shadow {
            offset: 1 + hp.hoverT
            color: Qt.rgba(0, 0.05, 0.12, 0.14)
        }

        // the thumbnail, in a thin frame
        Rectangle {
            id: frame
            x: 8
            y: 8
            width: parent.width - 16
            height: parent.height - 16
            color: "#e9edf1"
            border.width: 1
            border.color: "#a3acb6"

            Image {
                id: picture
                anchors.fill: parent
                anchors.margins: 2
                source: PathUtils.fileUrl(root.path)
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                mipmap: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200
                    }
                }
            }

            // a light two-tone gloss over the top of the picture
            Rectangle {
                x: picture.x
                y: picture.y
                width: picture.width
                height: picture.height * 0.46
                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: Qt.rgba(1, 1, 1, 0.22)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(1, 1, 1, 0.05)
                    }
                }
            }

            // a faint inner highlight over the picture's edge
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.6)
            }
        }
    }

    // a soft shadow under the frame, deeper while it's raised
    component Shadow: Rectangle {
        property real offset: 1
        x: 8
        y: 8 + offset
        width: parent.width - 16
        height: parent.height - 16
    }

    // a glossy green tick on the chosen picture, popping in (only built there)
    Loader {
        x: 2
        y: 2
        active: root.selected

        sourceComponent: GlassOrb {
            size: 22
            lightColor: "#d6ffbc"
            baseColor: "#3db51f"
            darkColor: "#0f4d06"
            glowColor: Qt.rgba(0.85, 1, 0.7, 0.9)

            NumberAnimation on scale {
                from: 0.3
                to: 1
                duration: 260
                easing.type: Easing.OutBack
            }

            Canvas {
                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const w = width, h = height;
                    ctx.beginPath();
                    ctx.moveTo(w * 0.28, h * 0.52);
                    ctx.lineTo(w * 0.44, h * 0.68);
                    ctx.lineTo(w * 0.73, h * 0.34);
                    ctx.lineWidth = 2.4;
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";
                    ctx.strokeStyle = "white";
                    ctx.stroke();
                }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
        onDoubleClicked: root.doubleClicked()
    }
}

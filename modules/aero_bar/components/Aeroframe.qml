import QtQuick
import QtQuick.Effects

Item {
    id: root

    default property alias content: contentHolder.data

    readonly property bool hovered: hoverHandler.hovered

    property real frameOpacity: 1

    property int frameWidth: 8
    property int topFrameWidth: 8
    property real radius: 6
    property real contentRadius: 4
    property bool clipContent: true
    // false: no inset content well, the whole frame is glass (e.g. the start menu)
    property bool showContentFrame: true

    //   Sky #6b74b8fc
    //   Twilight #a80046ad
    //   Sea #8032cdcd
    //   Leaf #6614a600
    //   Lime #6697d937
    //   Sun #54fadc0e
    //   Pumpkin #80ff9c00
    //   Ruby #a8ce0f0f
    //   Fuchsia #66ff0099
    //   Blush #70fcc7f8
    //   Violet #856e3ba1
    //   Lavender #528d5a94
    //   Taupe #6698844c
    //   Chocolate #a84f1b1b
    //   Slate #80555555
    //   Frost #54fcfcfc
    property color glassColor: "#6b333333"

    // property color glassColor: "#6b74b8fc"
    // property color glassColor: "#a80046ad"
    // property color glassColor: "#8032cdcd"
    // property color glassColor: "#6614a600"
    // property color glassColor: "#6697d937"
    // property color glassColor: "#54fadc0e"
    // property color glassColor: "#80ff9c00"
    // property color glassColor: "#a8ce0f0f"
    // property color glassColor: "#66ff0099"
    // property color glassColor: "#70fcc7f8"
    // property color glassColor: "#856e3ba1"
    // property color glassColor: "#528d5a94"
    // property color glassColor: "#6698844c"
    // property color glassColor: "#a84f1b1b"
    // property color glassColor: "#80555555"
    // property color glassColor: "#54fcfcfc"

    property color outlineColor: Qt.rgba(0, 0, 0, 0.6)
    property color highlightColor: Qt.rgba(1, 1, 1, 0.5)

    property real sheenTopOpacity: 0.12
    property real sheenPeakOpacity: 0.45
    property real sheenPeak: 0.42
    property real sheenFade: 0.05

    property real shadeOpacity: 0.5
    property real glareOpacity: 0.4

    property color contentColor: "#f0f0f0"

    implicitWidth: contentHolder.childrenRect.width + frameWidth * 2 + 2
    implicitHeight: contentHolder.childrenRect.height + topFrameWidth + frameWidth + 2

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: root.glassColor
        opacity: root.frameOpacity
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        visible: root.shadeOpacity > 0
        opacity: root.frameOpacity

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop {
                position: 0.0
                color: Qt.rgba(1, 1, 1, 0.4 * root.shadeOpacity)
            }
            GradientStop {
                position: 0.5
                color: Qt.rgba(0, 0, 0, 0.1 * root.shadeOpacity)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(1, 1, 1, 0.2 * root.shadeOpacity)
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        opacity: root.frameOpacity

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.rgba(1, 1, 1, root.sheenTopOpacity)
            }
            GradientStop {
                position: root.sheenPeak
                color: Qt.rgba(1, 1, 1, root.sheenPeakOpacity)
            }
            GradientStop {
                position: Math.min(0.999, root.sheenPeak + Math.max(0.005, root.sheenFade))
                color: Qt.rgba(1, 1, 1, 0)
            }
            GradientStop {
                position: 1.0
                color: Qt.rgba(1, 1, 1, 0)
            }
        }
    }

    Canvas {
        id: stripes
        anchors.fill: parent
        visible: root.glareOpacity > 0
        opacity: root.frameOpacity

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        Connections {
            target: root
            function onRadiusChanged() {
                stripes.requestPaint();
            }
            function onGlareOpacityChanged() {
                stripes.requestPaint();
            }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            if (root.glareOpacity <= 0 || width <= 0 || height <= 0)
                return;

            var radius = Math.max(0, root.radius - 1);
            ctx.beginPath();
            ctx.roundedRect(1, 1, width - 2, height - 2, radius, radius);
            ctx.clip();

            var alpha = root.glareOpacity;
            var reach = Math.max(width, height) * 0.7;

            var gradient = ctx.createLinearGradient(0, 0, 0, reach);
            gradient.addColorStop(0, Qt.rgba(1, 1, 1, 0.30 * alpha));
            gradient.addColorStop(1, Qt.rgba(1, 1, 1, 0.02 * alpha));
            ctx.fillStyle = gradient;

            var a1 = reach * 0.45;
            var b1 = reach * 0.55;
            var b2 = reach * 0.85;

            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(a1, 0);
            ctx.lineTo(0, a1);
            ctx.closePath();
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(b1, 0);
            ctx.lineTo(b2, 0);
            ctx.lineTo(0, b2);
            ctx.lineTo(0, b1);
            ctx.closePath();
            ctx.fill();
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: root.outlineColor
        opacity: root.frameOpacity
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, root.radius - 1)
        color: "transparent"
        border.width: 1
        border.color: root.highlightColor
        opacity: root.frameOpacity
    }

    Rectangle {
        anchors.fill: contentFrame
        anchors.margins: -1
        radius: root.contentRadius + 1
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.4)
        opacity: root.frameOpacity
        visible: root.showContentFrame
    }

    Rectangle {
        id: contentFrame
        anchors {
            fill: parent
            leftMargin: root.frameWidth
            rightMargin: root.frameWidth
            topMargin: root.topFrameWidth
            bottomMargin: root.frameWidth
        }
        radius: root.contentRadius
        color: root.showContentFrame ? root.contentColor : "transparent"
        border.width: root.showContentFrame ? 1 : 0
        border.color: Qt.rgba(0, 0, 0, 0.6)
        opacity: root.frameOpacity

        Item {
            id: contentHolder
            anchors.fill: parent
            anchors.margins: 1

            layer.enabled: root.clipContent && root.contentRadius > 1
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: contentMask
            }
        }

        Item {
            id: contentMask
            anchors.fill: contentHolder
            visible: false
            layer.enabled: true

            Rectangle {
                anchors.fill: parent
                radius: Math.max(0, root.contentRadius - 1)
                color: "black"
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        blocking: false
    }
}

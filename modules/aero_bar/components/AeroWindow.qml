import QtQuick
import QtQuick.Effects

// A Windows 7 dialog: a glass frame with a caption and close button around a white client area.
// Leave `shadowMargin` px around it free inside its window for the drop shadow.
Item {
    id: root

    default property alias content: frame.content
    property string title: ""

    signal closeClicked

    // drop shadow
    Rectangle {
        anchors.fill: frame
        radius: frame.radius
        color: "black"
        opacity: frame.frameOpacity
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.7)
            shadowBlur: 1
            shadowVerticalOffset: 5
        }
    }

    Aeroframe {
        id: frame
        anchors.fill: parent
        radius: 7
        frameWidth: 8
        topFrameWidth: 30
        contentRadius: 2
        contentColor: "white"
    }

    CaptionText {
        x: 12
        y: 8
        text: root.title
    }

    CloseButton {
        anchors.right: parent.right
        anchors.rightMargin: 6
        y: 1
        onClicked: root.closeClicked()
    }
}

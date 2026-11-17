import QtQuick

Item {
    id: root

    default property alias content: frame.content
    property string title: ""

    signal closeClicked

    implicitHeight: frame.implicitHeight

    Keys.onEscapePressed: closeClicked()

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

import QtQuick
import Quickshell
import "../components"
import "../lock"
import "../../../services"

LogonScreen {
    id: root

    clockShown: false
    shown: SessionEnd.active

    // kept through the fade-out, after SessionEnd.action is cleared
    property string kind: "shutDown"

    Connections {
        target: SessionEnd

        function onActionChanged() {
            if (SessionEnd.action !== "") {
                root.kind = SessionEnd.action;
            }
        }
    }

    readonly property var words: ({
            shutDown: {
                caption: "Shutting down…",
                force: "Force shut down"
            },
            restart: {
                caption: "Restarting…",
                force: "Force restart"
            },
            logOff: {
                caption: "Logging off…",
                force: "Force log off"
            }
        })[kind]

    readonly property int waiting: SessionEnd.windows.length
    readonly property real rowHeight: 56

    Keys.onEscapePressed: SessionEnd.cancel()
    Keys.onReturnPressed: SessionEnd.cancel()
    Keys.onEnterPressed: SessionEnd.cancel()
    onShownChanged: {
        if (shown) {
            forceActiveFocus();
        }
    }

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.max(progress.width, blockedView.width)
        height: SessionEnd.blocked ? blockedView.height : progress.height

        Behavior on height {
            NumberAnimation {
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        Row {
            id: progress
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18
            opacity: SessionEnd.blocked ? 0 : 1
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 220
                }
            }

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34

                SoftGlow {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#7fd8ff"
                    spread: 12
                    opacity: 0.45
                }

                BusyCircle {
                    anchors.fill: parent
                    size: 34
                    running: progress.visible
                }
            }

            CaptionText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.words.caption
                font.pixelSize: 32
                font.weight: Font.Light
            }
        }

        Column {
            id: blockedView
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 18
            opacity: SessionEnd.blocked ? 1 : 0
            visible: opacity > 0
            y: SessionEnd.blocked ? 0 : 12

            Behavior on opacity {
                NumberAnimation {
                    duration: 260
                }
            }

            Behavior on y {
                NumberAnimation {
                    duration: 320
                    easing.type: Easing.OutCubic
                }
            }

            CaptionText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.waiting === 1 ? "1 program still needs to close" : `${root.waiting} programs still need to close`
                font.pixelSize: 32
                font.weight: Font.Light
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 540
                height: panel.height

                SoftGlow {
                    anchors.fill: parent
                    radius: 8
                    color: "#5cc8ff"
                    spread: 14
                    opacity: 0.22
                }

                Rectangle {
                    id: panel
                    width: parent.width
                    height: list.height + 16
                    radius: 8
                    color: Qt.rgba(0.82, 0.92, 1, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.4)

                    Rectangle {
                        x: 1
                        y: 1
                        width: parent.width - 2
                        height: parent.height * 0.5
                        radius: 7
                        gradient: Gradient {
                            GradientStop {
                                position: 0
                                color: Qt.rgba(1, 1, 1, 0.2)
                            }
                            GradientStop {
                                position: 1
                                color: Qt.rgba(1, 1, 1, 0.03)
                            }
                        }
                    }

                    ListView {
                        id: list
                        x: 8
                        y: 8
                        width: parent.width - 16
                        height: Math.min(count, 5) * root.rowHeight
                        clip: true
                        interactive: contentHeight > height
                        boundsBehavior: Flickable.StopAtBounds

                        model: ScriptModel {
                            values: SessionEnd.blocked ? SessionEnd.windows : []
                        }

                        delegate: WaitingProgram {
                            required property var modelData
                            required property int index
                            width: list.width
                            height: root.rowHeight
                            toplevel: modelData
                            divided: index < list.count - 1
                        }

                        remove: Transition {
                            NumberAnimation {
                                property: "opacity"
                                to: 0
                                duration: 200
                            }
                        }

                        displaced: Transition {
                            NumberAnimation {
                                property: "y"
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 220
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }

            CaptionText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "To go back and save your work, click Cancel and finish what you need to."
                font.pixelSize: 15
                color: Qt.rgba(1, 1, 1, 0.88)
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                LogonButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.words.force
                    onClicked: SessionEnd.finish()
                }

                AeroButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Cancel"
                    onClicked: SessionEnd.cancel()
                }
            }
        }
    }
}

import QtQuick

// The small light menu of the logon screen (power options, sessions). `actions` is a list of
// { label, command, checked }; picking one hides the menu and runs its command.
Rectangle {
    id: root

    property var actions: []

    visible: false
    width: 150
    height: menuColumn.height + 6
    radius: 3
    border.width: 1
    border.color: "#979797"
    color: "#f0f0f0"

    Column {
        id: menuColumn
        x: 3
        y: 3
        width: parent.width - 6

        Repeater {
            model: root.actions

            Item {
                id: item

                required property var modelData

                width: menuColumn.width
                height: 24

                Rectangle {
                    anchors.fill: parent
                    radius: 3
                    opacity: itemMouse.containsMouse ? 1 : 0
                    visible: opacity > 0
                    border.width: 1
                    border.color: "#a8d8eb"
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: "#f1f8fd"
                        }
                        GradientStop {
                            position: 1
                            color: "#d5ecf9"
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 90
                        }
                    }
                }

                // the current choice (sessions)
                Rectangle {
                    x: 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: 5
                    height: 5
                    radius: 2.5
                    visible: item.modelData.checked ?? false
                    color: "#1a1a1a"
                }

                Text {
                    x: 12 + ((item.modelData.checked ?? null) !== null ? 6 : 0)
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - 6
                    text: item.modelData.label
                    elide: Text.ElideRight
                    color: "#1a1a1a"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.visible = false;
                        item.modelData.command();
                    }
                }
            }
        }
    }
}

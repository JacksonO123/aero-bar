import QtQuick
import Quickshell
import "../../components"
import "../../notifications"
import "../../../../services"

// The Action Center: everything that hasn't been dismissed, newest app group first, with
// "Do not disturb" and "Clear all" at the bottom.
Item {
    id: root

    property bool shown: false

    readonly property real padding: 12
    readonly property color linkColor: "#1c5ea8"

    // [{ app, items: [notification, ...newest first] }], groups ordered by their newest item
    readonly property var groups: {
        const out = [];
        const byApp = {};
        for (const n of Notifications.list.slice().reverse()) {
            const app = n.appName || "Other";
            if (!byApp[app]) {
                byApp[app] = {
                    app: app,
                    items: []
                };
                out.push(byApp[app]);
            }
            byApp[app].items.push(n);
        }
        return out;
    }

    width: 352
    height: content.height + padding * 2

    onShownChanged: Notifications.centersOpen += shown ? 1 : -1

    Component.onDestruction: {
        if (shown) {
            Notifications.centersOpen -= 1;
        }
    }

    function timeText(n) {
        const t = Notifications.timeOf(n);
        if (!t) {
            return "";
        }
        const now = new Date();
        return t.toDateString() === now.toDateString() ? Qt.formatTime(t, "h:mm AP") : Qt.formatDate(t, "d MMM");
    }

    Column {
        id: content
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        spacing: 8

        Item {
            width: parent.width
            height: title.height

            Text {
                id: title
                text: "Notifications"
                color: "#1e3c78"
                font.pixelSize: 15
            }

            Text {
                anchors.right: parent.right
                anchors.baseline: title.baseline
                text: Notifications.count === 1 ? "1 message" : Notifications.count + " messages"
                visible: Notifications.count > 0
                color: "#6b7785"
                font.pixelSize: 11
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(0.6, 0.72, 0.85, 0.7)
        }

        // nothing to show
        Row {
            visible: Notifications.count === 0
            height: 56
            spacing: 10

            GlassOrb {
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                lightColor: "#d4ffb0"
                baseColor: "#3ea51f"
                darkColor: "#145200"
                glowColor: Qt.rgba(0.8, 1, 0.6, 0.9)

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        ctx.beginPath();
                        ctx.moveTo(width * 0.28, height * 0.52);
                        ctx.lineTo(width * 0.44, height * 0.68);
                        ctx.lineTo(width * 0.73, height * 0.34);
                        ctx.lineWidth = 2.6;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.strokeStyle = "white";
                        ctx.stroke();
                    }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    text: "No new notifications"
                    color: "#1a1a1a"
                    font.pixelSize: 12
                    font.bold: true
                }
                Text {
                    text: Notifications.doNotDisturb ? "Do not disturb is on: new ones arrive quietly." : "You're all caught up."
                    color: "#6b7785"
                    font.pixelSize: 11
                }
            }
        }

        Flickable {
            id: scroller
            width: parent.width
            height: Math.min(groupsColumn.height, 400)
            visible: Notifications.count > 0
            contentHeight: groupsColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: groupsColumn
                width: scroller.width
                spacing: 10

                Repeater {
                    model: root.groups

                    Column {
                        id: group
                        required property var modelData
                        width: groupsColumn.width
                        spacing: 2

                        SectionHeader {
                            width: parent.width
                            text: group.modelData.app
                        }

                        Repeater {
                            model: group.modelData.items

                            Item {
                                id: row
                                required property var modelData
                                readonly property var n: modelData

                                width: group.width
                                height: rowColumn.height + 12

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 3
                                    visible: rowMouse.containsMouse || rowClose.hovered
                                    color: "#e5f3fb"
                                    border.width: 1
                                    border.color: "#70c0e7"
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifications.activate(row.n)
                                }

                                NotificationIcon {
                                    x: 6
                                    y: 6
                                    size: 24
                                    notification: row.n
                                }

                                Column {
                                    id: rowColumn
                                    x: 38
                                    y: 6
                                    width: row.width - x - 8
                                    spacing: 1

                                    Item {
                                        width: parent.width
                                        height: summary.height

                                        Text {
                                            id: summary
                                            width: parent.width - time.width - 24
                                            text: row.n.summary
                                            color: "#1a1a1a"
                                            font.pixelSize: 12
                                            font.bold: true
                                            elide: Text.ElideRight
                                            textFormat: Text.PlainText
                                        }

                                        Text {
                                            id: time
                                            anchors.right: parent.right
                                            anchors.rightMargin: rowMouse.containsMouse || rowClose.hovered ? 20 : 0
                                            text: root.timeText(row.n)
                                            color: "#6b7785"
                                            font.pixelSize: 11
                                        }

                                        SmallClose {
                                            id: rowClose
                                            anchors.right: parent.right
                                            anchors.verticalCenter: summary.verticalCenter
                                            visible: rowMouse.containsMouse || hovered
                                            onClicked: Notifications.dismiss(row.n)
                                        }
                                    }

                                    Text {
                                        width: parent.width
                                        text: row.n.body
                                        visible: text !== ""
                                        color: "#333"
                                        font.pixelSize: 12
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        textFormat: Text.StyledText
                                        linkColor: root.linkColor
                                        onLinkActivated: link => Qt.openUrlExternally(link)
                                    }

                                    Flow {
                                        width: parent.width
                                        spacing: 12
                                        visible: actions.count > 0

                                        Repeater {
                                            id: actions
                                            model: (row.n.actions ?? []).filter(a => a.identifier !== "default")

                                            Text {
                                                required property var modelData
                                                text: modelData.text
                                                color: actionMouse.containsMouse ? "#3399ff" : root.linkColor
                                                font.pixelSize: 12
                                                font.underline: actionMouse.containsMouse

                                                MouseArea {
                                                    id: actionMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: parent.modelData.invoke()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(0.6, 0.72, 0.85, 0.7)
        }

        Item {
            width: parent.width
            height: 20

            CheckBox {
                anchors.verticalCenter: parent.verticalCenter
                text: "Do not disturb"
                checked: Notifications.doNotDisturb
                onToggled: checked => Notifications.setDoNotDisturb(checked)
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: Notifications.count > 0
                text: "Clear all"
                color: clearMouse.containsMouse ? "#3399ff" : root.linkColor
                font.pixelSize: 12
                font.underline: clearMouse.containsMouse

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifications.clearAll()
                }
            }
        }
    }
}

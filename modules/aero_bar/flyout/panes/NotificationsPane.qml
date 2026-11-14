import QtQuick
import Quickshell
import ".."
import "../../components"
import "../../notifications"
import "../../../../services"
import "../../../../utils/constants.js" as Constants

// The Action Center: everything that hasn't been dismissed, newest app group first, with
// "Do not disturb" and "Clear all" at the bottom.
FlyoutPane {
    id: root

    readonly property real padding: 12
    readonly property color linkColor: "#1c5ea8"

    // app names, ordered by each app's newest notification
    readonly property var apps: {
        const out = [];
        for (const n of Notifications.list.slice().reverse()) {
            const app = appOf(n);
            if (!out.includes(app)) {
                out.push(app);
            }
        }
        return out;
    }

    function appOf(n) {
        return n.appName || "Other";
    }

    // an app's notifications, newest first
    function itemsOf(app) {
        return Notifications.list.filter(n => appOf(n) === app).reverse();
    }

    width: 352
    height: content.height + padding * 2

    OpenCounter {
        target: Notifications
        counter: "panesOpen"
        when: root.active
    }

    // today's notifications show the time, older ones the date (re-evaluated as the clock ticks)
    function timeText(n) {
        const t = Notifications.timeOf(n);
        if (!t) {
            return "";
        }
        const now = Clock.date;
        return t.toDateString() === now.toDateString() ? Qt.formatTime(t, Constants.TIME_FORMAT) : Qt.formatDate(t, "d MMM");
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

        FlyoutRule {
            width: parent.width
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

                // ScriptModels: rows stay put as notifications come and go
                Repeater {
                    model: ScriptModel {
                        values: root.apps
                    }

                    Column {
                        id: group
                        required property var modelData
                        width: groupsColumn.width
                        spacing: 2

                        SectionHeader {
                            width: parent.width
                            text: group.modelData
                        }

                        Repeater {
                            model: ScriptModel {
                                values: root.itemsOf(group.modelData)
                            }

                            Item {
                                id: row
                                required property var modelData
                                readonly property var n: modelData

                                width: group.width
                                height: rowColumn.height + 12

                                RowHighlight {
                                    anchors.fill: parent
                                    hot: rowHover.hovered
                                    hotBorderColor: "#70c0e7"
                                }

                                // stays hovered over the row's close button and links
                                HoverHandler {
                                    id: rowHover
                                }

                                MouseArea {
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
                                            // steps aside for the close button
                                            anchors.rightMargin: rowHover.hovered ? 20 : 0
                                            text: root.timeText(row.n)
                                            color: "#6b7785"
                                            font.pixelSize: 11

                                            Behavior on anchors.rightMargin {
                                                NumberAnimation {
                                                    duration: 110
                                                    easing.type: Easing.OutQuad
                                                }
                                            }
                                        }

                                        SmallClose {
                                            anchors.right: parent.right
                                            anchors.verticalCenter: summary.verticalCenter
                                            opacity: rowHover.hovered ? 1 : 0
                                            visible: opacity > 0
                                            onClicked: Notifications.dismiss(row.n)

                                            Behavior on opacity {
                                                NumberAnimation {
                                                    duration: 110
                                                }
                                            }
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
                                            model: Notifications.extraActions(row.n)

                                            LinkText {
                                                required property var modelData
                                                text: modelData.text
                                                onClicked: modelData.invoke()
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

        FlyoutRule {
            width: parent.width
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

            LinkText {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: Notifications.count > 0
                text: "Clear all"
                onClicked: Notifications.clearAll()
            }
        }
    }
}

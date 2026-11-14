import QtQuick
import Quickshell
import "../../components"
import "../../../../services"

// Windows 7 clock flyout: long date, month calendar and a glass analog clock. The expand button
// (or clicking the month title) zooms out to the whole year; clicking a month zooms back in.
Item {
    id: root

    property bool shown: false
    property bool expanded: false
    property int viewYear: 2000
    property int viewMonth: 0
    property int slideDirection: 0

    readonly property var today: Clock.date
    readonly property int todayYear: today.getFullYear()
    readonly property int todayMonth: today.getMonth()
    readonly property int todayDay: today.getDate()
    readonly property int firstDayOfWeek: Qt.locale().firstDayOfWeek
    readonly property bool viewingToday: viewYear === todayYear && viewMonth === todayMonth

    readonly property real padding: 12
    readonly property real cellW: 30
    readonly property real cellH: 24
    readonly property color linkColor: "#1c5ea8"

    width: Math.max(header.implicitWidth, expanded ? yearView.width : monthView.width) + padding * 2
    height: padding + header.height + 10 + (expanded ? yearView.height : monthView.height) + padding

    function resetView() {
        expanded = false;
        slideDirection = 0;
        viewYear = todayYear;
        viewMonth = todayMonth;
    }

    onShownChanged: {
        if (shown) {
            resetView();
        }
    }

    Component.onCompleted: resetView()

    function shiftMonth(delta) {
        slideDirection = delta;
        const m = viewMonth + delta;
        viewYear += Math.floor(m / 12);
        viewMonth = ((m % 12) + 12) % 12;
        monthSlide.restart();
    }

    function shiftYear(delta) {
        slideDirection = delta;
        viewYear += delta;
        yearSlide.restart();
    }

    function openMonth(month) {
        viewMonth = month;
        expanded = false;
    }

    function monthCells(year, month) {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() - firstDayOfWeek + 7) % 7;
        const cells = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(year, month, 1 - offset + i);
            cells.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month,
                isToday: d.getFullYear() === todayYear && d.getMonth() === todayMonth && d.getDate() === todayDay,
                weekend: d.getDay() === 0 || d.getDay() === 6
            });
        }
        return cells;
    }

    function dayNames(length) {
        const names = [];
        for (let i = 0; i < 7; i++) {
            names.push(Qt.locale().dayName((firstDayOfWeek + i) % 7, Locale.ShortFormat).slice(0, length));
        }
        return names;
    }

    function monthName(month) {
        return Qt.locale().standaloneMonthName(month, Locale.LongFormat);
    }

    function isoWeek(date) {
        const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        const day = d.getUTCDay() || 7;
        d.setUTCDate(d.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
    }

    SystemClock {
        id: secondsClock
        precision: SystemClock.Seconds
        enabled: root.shown
    }

    // ---- building blocks ------------------------------------------------------------------

    component NavArrow: Item {
        id: arrow

        property bool pointsLeft: true
        signal activated

        width: 22
        height: 22

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            border.width: 1
            border.color: "#9cc8ee"
            opacity: arrowMouse.containsMouse ? 1 : 0

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#f7fbff"
                }
                GradientStop {
                    position: 1
                    color: "#d3eafb"
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        MediaGlyph {
            anchors.centerIn: parent
            width: 8
            height: 10
            kind: "play"
            rotation: arrow.pointsLeft ? 180 : 0
            color: arrowMouse.containsMouse ? "#1f6fc5" : "#4d6377"
            shadow: false
        }

        MouseArea {
            id: arrowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: arrow.activated()
        }
    }

    // year/month toggle: a little grid of months, or a single month
    component ZoomButton: LightButton {
        id: zoom

        property bool showsYear: true

        width: 26
        height: 22

        Grid {
            anchors.centerIn: parent
            visible: zoom.showsYear
            columns: 4
            spacing: 1.5

            Repeater {
                model: 12

                Rectangle {
                    width: 2.5
                    height: 2.5
                    radius: 0.5
                    color: "#2d4a66"
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            visible: !zoom.showsYear
            width: 12
            height: 10
            radius: 1.5
            color: "transparent"
            border.width: 1.5
            border.color: "#2d4a66"

            Rectangle {
                x: 2
                y: 2
                width: parent.width - 4
                height: 1.5
                color: "#2d4a66"
            }
        }
    }

    component DayCell: Item {
        id: cell

        property int day
        property bool inMonth
        property bool isToday
        property bool weekend

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 3
            visible: cellHover.hovered && !cell.isToday && cell.inMonth
            border.width: 1
            border.color: "#b8d6fb"

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: "#fafdff"
                }
                GradientStop {
                    position: 1
                    color: "#e1f0fb"
                }
            }
        }

        GlassOrb {
            anchors.centerIn: parent
            visible: cell.isToday
            size: Math.min(cell.width, cell.height) + 1
        }

        Text {
            anchors.centerIn: parent
            text: cell.day
            color: cell.isToday ? "white" : !cell.inMonth ? "#aab4be" : cell.weekend ? "#4d6a87" : "#1e2f40"
            font.pixelSize: 12
            font.bold: cell.isToday
            style: cell.isToday ? Text.Outline : Text.Normal
            styleColor: Qt.rgba(0, 0.08, 0.25, 0.5)
        }

        HoverHandler {
            id: cellHover
        }
    }

    component MiniMonth: Item {
        id: mini

        property string title
        property var cells: []
        property var letters: []
        property bool current: false
        signal picked

        width: 7 * 20 + 8
        height: 36 + 6 * 14 + 4

        Rectangle {
            anchors.fill: parent
            radius: 4
            border.width: 1
            border.color: mini.current ? "#7eb4ea" : miniMouse.containsMouse ? "#b8d6fb" : "transparent"
            opacity: mini.current || miniMouse.containsMouse ? 1 : 0

            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: mini.current ? "#eef7ff" : "#fafdff"
                }
                GradientStop {
                    position: 1
                    color: mini.current ? "#cfe6fa" : "#e6f2fb"
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }
        }

        Text {
            x: 7
            y: 4
            text: mini.title
            color: mini.current ? "#1a5fb4" : "#2a3d50"
            font.pixelSize: 12
            font.bold: true
        }

        Row {
            x: 4
            y: 21

            Repeater {
                model: mini.letters

                Text {
                    required property var modelData
                    width: 20
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: "#7a8896"
                    font.pixelSize: 9
                }
            }
        }

        Grid {
            x: 4
            y: 35
            columns: 7

            Repeater {
                model: mini.cells

                Item {
                    id: miniDay
                    required property var modelData
                    width: 20
                    height: 14

                    GlassOrb {
                        anchors.centerIn: parent
                        visible: miniDay.modelData.isToday
                        size: 15
                    }

                    Text {
                        anchors.centerIn: parent
                        text: miniDay.modelData.inMonth ? miniDay.modelData.day : ""
                        color: miniDay.modelData.isToday ? "white" : miniDay.modelData.weekend ? "#5a7590" : "#33475b"
                        font.pixelSize: 9
                        font.bold: miniDay.modelData.isToday
                    }
                }
            }
        }

        MouseArea {
            id: miniMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mini.picked()
        }
    }

    // ---- header: long date, like the Win7 flyout ----------------------------------------------

    Item {
        id: header
        x: root.padding
        y: root.padding
        width: root.width - root.padding * 2
        implicitWidth: longDate.implicitWidth + weekLabel.implicitWidth + 24
        height: 30

        Text {
            id: longDate
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -2
            text: root.today.toLocaleDateString(Qt.locale(), Locale.LongFormat)
            color: longDateMouse.containsMouse ? "#3399ff" : root.linkColor
            font.pixelSize: 15
            font.underline: longDateMouse.containsMouse && !root.viewingToday

            MouseArea {
                id: longDateMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.resetView()
            }
        }

        Text {
            id: weekLabel
            anchors.right: parent.right
            anchors.verticalCenter: longDate.verticalCenter
            text: `Week ${root.isoWeek(root.today)}`
            color: "#7a8896"
            font.pixelSize: 11
        }

        // Win7 separator: a line that fades out at both ends
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop {
                    position: 0
                    color: Qt.rgba(0.6, 0.72, 0.85, 0)
                }
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0.6, 0.72, 0.85, 1)
                }
                GradientStop {
                    position: 0.8
                    color: Qt.rgba(0.6, 0.72, 0.85, 1)
                }
                GradientStop {
                    position: 1
                    color: Qt.rgba(0.6, 0.72, 0.85, 0)
                }
            }
        }
    }

    // ---- month view ---------------------------------------------------------------------------

    Row {
        id: monthView
        x: root.padding
        y: header.y + header.height + 10
        spacing: 22
        opacity: root.expanded ? 0 : 1
        visible: opacity > 0
        scale: root.expanded ? 0.86 : 1
        transformOrigin: Item.TopLeft

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        Column {
            spacing: 4

            Item {
                width: 7 * root.cellW
                height: 24

                NavArrow {
                    anchors.verticalCenter: parent.verticalCenter
                    pointsLeft: true
                    onActivated: root.shiftMonth(-1)
                }

                Text {
                    id: monthTitle
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: -12
                    text: `${root.monthName(root.viewMonth)} ${root.viewYear}`
                    color: monthTitleMouse.containsMouse ? "#1f6fc5" : "#1e2f40"
                    font.pixelSize: 13
                    font.bold: true

                    MouseArea {
                        id: monthTitleMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.expanded = true
                    }
                }

                NavArrow {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: zoomIn.left
                    anchors.rightMargin: 4
                    pointsLeft: false
                    onActivated: root.shiftMonth(1)
                }

                ZoomButton {
                    id: zoomIn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    showsYear: true
                    onClicked: root.expanded = true
                }
            }

            Row {
                Repeater {
                    model: root.dayNames(2)

                    Text {
                        required property var modelData
                        width: root.cellW
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: "#7a8896"
                        font.pixelSize: 11
                    }
                }
            }

            Item {
                width: 7 * root.cellW
                height: 6 * root.cellH
                clip: true

                Grid {
                    id: dayGrid
                    columns: 7

                    Repeater {
                        model: root.monthCells(root.viewYear, root.viewMonth)

                        delegate: DayCell {
                            required property var modelData
                            width: root.cellW
                            height: root.cellH
                            day: modelData.day
                            inMonth: modelData.inMonth
                            isToday: modelData.isToday
                            weekend: modelData.weekend
                        }
                    }
                }

                ParallelAnimation {
                    id: monthSlide
                    NumberAnimation {
                        target: dayGrid
                        property: "x"
                        from: 26 * root.slideDirection
                        to: 0
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: dayGrid
                        property: "opacity"
                        from: 0.2
                        to: 1
                        duration: 220
                    }
                }
            }

            Item {
                width: 7 * root.cellW
                height: 16

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !root.viewingToday
                    text: "Go to today"
                    color: todayMouse.containsMouse ? "#3399ff" : root.linkColor
                    font.pixelSize: 11
                    font.underline: todayMouse.containsMouse

                    MouseArea {
                        id: todayMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetView()
                    }
                }
            }
        }

        Column {
            spacing: 6

            AnalogClock {
                anchors.horizontalCenter: parent.horizontalCenter
                size: 134
                date: secondsClock.date
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(secondsClock.date, "h:mm:ss AP")
                color: "#1e2f40"
                font.pixelSize: 15
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.locale().dayName(root.today.getDay(), Locale.LongFormat)
                color: "#6b7785"
                font.pixelSize: 11
            }
        }
    }

    // ---- year view ----------------------------------------------------------------------------

    Column {
        id: yearView
        x: root.padding
        y: header.y + header.height + 10
        spacing: 6
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0
        scale: root.expanded ? 1 : 1.12
        transformOrigin: Item.TopLeft

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 240
                easing.type: Easing.OutCubic
            }
        }

        Item {
            width: yearGrid.width
            height: 24

            NavArrow {
                anchors.verticalCenter: parent.verticalCenter
                pointsLeft: true
                onActivated: root.shiftYear(-1)
            }

            Text {
                anchors.centerIn: parent
                text: root.viewYear
                color: "#1e2f40"
                font.pixelSize: 14
                font.bold: true
            }

            NavArrow {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: zoomOut.left
                anchors.rightMargin: 4
                pointsLeft: false
                onActivated: root.shiftYear(1)
            }

            ZoomButton {
                id: zoomOut
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                showsYear: false
                onClicked: root.expanded = false
            }
        }

        Grid {
            id: yearGrid
            columns: 4
            spacing: 8

            Repeater {
                model: 12

                delegate: MiniMonth {
                    required property int index
                    title: root.monthName(index)
                    cells: root.monthCells(root.viewYear, index)
                    letters: root.dayNames(1)
                    current: root.viewYear === root.todayYear && index === root.todayMonth
                    onPicked: root.openMonth(index)
                }
            }

            ParallelAnimation {
                id: yearSlide
                NumberAnimation {
                    target: yearGrid
                    property: "opacity"
                    from: 0.2
                    to: 1
                    duration: 240
                }
            }
        }
    }
}

pragma ComponentBehavior: Bound

import QtQuick
import "../components"
import "../../../services"

// The Windows 7 start menu, drawn in this shell's glass:
//  left:  white panel with frequent programs / All Programs (folders) / search results,
//         search box underneath
//  right: the user tile hanging over the top edge, places + system links on the glass,
//         and the Shut down split button
Item {
    id: root

    property bool shown: false

    property string mode: "home" // home | all | search
    property int selected: 0
    property string hoveredIcon: ""
    property bool powerMenuOpen: false
    // the home list only shows a keyboard selection once the arrow keys are used
    property bool keyboardNav: false
    // All Programs builds its app rows the first time it's opened, not at startup (there's a
    // menu per screen). The folders start collapsed, so their icons load before one is opened.
    property bool allProgramsBuilt: false

    onModeChanged: {
        if (mode === "all") {
            allProgramsBuilt = true;
        }
    }

    readonly property alias maskFrame: frame
    readonly property alias maskTile: tile

    readonly property real frameW: 420
    readonly property real frameH: 520
    readonly property real overhang: 30
    readonly property real pad: 8
    readonly property real leftW: 254
    readonly property real searchH: 28
    readonly property real rightX: pad + leftW + 10
    readonly property real rightW: frameW - rightX - pad

    readonly property string query: searchBox.text
    readonly property var results: StartMenuState.search(query)

    implicitWidth: frameW
    implicitHeight: frameH + overhang

    onQueryChanged: {
        selected = 0;
        if (query.trim() !== "") {
            mode = "search";
        } else if (mode === "search") {
            mode = "home";
        }
    }

    onShownChanged: {
        if (shown) {
            searchBox.clear();
            mode = "home";
            selected = 0;
            keyboardNav = false;
            powerMenuOpen = false;
            searchBox.focusInput();
        }
    }

    // the search text as a shell command (the "Run" row)
    function runQuery() {
        StartMenuState.run(["sh", "-c", query]);
    }

    // (search mode always has a query: an empty one goes back home)
    function activateSelected() {
        if (mode === "search") {
            if (selected < results.length) {
                StartMenuState.launch(results[selected]);
            } else {
                runQuery();
            }
        } else if (mode === "home" && keyboardNav) {
            // only a row the arrow keys highlighted
            StartMenuState.launch(StartMenuState.frequentApps[selected]);
        }
    }

    function selectableCount() {
        if (mode === "search") {
            return results.length + 1; // + the Run row
        }
        return mode === "home" ? StartMenuState.frequentApps.length : 0;
    }

    // a place shows its icon on the user tile while hovered. Moving straight to the next place
    // reports the new hover before the old one ends, so only clear our own icon.
    function showPlaceIcon(icon, hovered) {
        if (hovered) {
            hoveredIcon = icon;
        } else if (hoveredIcon === icon) {
            hoveredIcon = "";
        }
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            if (powerMenuOpen) {
                powerMenuOpen = false;
            } else if (mode === "all") {
                mode = "home";
            } else if (query !== "") {
                searchBox.clear();
            } else {
                StartMenuState.close();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
            const count = selectableCount();
            if (count > 0) {
                const step = event.key === Qt.Key_Down ? 1 : -1;
                // on the home list the first arrow press only reveals the selection
                const revealOnly = !keyboardNav && mode !== "search";
                selected = revealOnly ? 0 : (selected + step + count) % count;
                keyboardNav = true;
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateSelected();
            event.accepted = true;
        }
    }

    // a link on the glass column
    component Place: Win7Frame {
        id: place

        property string label
        property string icon
        property var command: []
        property bool emphasised: false

        height: 28
        frameOpacity: hoverT
        onClicked: StartMenuState.run(place.command)

        Win7Hover {
            radius: place.radius
            opacity: place.hoverT
            pressedT: place.pressedT
        }

        Text {
            x: 10
            width: parent.width - 14
            anchors.verticalCenter: parent.verticalCenter
            text: place.label
            elide: Text.ElideRight
            color: "white"
            font.pixelSize: 12
            font.bold: place.emphasised
            style: Text.Raised
            styleColor: Qt.rgba(0, 0, 0, 0.55)
        }
    }

    // open/close: quick fade + rise, like Win7
    opacity: shown ? 1 : 0
    property real rise: shown ? 0 : 14

    Behavior on opacity {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Behavior on rise {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Item {
        id: body
        y: root.overhang + root.rise
        width: root.frameW
        height: root.frameH

        Aeroframe {
            id: frame
            anchors.fill: parent
            frameWidth: 0
            topFrameWidth: 0
            radius: 7
            showContentFrame: false
            sheenTopOpacity: 0.2
            sheenPeakOpacity: 0.12
            sheenPeak: 0.05
            sheenFade: 0.3
        }

        // ---- left: white panel ---------------------------------------------------------------

        Rectangle {
            id: leftPanel
            x: root.pad
            y: root.pad
            width: root.leftW
            height: root.frameH - root.pad * 2 - root.searchH - 10
            radius: 4
            color: "white"
            border.width: 1
            border.color: Qt.rgba(0.1, 0.18, 0.28, 0.75)
            clip: true

            Item {
                id: listArea
                x: 4
                y: 4
                width: parent.width - 8
                height: parent.height - 8 - allPrograms.height - 9

                // frequent programs
                Column {
                    width: parent.width
                    x: root.mode === "home" ? 0 : -width * 0.3
                    opacity: root.mode === "home" ? 1 : 0
                    visible: opacity > 0

                    Behavior on x {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }
                    }

                    Repeater {
                        model: StartMenuState.frequentApps

                        MenuItem {
                            required property var modelData
                            required property int index
                            width: listArea.width
                            label: modelData.name
                            iconName: modelData.icon
                            iconSize: 32
                            selected: root.keyboardNav && root.mode === "home" && root.selected === index
                            onActivated: StartMenuState.launch(modelData)
                        }
                    }
                }

                // All Programs: category folders
                Item {
                    anchors.fill: parent
                    x: root.mode === "all" ? 0 : width * 0.5
                    opacity: root.mode === "all" ? 1 : 0
                    visible: opacity > 0

                    Behavior on x {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 160
                        }
                    }

                    Flickable {
                        id: allFlick
                        anchors.fill: parent
                        anchors.rightMargin: 6
                        contentHeight: folders.height
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Column {
                            id: folders
                            width: allFlick.width

                            Repeater {
                                model: StartMenuState.categories

                                Column {
                                    id: folder
                                    required property var modelData
                                    property bool expanded: false
                                    width: folders.width

                                    MenuItem {
                                        width: folder.width
                                        label: folder.modelData.name
                                        iconName: folder.expanded ? "folder-open" : "folder"
                                        iconSize: 20
                                        showArrow: true
                                        arrowDown: folder.expanded
                                        onActivated: folder.expanded = !folder.expanded
                                    }

                                    Item {
                                        width: folder.width
                                        height: folder.expanded ? apps.implicitHeight : 0
                                        clip: true

                                        Behavior on height {
                                            NumberAnimation {
                                                duration: 180
                                                easing.type: Easing.OutCubic
                                            }
                                        }

                                        Column {
                                            id: apps
                                            width: parent.width

                                            Repeater {
                                                model: root.allProgramsBuilt ? folder.modelData.entries : []

                                                MenuItem {
                                                    required property var modelData
                                                    width: apps.width
                                                    label: modelData.name
                                                    iconName: modelData.icon
                                                    iconSize: 20
                                                    indent: 16
                                                    onActivated: StartMenuState.launch(modelData)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    ScrollThumb {
                        anchors.right: parent.right
                        flickable: allFlick
                    }
                }

                // search results
                Column {
                    width: parent.width
                    opacity: root.mode === "search" ? 1 : 0
                    visible: opacity > 0
                    spacing: 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 120
                        }
                    }

                    SectionHeader {
                        width: parent.width
                        text: root.results.length > 0 ? `Programs (${root.results.length})` : "No programs match"
                    }

                    Repeater {
                        model: root.results

                        MenuItem {
                            required property var modelData
                            required property int index
                            width: listArea.width
                            label: modelData.name
                            sublabel: modelData.genericName || modelData.comment || ""
                            iconName: modelData.icon
                            iconSize: 24
                            selected: root.selected === index
                            onActivated: StartMenuState.launch(modelData)
                        }
                    }

                    Item {
                        width: 1
                        height: 4
                    }

                    SectionHeader {
                        width: parent.width
                        text: "Run"
                    }

                    MenuItem {
                        width: listArea.width
                        label: `Run “${root.query.trim()}”`
                        iconName: "utilities-terminal"
                        iconSize: 20
                        selected: root.selected === root.results.length
                        onActivated: root.runQuery()
                    }
                }
            }

            // Win7 separator above All Programs
            Rectangle {
                x: 10
                width: parent.width - 20
                anchors.bottom: allPrograms.top
                anchors.bottomMargin: 4
                height: 1

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0
                        color: Qt.rgba(0.75, 0.8, 0.86, 0)
                    }
                    GradientStop {
                        position: 0.5
                        color: Qt.rgba(0.75, 0.8, 0.86, 1)
                    }
                    GradientStop {
                        position: 1
                        color: Qt.rgba(0.75, 0.8, 0.86, 0)
                    }
                }
            }

            MenuItem {
                id: allPrograms
                x: 4
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
                width: parent.width - 8
                iconSize: 0
                bold: true
                indent: root.mode === "home" ? 0 : 12
                label: root.mode === "home" ? "All Programs" : "Back"
                showArrow: root.mode === "home"
                onActivated: {
                    root.mode = root.mode === "home" ? "all" : "home";
                    if (root.mode === "home") {
                        searchBox.clear();
                    }
                }

                MediaGlyph {
                    visible: root.mode !== "home"
                    x: 10
                    anchors.verticalCenter: parent.verticalCenter
                    width: 6
                    height: 8
                    kind: "play"
                    rotation: 180
                    color: "#3c3c3c"
                    shadow: false
                }
            }
        }

        SearchBox {
            id: searchBox
            x: root.pad
            y: root.frameH - root.pad - root.searchH
            width: root.leftW
            height: root.searchH
            // Enter is handled once, by Keys.onPressed above (TextInput lets the key through)
        }

        // ---- right: places on the glass ----------------------------------------------------------

        Column {
            id: rightColumn
            x: root.rightX
            y: tile.height - root.overhang + 12
            width: root.rightW
            spacing: 1

            Place {
                width: rightColumn.width
                label: StartMenuState.displayName
                icon: "user-home"
                emphasised: true
                command: StartMenuState.homeCommand
                onHoveredChanged: root.showPlaceIcon(icon, hovered)
            }

            Repeater {
                model: StartMenuState.places

                Place {
                    required property var modelData
                    width: rightColumn.width
                    label: modelData.label
                    icon: modelData.icon
                    command: modelData.command
                    onHoveredChanged: root.showPlaceIcon(icon, hovered)
                }
            }

            Item {
                width: rightColumn.width
                height: 11

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 16
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.22)
                }
            }

            Repeater {
                model: StartMenuState.systemLinks

                Place {
                    required property var modelData
                    width: rightColumn.width
                    label: modelData.label
                    icon: modelData.icon
                    command: modelData.command
                    onHoveredChanged: root.showPlaceIcon(icon, hovered)
                }
            }
        }

        // ---- Shut down split button ------------------------------------------------------------

        ShutdownButton {
            id: shutdownButton
            x: root.rightX + 8
            // centred on the search box, like Win7
            y: root.frameH - root.pad - root.searchH + (root.searchH - height) / 2
            menuOpen: root.powerMenuOpen
            onClicked: StartMenuState.run(StartMenuState.shutDown)
            onArrowClicked: root.powerMenuOpen = !root.powerMenuOpen
        }

        // power options (Win7 context menu)
        Item {
            id: powerMenu
            x: shutdownButton.x + shutdownButton.width - width
            y: shutdownButton.y - height - 4
            width: 138
            height: powerColumn.height + 6
            opacity: root.powerMenuOpen ? 1 : 0
            visible: opacity > 0
            z: 10

            Behavior on opacity {
                NumberAnimation {
                    duration: 110
                }
            }

            Rectangle {
                x: 2
                y: 3
                width: parent.width
                height: parent.height
                radius: 3
                color: Qt.rgba(0, 0, 0, 0.3)
            }

            Rectangle {
                anchors.fill: parent
                radius: 3
                color: "#f5f6f7"
                border.width: 1
                border.color: "#979797"
            }

            Column {
                id: powerColumn
                x: 3
                y: 3
                width: parent.width - 6

                Repeater {
                    model: StartMenuState.powerActions

                    MenuItem {
                        required property var modelData
                        width: powerColumn.width
                        height: 24
                        iconSize: 0
                        label: modelData.label
                        onActivated: {
                            root.powerMenuOpen = false;
                            StartMenuState.run(modelData.command);
                        }
                    }
                }
            }
        }
    }

    ProfileTile {
        id: tile
        x: root.rightX + (root.rightW - width) / 2
        y: root.rise
        picture: StartMenuState.picture
        iconName: root.hoveredIcon
        hoverT: tileMouse.containsMouse ? 1 : 0

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            // like Win7's User Accounts, for changing your picture
            onClicked: StartMenuState.run(() => AccountPicture.openDialog(StartMenuState.screen))
        }
    }
}

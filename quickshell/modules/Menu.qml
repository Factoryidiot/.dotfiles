import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: menuWindow

    property bool isOpen: false
    property string activeCategory: "root"
    property var navHistory: []
    property int searchIndex: 0

    function open(category) {
        activeCategory = category || "root";
        navHistory = [];
        searchInput.text = "";
        searchIndex = 0;
        isOpen = true;
        searchInput.forceActiveFocus();
    }

    function close() {
        isOpen = false;
        searchInput.focus = false;
    }

    function toggle(category) {
        if (isOpen) close();
        else open(category);
    }

    function drillDown(categoryId) {
        navHistory.push(activeCategory);
        activeCategory = categoryId;
        searchInput.text = "";
        searchIndex = 0;
    }

    function goBack() {
        if (searchInput.text.length > 0) {
            searchInput.text = "";
            return;
        }
        if (navHistory.length > 0) {
            activeCategory = navHistory.pop();
            searchIndex = 0;
        } else {
            close();
        }
    }

    // Full screen overlay for backdrop dismiss
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    visible: isOpen
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quickshell-menu"

    IpcHandler {
        target: "menu"
        function toggle(): void { menuWindow.toggle("root"); }
        function open(): void { menuWindow.open("root"); }
        function close(): void { menuWindow.close(); }
        function apps(): void { menuWindow.open("apps"); }
        function power(): void { menuWindow.open("system"); }
        function tools(): void { menuWindow.open("tools"); }
    }

    // Helper process to execute commands asynchronously
    Process {
        id: cmdRunner
        command: []
        running: false
    }

    function runCmd(cmd) {
        cmdRunner.command = ["zsh", "-c", cmd];
        cmdRunner.running = true;
        menuWindow.close();
    }

    // Top-Level Categories
    readonly property var rootCategories: [
        { id: "apps", name: "Applications", comment: "Browse all installed desktop applications", icon: "applications-other", isCategory: true },
        { id: "tools", name: "System Tools & TUIs", comment: "Task managers, mixers, wifi and bluetooth utilities", icon: "utilities-system-monitor", isCategory: true },
        { id: "system", name: "Power & Session", comment: "Lock, suspend, reboot, shutdown, and logout", icon: "system-shutdown", isCategory: true }
    ]

    // System Tools & TUIs
    readonly property var toolActions: [
        { id: "action-terminal", name: "Terminal", comment: "Ghostty GPU-accelerated terminal", icon: "utilities-terminal", exec: "xdg-terminal-exec", category: "Tools" },
        { id: "action-btop", name: "Resource Monitor (btop)", comment: "Interactive process viewer and hardware stats", icon: "utilities-system-monitor", exec: "launch-or-focus-tui btop", category: "Tools" },
        { id: "action-wiremix", name: "Audio Mixer (wiremix)", comment: "PipeWire sound and stream volume controls", icon: "audio-card", exec: "launch-or-focus-tui wiremix", category: "Tools" },
        { id: "action-bluetui", name: "Bluetooth Manager (bluetui)", comment: "Manage paired and connected Bluetooth devices", icon: "bluetooth", exec: "launch-or-focus-tui bluetui", category: "Tools" },
        { id: "action-impala", name: "WiFi Manager (impala)", comment: "Scan, connect, and configure wireless networks", icon: "network-wireless", exec: "launch-wifi", category: "Tools" },
        { id: "action-bitwarden", name: "Bitwarden Password Vault", comment: "Open desktop password manager", icon: "bitwarden", exec: "launch-or-focus bitwarden bitwarden", category: "Tools" },
        { id: "action-waypaper", name: "Wallpaper Picker (waypaper)", comment: "Select and set desktop wallpaper", icon: "preferences-desktop-wallpaper", exec: "waypaper", category: "Tools" }
    ]

    // Power & Session Actions
    readonly property var systemActions: [
        { id: "action-lock", name: "Lock Screen", comment: "Lock display session immediately", icon: "system-lock-screen", exec: "hyprlock", category: "System" },
        { id: "action-suspend", name: "Suspend", comment: "Put system to sleep", icon: "system-suspend", exec: "systemctl suspend", category: "System" },
        { id: "action-reboot", name: "Reboot", comment: "Restart computer", icon: "system-reboot", exec: "systemctl reboot", category: "System" },
        { id: "action-shutdown", name: "Shutdown", comment: "Power off computer", icon: "system-shutdown", exec: "systemctl poweroff", category: "System" },
        { id: "action-logout", name: "Log Out", comment: "Exit current desktop session", icon: "system-log-out", exec: "hyprctl dispatch exit", category: "System" }
    ]

    function getBreadcrumbTitle() {
        if (searchInput.text.trim().length > 0) {
            return "Search Results";
        }
        if (activeCategory === "apps") return "Applications";
        if (activeCategory === "tools") return "System Tools & TUIs";
        if (activeCategory === "system") return "Power & Session";
        return "Menu";
    }

    function getDisplayItems() {
        var query = searchInput.text.trim().toLowerCase();
        var results = [];

        // 1. Search Mode: Query matches across ALL items
        if (query.length > 0) {
            // Tools
            for (var t = 0; t < toolActions.length; t++) {
                var tool = toolActions[t];
                if (tool.name.toLowerCase().includes(query) || (tool.comment && tool.comment.toLowerCase().includes(query))) {
                    results.push({ isApp: false, isCategory: false, name: tool.name, comment: tool.comment, icon: tool.icon, exec: tool.exec, badge: "Tool" });
                }
            }
            // System
            for (var s = 0; s < systemActions.length; s++) {
                var sys = systemActions[s];
                if (sys.name.toLowerCase().includes(query) || (sys.comment && sys.comment.toLowerCase().includes(query))) {
                    results.push({ isApp: false, isCategory: false, name: sys.name, comment: sys.comment, icon: sys.icon, exec: sys.exec, badge: "System" });
                }
            }
            // Applications
            if (DesktopEntries && DesktopEntries.applications) {
                var apps = DesktopEntries.applications.values;
                for (var a = 0; a < apps.length; a++) {
                    var app = apps[a];
                    if (!app || app.nodisplay) continue;
                    var appName = app.name || "";
                    var appComment = app.comment || app.genericName || "";
                    if (appName.toLowerCase().includes(query) || appComment.toLowerCase().includes(query)) {
                        results.push({ isApp: true, isCategory: false, name: appName, comment: appComment, icon: app.icon || "application-x-executable", appObj: app, badge: "App" });
                    }
                }
            }
            return results;
        }

        // 2. Browse Mode: Show current category
        if (activeCategory === "root") {
            for (var r = 0; r < rootCategories.length; r++) {
                var cat = rootCategories[r];
                results.push({ isApp: false, isCategory: true, id: cat.id, name: cat.name, comment: cat.comment, icon: cat.icon, badge: "Submenu" });
            }
            return results;
        }

        if (activeCategory === "tools") {
            for (var t2 = 0; t2 < toolActions.length; t2++) {
                var tool2 = toolActions[t2];
                results.push({ isApp: false, isCategory: false, name: tool2.name, comment: tool2.comment, icon: tool2.icon, exec: tool2.exec, badge: "" });
            }
            return results;
        }

        if (activeCategory === "system") {
            for (var s2 = 0; s2 < systemActions.length; s2++) {
                var sys2 = systemActions[s2];
                results.push({ isApp: false, isCategory: false, name: sys2.name, comment: sys2.comment, icon: sys2.icon, exec: sys2.exec, badge: "" });
            }
            return results;
        }

        if (activeCategory === "apps") {
            if (DesktopEntries && DesktopEntries.applications) {
                var appsList = DesktopEntries.applications.values.slice();
                appsList.sort((x, y) => (x.name || "").localeCompare(y.name || ""));
                for (var a2 = 0; a2 < appsList.length; a2++) {
                    var app2 = appsList[a2];
                    if (!app2 || app2.nodisplay) continue;
                    results.push({ isApp: true, isCategory: false, name: app2.name || "", comment: app2.comment || app2.genericName || "", icon: app2.icon || "application-x-executable", appObj: app2, badge: "" });
                }
            }
            return results;
        }

        return results;
    }

    function executeItem(item) {
        if (!item) return;
        if (item.isCategory) {
            menuWindow.drillDown(item.id);
        } else if (item.isApp && item.appObj) {
            item.appObj.execute();
            menuWindow.close();
        } else if (item.exec) {
            menuWindow.runCmd(item.exec);
        }
    }

    // Scrim / Backdrop dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: menuWindow.close()
    }

    // Main Floating Modal Container
    Rectangle {
        id: modalBox
        width: 580
        height: Math.min(540, Math.max(140, 80 + (resultsList.count * 48)))
        anchors.centerIn: parent
        color: "#2e3440"
        border.color: "#4c566a"
        border.width: 1
        radius: 8
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Header: Breadcrumb Path & Search Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Back Button (shown if in submenu)
                Rectangle {
                    visible: menuWindow.activeCategory !== "root" && searchInput.text.length === 0
                    width: 32
                    height: 32
                    radius: 4
                    color: backMouseArea.containsMouse ? "#434c5e" : "#3b4252"

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: backMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menuWindow.goBack()
                    }
                }

                // Breadcrumb Title
                Text {
                    text: menuWindow.getBreadcrumbTitle()
                    color: "#88c0d0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Search Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 38
                color: "#3b4252"
                radius: 6
                border.color: searchInput.activeFocus ? "#88c0d0" : "#434c5e"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "󰍉"
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: "#eceff4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        selectByMouse: true
                        selectionColor: "#88c0d0"
                        selectedTextColor: "#2e3440"
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: menuWindow.activeCategory === "root" ? "Search all applications & actions..." : `Filter in ${menuWindow.getBreadcrumbTitle()}...`
                            color: "#d8dee9"
                            opacity: 0.4
                            font.family: searchInput.font.family
                            font.pixelSize: searchInput.font.pixelSize
                            visible: searchInput.text.length === 0
                        }

                        onTextChanged: {
                            menuWindow.searchIndex = 0;
                        }

                        Keys.onDownPressed: {
                            if (resultsList.count > 0) {
                                menuWindow.searchIndex = (menuWindow.searchIndex + 1) % resultsList.count;
                                resultsList.positionViewAtIndex(menuWindow.searchIndex, ListView.Contain);
                            }
                        }

                        Keys.onUpPressed: {
                            if (resultsList.count > 0) {
                                menuWindow.searchIndex = (menuWindow.searchIndex - 1 + resultsList.count) % resultsList.count;
                                resultsList.positionViewAtIndex(menuWindow.searchIndex, ListView.Contain);
                            }
                        }

                        Keys.onReturnPressed: {
                            var items = menuWindow.getDisplayItems();
                            if (items.length > 0 && menuWindow.searchIndex < items.length) {
                                menuWindow.executeItem(items[menuWindow.searchIndex]);
                            }
                        }

                        Keys.onEscapePressed: {
                            menuWindow.goBack();
                        }
                    }
                }
            }

            // Results List
            ListView {
                id: resultsList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2

                model: menuWindow.getDisplayItems()

                delegate: Rectangle {
                    id: rowDelegate
                    required property var modelData
                    required property int index

                    width: resultsList.width
                    height: 44
                    radius: 4
                    color: index === menuWindow.searchIndex ? "#434c5e" : (rowMouseArea.containsMouse ? "#3b4252" : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 10

                        // Icon
                        Image {
                            width: 22
                            height: 22
                            source: Quickshell.iconPath(modelData.icon, true)
                            fillMode: Image.PreserveAspectFit
                            visible: source.toString() !== ""
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.name
                                color: index === menuWindow.searchIndex ? "#88c0d0" : "#eceff4"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                font.bold: index === menuWindow.searchIndex || modelData.isCategory
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.comment
                                color: "#d8dee9"
                                opacity: 0.6
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                visible: modelData.comment !== ""
                                Layout.fillWidth: true
                            }
                        }

                        // Badge / Arrow indicator
                        Text {
                            text: modelData.isCategory ? "" : (modelData.badge ? modelData.badge : "")
                            color: modelData.isCategory ? "#88c0d0" : "#81a1c1"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: modelData.isCategory ? 12 : 10
                            opacity: modelData.isCategory ? 0.8 : 0.6
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: rowMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onEntered: menuWindow.searchIndex = index
                        onClicked: menuWindow.executeItem(modelData)
                    }
                }
            }
        }
    }
}

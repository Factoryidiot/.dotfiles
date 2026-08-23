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

    property var existingVms: []

    Process {
        id: vmListProc
        command: ["zsh", "-c", "cmd-vm list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text.trim();
                if (out.length > 0) {
                    menuWindow.existingVms = out.split("\n").filter(v => v.trim().length > 0);
                } else {
                    menuWindow.existingVms = [];
                }
            }
        }
    }

    function open(category) {
        activeCategory = category || "root";
        navHistory = [];
        searchInput.text = "";
        searchIndex = 0;
        vmListProc.running = true;
        isOpen = true;
        searchInput.forceActiveFocus();
    }

    function close() {
        isOpen = false;
        searchInput.focus = false;
    }

    function toggle(category) {
        var targetCat = category || "root";
        if (isOpen && activeCategory === targetCat) {
            close();
        } else {
            open(targetCat);
        }
    }

    function drillDown(categoryId) {
        navHistory.push(activeCategory);
        activeCategory = categoryId;
        searchInput.text = "";
        searchIndex = 0;
        if (categoryId === "vms" || categoryId === "vms-start" || categoryId === "vms-delete") {
            vmListProc.running = true;
        }
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
        function apps(): void { menuWindow.toggle("apps"); }
        function actions(): void { menuWindow.toggle("actions"); }
        function setup(): void { menuWindow.toggle("setup"); }
        function vms(): void { menuWindow.toggle("vms"); }
        function help(): void { menuWindow.toggle("help"); }
        function power(): void { menuWindow.toggle("system"); }
    }

    function runCmd(cmd) {
        Quickshell.execDetached(["zsh", "-c", cmd]);
        menuWindow.close();
    }

    // Root Categories
    readonly property var rootCategories: [
        { id: "apps", name: "Apps", glyph: "󰀻", isCategory: true },
        { id: "actions", name: "Actions", glyph: "󱓞", isCategory: true },
        { id: "setup", name: "Setup", glyph: "", isCategory: true },
        { id: "vms", name: "Virtual Machines", glyph: "", isCategory: true },
        { id: "webapp", name: "Web App", glyph: "", exec: "xdg-terminal-exec --app-id=dot.nix.install-webapp install-webapp" },
        { id: "help", name: "Help", glyph: "󰧑", isCategory: true },
        { id: "system", name: "System", glyph: "", isCategory: true }
    ]

    // Virtual Machines Submenu
    readonly property var vmsItems: [
        { id: "vms-curator", name: "VM-Curator", glyph: "󰪶", exec: "launch-or-focus-tui vm-curator" },
        { id: "vms-lazydocker", name: "Lazydocker", glyph: "󰡨", exec: "launch-or-focus-tui lazydocker" },
        { id: "vms-start", name: "Start VM", glyph: "", isCategory: true },
        { id: "vms-delete", name: "Delete VM", glyph: "", isCategory: true }
    ]

    // Actions Submenu
    readonly property var actionItems: [
        { id: "act-screenshot", name: "Screenshot (Interactive)", glyph: "", exec: "cmd-screenshot smart" },
        { id: "act-screenshot-clip", name: "Screenshot (To Clipboard)", glyph: "", exec: "cmd-screenshot smart clipboard" },
        { id: "act-colorpicker", name: "Color Picker (Hyprpicker)", glyph: "󰃉", exec: "pkill hyprpicker || hyprpicker -a" },
        { id: "act-share-clip", name: "Share Clipboard", glyph: "", exec: "cmd-share clipboard" },
        { id: "act-share-file", name: "Share File", glyph: "", exec: "xdg-terminal-exec --app-id=dot.nix.terminal bash -c 'cmd-share file'" },
        { id: "act-toggle-screensaver", name: "Toggle Screensaver", glyph: "󱄄", exec: "toggle-screensaver" },
        { id: "act-toggle-nightlight", name: "Toggle Nightlight", glyph: "󰔎", exec: "toggle-nightlight" },
        { id: "act-toggle-idle", name: "Toggle Idle Lock", glyph: "󱫖", exec: "toggle-idle" }
    ]

    // Setup & Settings Submenu
    readonly property var setupItems: [
        { id: "setup-audio", name: "Audio (wiremix)", glyph: "", exec: "launch-or-focus-tui wiremix" },
        { id: "setup-wifi", name: "WiFi (impala)", glyph: "", exec: "launch-wifi" },
        { id: "setup-bluetooth", name: "Bluetooth (bluetui)", glyph: "󰂯", exec: "launch-bluetooth" },
        { id: "setup-monitors", name: "Monitors", glyph: "󰍹", exec: "launch-editor ~/.dotfiles/hypr/modules/monitors.lua" },
        { id: "setup-keybindings", name: "Keybindings", glyph: "", exec: "launch-editor ~/.dotfiles/hypr/modules/keybindings.lua" },
        { id: "setup-wallpaper", name: "Wallpaper (waypaper)", glyph: "", exec: "waypaper" },
        { id: "setup-weather-report", name: "Weather Report", glyph: "", exec: "launch-weather-report" }
    ]

    // Help & Docs Submenu
    readonly property var helpItems: [
        { id: "help-keybindings", name: "Keybindings Reference", glyph: "", exec: "launch-or-focus-tui display-keybindings" },
        { id: "help-homemanager", name: "Home-Manager Options", glyph: "", exec: "launch-webapp 'https://home-manager-options.extranix.com/'" },
        { id: "help-hyprland", name: "Hyprland Wiki", glyph: "", exec: "launch-webapp 'https://wiki.hypr.land/'" },
        { id: "help-neovim", name: "Neovim Keymaps", glyph: "", exec: "launch-webapp 'https://www.lazyvim.org/keymaps'" },
        { id: "help-nixos", name: "NixOS Wiki", glyph: "", exec: "launch-webapp 'https://wiki.nixos.org/wiki/NixOS_Wiki'" },
        { id: "help-zsh", name: "Zsh / Shell Hints", glyph: "󱆃", exec: "launch-webapp 'https://devhints.io/bash'" }
    ]

    // Power & Session Submenu
    readonly property var systemActions: [
        { id: "action-lock", name: "Lock", glyph: "", exec: "hyprlock" },
        { id: "action-screensaver", name: "Screensaver (Force)", glyph: "󱄄", exec: "launch-screensaver force" },
        { id: "action-suspend", name: "Suspend", glyph: "󰒲", exec: "systemctl suspend" },
        { id: "action-reboot", name: "Reboot", glyph: "󰜉", exec: "systemctl reboot" },
        { id: "action-shutdown", name: "Shutdown", glyph: "󰐥", exec: "systemctl poweroff" },
        { id: "action-logout", name: "Log Out", glyph: "󰍃", exec: "hyprctl dispatch exit" }
    ]

    function getBreadcrumbTitle() {
        if (searchInput.text.trim().length > 0) return "Search";
        if (activeCategory === "apps") return "Apps";
        if (activeCategory === "actions") return "Actions";
        if (activeCategory === "setup") return "Setup";
        if (activeCategory === "vms") return "Virtual Machines";
        if (activeCategory === "vms-start") return "Start VM";
        if (activeCategory === "vms-delete") return "Delete VM";
        if (activeCategory === "help") return "Help";
        if (activeCategory === "system") return "System";
        return "Menu";
    }

    function getDisplayItems() {
        var query = searchInput.text.trim().toLowerCase();
        var results = [];

        // 1. Search Mode: Match across all actions, setup items, help docs, and desktop applications
        if (query.length > 0) {
            var pools = [actionItems, setupItems, helpItems, systemActions, vmsItems];
            for (var p = 0; p < pools.length; p++) {
                var pool = pools[p];
                for (var i = 0; i < pool.length; i++) {
                    var item = pool[i];
                    if (item.name.toLowerCase().includes(query)) {
                        results.push({ isApp: false, isCategory: item.isCategory === true, id: item.id || "", name: item.name, glyph: item.glyph, icon: "", exec: item.exec || "" });
                    }
                }
            }
            for (var vmIdx = 0; vmIdx < existingVms.length; vmIdx++) {
                var vmName = existingVms[vmIdx];
                if (vmName.toLowerCase().includes(query)) {
                    results.push({ isApp: false, isCategory: false, name: "Start " + vmName, glyph: "", icon: "", exec: "cmd-vm start '" + vmName + "'" });
                }
            }
            if (DesktopEntries && DesktopEntries.applications) {
                var apps = DesktopEntries.applications.values;
                for (var a = 0; a < apps.length; a++) {
                    var app = apps[a];
                    if (!app || app.nodisplay) continue;
                    var appName = app.name || "";
                    var appComment = app.comment || app.genericName || "";
                    var appId = app.id || "";
                    if (appName.toLowerCase().includes("vm-curator") || appName.toLowerCase() === "curator" || appId.toLowerCase().includes("vm-curator")) continue;
                    if (appName.toLowerCase().includes(query) || appComment.toLowerCase().includes(query)) {
                        results.push({ isApp: true, isCategory: false, name: appName, glyph: "", icon: app.icon || "application-x-executable", appObj: app });
                    }
                }
            }
            return results;
        }

        // 2. Browse Mode
        if (activeCategory === "root") {
            for (var r = 0; r < rootCategories.length; r++) {
                var cat = rootCategories[r];
                results.push({ isApp: false, isCategory: cat.isCategory === true, id: cat.id, name: cat.name, glyph: cat.glyph, icon: "", exec: cat.exec || "" });
            }
            return results;
        }

        if (activeCategory === "vms") {
            for (var v1 = 0; v1 < vmsItems.length; v1++) {
                var vm = vmsItems[v1];
                results.push({ isApp: false, isCategory: vm.isCategory === true, id: vm.id, name: vm.name, glyph: vm.glyph, icon: "", exec: vm.exec || "" });
            }
            return results;
        }

        if (activeCategory === "vms-start") {
            if (existingVms.length === 0) {
                results.push({ isApp: false, isCategory: false, name: "No VMs found in ~/VMs", glyph: "", icon: "", exec: "" });
            } else {
                for (var vs = 0; vs < existingVms.length; vs++) {
                    var vName = existingVms[vs];
                    results.push({ isApp: false, isCategory: false, name: vName, glyph: "", icon: "", exec: "cmd-vm start '" + vName + "'" });
                }
            }
            return results;
        }

        if (activeCategory === "vms-delete") {
            if (existingVms.length === 0) {
                results.push({ isApp: false, isCategory: false, name: "No VMs found in ~/VMs", glyph: "", icon: "", exec: "" });
            } else {
                for (var vd = 0; vd < existingVms.length; vd++) {
                    var vdName = existingVms[vd];
                    results.push({ isApp: false, isCategory: false, name: vdName, glyph: "", icon: "", exec: "cmd-vm delete-confirm '" + vdName + "'" });
                }
            }
            return results;
        }

        if (activeCategory === "actions") {
            for (var a1 = 0; a1 < actionItems.length; a1++) {
                var act = actionItems[a1];
                results.push({ isApp: false, isCategory: false, name: act.name, glyph: act.glyph, icon: "", exec: act.exec });
            }
            return results;
        }

        if (activeCategory === "setup") {
            for (var s1 = 0; s1 < setupItems.length; s1++) {
                var st = setupItems[s1];
                results.push({ isApp: false, isCategory: false, name: st.name, glyph: st.glyph, icon: "", exec: st.exec });
            }
            return results;
        }

        if (activeCategory === "help") {
            for (var h1 = 0; h1 < helpItems.length; h1++) {
                var hl = helpItems[h1];
                results.push({ isApp: false, isCategory: false, name: hl.name, glyph: hl.glyph, icon: "", exec: hl.exec });
            }
            return results;
        }

        if (activeCategory === "system") {
            for (var s2 = 0; s2 < systemActions.length; s2++) {
                var sys2 = systemActions[s2];
                results.push({ isApp: false, isCategory: false, name: sys2.name, glyph: sys2.glyph, icon: "", exec: sys2.exec });
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
                    var aName = (app2.name || "").toLowerCase();
                    var aId = (app2.id || "").toLowerCase();
                    if (aName.includes("vm-curator") || aName === "curator" || aId.includes("vm-curator")) continue;
                    results.push({ isApp: true, isCategory: false, name: app2.name || "", glyph: "", icon: app2.icon || "application-x-executable", appObj: app2 });
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
        width: 380
        height: Math.min(460, Math.max(100, 68 + (resultsList.count * 32)))
        anchors.centerIn: parent
        color: "#2e3440"
        border.color: "#4c566a"
        border.width: 1
        radius: 6
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 6

            // Header: Breadcrumb Path (only visible when in a submenu)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: menuWindow.activeCategory !== "root" && searchInput.text.length === 0

                // Back Button (shown if in submenu)
                Rectangle {
                    width: 24
                    height: 24
                    radius: 4
                    color: backMouseArea.containsMouse ? "#434c5e" : "#3b4252"

                    Text {
                        anchors.centerIn: parent
                        text: ""
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
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
                    font.pixelSize: 12
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Search Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 30
                color: "#3b4252"
                radius: 4
                border.color: searchInput.activeFocus ? "#88c0d0" : "#434c5e"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 6

                    Text {
                        text: "󰍉"
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: "#eceff4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        selectByMouse: true
                        selectionColor: "#88c0d0"
                        selectedTextColor: "#2e3440"
                        clip: true

                        Text {
                            anchors.fill: parent
                            text: menuWindow.activeCategory === "root" ? "Search..." : `Filter ${menuWindow.getBreadcrumbTitle()}...`
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
                    height: 30
                    radius: 4
                    color: index === menuWindow.searchIndex ? "#434c5e" : (rowMouseArea.containsMouse ? "#3b4252" : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        // 1. Font Glyph Icon (if present)
                        Text {
                            visible: modelData.glyph !== ""
                            text: modelData.glyph
                            color: index === menuWindow.searchIndex ? "#88c0d0" : "#d8dee9"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            Layout.preferredWidth: 16
                            horizontalAlignment: Text.AlignHCenter
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // 2. Scaled Desktop App Icon (14x14)
                        Item {
                            visible: modelData.glyph === "" && modelData.icon !== ""
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            Layout.alignment: Qt.AlignVCenter

                            Image {
                                anchors.fill: parent
                                source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : ""
                                sourceSize: Qt.size(14, 14)
                                fillMode: Image.PreserveAspectFit
                            }
                        }

                        // Label (single line, clean typography)
                        Text {
                            text: modelData.name
                            color: index === menuWindow.searchIndex ? "#88c0d0" : "#eceff4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.bold: index === menuWindow.searchIndex || modelData.isCategory
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Category drill-down arrow
                        Text {
                            text: modelData.isCategory ? "" : ""
                            color: "#88c0d0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            opacity: 0.7
                            visible: modelData.isCategory
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

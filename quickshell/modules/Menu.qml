import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: menuWindow

    property bool isOpen: false

    function open() {
        isOpen = true;
        searchInput.text = "";
        searchIndex = 0;
        searchInput.forceActiveFocus();
    }

    function close() {
        isOpen = false;
        searchInput.focus = false;
    }

    function toggle() {
        if (isOpen) close();
        else open();
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
        function toggle(): void { menuWindow.toggle(); }
        function open(): void { menuWindow.open(); }
        function close(): void { menuWindow.close(); }
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

    // Built-in system actions
    readonly property var systemActions: [
        { id: "action-terminal", name: "Terminal", comment: "Ghostty Terminal", icon: "utilities-terminal", exec: "xdg-terminal-exec" },
        { id: "action-btop", name: "Resource Monitor (btop)", comment: "System process and resource monitor", icon: "utilities-system-monitor", exec: "launch-or-focus-tui btop" },
        { id: "action-wiremix", name: "Audio Mixer (wiremix)", comment: "PipeWire volume and audio device control", icon: "audio-card", exec: "launch-or-focus-tui wiremix" },
        { id: "action-bluetui", name: "Bluetooth Manager (bluetui)", comment: "Bluetooth device management", icon: "bluetooth", exec: "launch-or-focus-tui bluetui" },
        { id: "action-impala", name: "WiFi Manager (impala)", comment: "Wireless network configuration", icon: "network-wireless", exec: "launch-wifi" },
        { id: "action-lock", name: "Lock Screen", comment: "Lock display session", icon: "system-lock-screen", exec: "hyprlock" },
        { id: "action-suspend", name: "Suspend", comment: "Sleep / suspend system", icon: "system-suspend", exec: "systemctl suspend" },
        { id: "action-reboot", name: "Reboot", comment: "Restart computer", icon: "system-reboot", exec: "systemctl reboot" },
        { id: "action-shutdown", name: "Shutdown", comment: "Power off computer", icon: "system-shutdown", exec: "systemctl poweroff" }
    ]

    property int searchIndex: 0

    function getFilteredItems() {
        var query = searchInput.text.trim().toLowerCase();
        var results = [];

        // 1. Match System Actions
        for (var i = 0; i < systemActions.length; i++) {
            var act = systemActions[i];
            if (query === "" || act.name.toLowerCase().includes(query) || (act.comment && act.comment.toLowerCase().includes(query))) {
                results.push({
                    isApp: false,
                    id: act.id,
                    name: act.name,
                    comment: act.comment,
                    icon: act.icon,
                    exec: act.exec
                });
            }
        }

        // 2. Match Desktop Applications
        if (DesktopEntries && DesktopEntries.applications) {
            var apps = DesktopEntries.applications.values;
            for (var j = 0; j < apps.length; j++) {
                var app = apps[j];
                if (!app || app.nodisplay) continue;
                var appName = app.name || "";
                var appComment = app.comment || app.genericName || "";
                if (query === "" || appName.toLowerCase().includes(query) || appComment.toLowerCase().includes(query)) {
                    results.push({
                        isApp: true,
                        id: app.id,
                        name: appName,
                        comment: appComment,
                        icon: app.icon || "application-x-executable",
                        appObj: app
                    });
                }
            }
        }

        return results;
    }

    function executeItem(item) {
        if (!item) return;
        if (item.isApp && item.appObj) {
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
        height: Math.min(520, Math.max(120, 68 + (resultsList.count * 48)))
        anchors.centerIn: parent
        color: "#2e3440"
        border.color: "#4c566a"
        border.width: 1
        radius: 8
        clip: true

        // Prevent clicks inside modal from closing
        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Top Search Bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
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
                        font.pixelSize: 16
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
                            text: "Search applications & actions..."
                            color: "#d8dee9"
                            opacity: 0.4
                            font.family: searchInput.font.family
                            font.pixelSize: searchInput.font.pixelSize
                            visible: searchInput.text.length === 0
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
                            var items = menuWindow.getFilteredItems();
                            if (items.length > 0 && menuWindow.searchIndex < items.length) {
                                menuWindow.executeItem(items[menuWindow.searchIndex]);
                            }
                        }

                        Keys.onEscapePressed: {
                            menuWindow.close();
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

                model: menuWindow.getFilteredItems()

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
                                font.bold: index === menuWindow.searchIndex
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

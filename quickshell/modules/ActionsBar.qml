import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"

Item {
    id: root

    property var bar: null
    property var menu: null
    property bool isHovered: false

    // State properties
    property bool cliampRunning: false
    property bool screensaverOff: false
    property bool nightlightOn: false
    property bool stayAwakeActive: false

    readonly property bool hasActive: cliampRunning || screensaverOff || nightlightOn || stayAwakeActive

    implicitHeight: 24
    implicitWidth: contentRow.implicitWidth

    function runCmd(cmd) {
        Quickshell.execDetached(["zsh", "-c", cmd]);
        refreshSoon();
    }

    function toggleActionsMenu() {
        if (root.menu) {
            root.menu.toggle("actions");
        } else {
            root.runCmd("quickshell ipc call menu actions");
        }
    }

    function refreshSoon() {
        refreshTimer.restart();
    }

    Timer {
        id: refreshTimer
        interval: 150
        onTriggered: statusProc.running = true
    }

    Timer {
        id: hoverExitTimer
        interval: 350
        onTriggered: root.isHovered = false
    }

    Process {
        id: statusProc
        command: ["zsh", "-c", "
            pgrep -x cliamp >/dev/null && c=1 || c=0
            [[ -f ~/.config/screensaver-off ]] && s=1 || s=0
            temp=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+')
            [[ -n $temp && $temp -lt 6000 && $temp -gt 0 ]] && n=1 || n=0
            systemctl --user is-active --quiet hypridle.service && i=0 || i=1
            echo \"$c|$s|$n|$i\"
        "]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                let text = this.text.trim();
                let parts = text.split("|");
                if (parts.length >= 4) {
                    root.cliampRunning = (parts[0] === "1");
                    root.screensaverOff = (parts[1] === "1");
                    root.nightlightOn = (parts[2] === "1");
                    root.stayAwakeActive = (parts[3] === "1");
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: statusProc.running = true
    }

    Row {
        id: contentRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        HoverHandler {
            id: barHoverHandler
            onHoveredChanged: {
                if (hovered) {
                    hoverExitTimer.stop();
                    root.isHovered = true;
                } else {
                    hoverExitTimer.restart();
                }
            }
        }

        // Actions (rocket) icon: permanently visible in place with low / dim visibility
        IconButton {
            id: triggerBtn
            bar: root.bar
            iconText: "󱓞"
            color: root.isHovered ? "#88c0d0" : "#4c566a"
            paddingHorizontal: 4
            tooltipText: "Click: Actions Menu"
            onClicked: root.toggleActionsMenu()
        }

        // Active Actions block: permanently visible when active, to the right of the rocket icon
        Row {
            id: activeRow
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            visible: root.hasActive

            // 1. Music (Active)
            IconButton {
                id: musicActiveBtn
                visible: root.cliampRunning
                bar: root.bar
                iconText: ""
                color: "#88c0d0"
                paddingHorizontal: 4
                tooltipText: "Music (cliamp - Running)\nLeft-click: Focus\nRight-click: Play / Pause"
                onClicked: root.runCmd("launch-or-focus-tui cliamp")
                onRightClicked: {
                    root.runCmd("playerctl play-pause 2>/dev/null");
                    root.refreshSoon();
                }
            }

            // 2. Screensaver (Active - Inhibited)
            IconButton {
                id: screensaverActiveBtn
                visible: root.screensaverOff
                bar: root.bar
                iconText: "󱄄"
                color: "#ebcb8b"
                paddingHorizontal: 4
                tooltipText: "Screensaver: Disabled (Stay Awake)\nClick to enable"
                onClicked: {
                    root.runCmd("toggle-screensaver");
                    root.refreshSoon();
                }
            }

            // 3. Nightlight (Active - Warm)
            IconButton {
                id: nightlightActiveBtn
                visible: root.nightlightOn
                bar: root.bar
                iconText: "󰔎"
                color: "#d08770"
                paddingHorizontal: 4
                tooltipText: "Nightlight: Active (4000K)\nClick to toggle daylight"
                onClicked: {
                    root.runCmd("toggle-nightlight");
                    root.refreshSoon();
                }
            }

            // 4. Idle Lock (Active - Inhibited)
            IconButton {
                id: idleActiveBtn
                visible: root.stayAwakeActive
                bar: root.bar
                iconText: "󱫖"
                color: "#bf616a"
                paddingHorizontal: 4
                tooltipText: "Idle Lock: Disabled (Stay Awake)\nClick to enable"
                onClicked: {
                    root.runCmd("toggle-idle");
                    root.refreshSoon();
                }
            }
        }

        // Inactive Actions area: smoothly expands to the right on hover
        Item {
            id: inactiveArea
            implicitHeight: 24
            implicitWidth: root.isHovered ? inactiveRow.implicitWidth : 0
            clip: true
            visible: implicitWidth > 0

            Behavior on implicitWidth {
                NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
            }

            Row {
                id: inactiveRow
                spacing: 2
                anchors.verticalCenter: parent.verticalCenter

                // 1. Music (Inactive)
                IconButton {
                    id: musicInactiveBtn
                    visible: !root.cliampRunning
                    bar: root.bar
                    iconText: ""
                    color: "#4c566a"
                    opacity: 0.5
                    paddingHorizontal: 4
                    tooltipText: "Music (cliamp)\nLeft-click: Launch cliamp\nRight-click: Play / Pause"
                    onClicked: root.runCmd("launch-or-focus-tui cliamp")
                    onRightClicked: {
                        root.runCmd("playerctl play-pause 2>/dev/null");
                        root.refreshSoon();
                    }
                }

                // 2. Screensaver (Inactive)
                IconButton {
                    id: screensaverInactiveBtn
                    visible: !root.screensaverOff
                    bar: root.bar
                    iconText: "󱄄"
                    color: "#4c566a"
                    opacity: 0.5
                    paddingHorizontal: 4
                    tooltipText: "Screensaver: Enabled\nClick to disable"
                    onClicked: {
                        root.runCmd("toggle-screensaver");
                        root.refreshSoon();
                    }
                }

                // 3. Nightlight (Inactive)
                IconButton {
                    id: nightlightInactiveBtn
                    visible: !root.nightlightOn
                    bar: root.bar
                    iconText: "󰔎"
                    color: "#4c566a"
                    opacity: 0.5
                    paddingHorizontal: 4
                    tooltipText: "Nightlight: Inactive (6000K)\nClick to toggle nightlight"
                    onClicked: {
                        root.runCmd("toggle-nightlight");
                        root.refreshSoon();
                    }
                }

                // 4. Idle Lock (Inactive)
                IconButton {
                    id: idleInactiveBtn
                    visible: !root.stayAwakeActive
                    bar: root.bar
                    iconText: "󱫖"
                    color: "#4c566a"
                    opacity: 0.5
                    paddingHorizontal: 4
                    tooltipText: "Idle Lock: Enabled\nClick to disable"
                    onClicked: {
                        root.runCmd("toggle-idle");
                        root.refreshSoon();
                    }
                }
            }
        }
    }
}

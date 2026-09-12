import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"

Item {
    id: root

    property var bar: null
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

        // Trigger icon shown when NO actions are active (or when hovered)
        Item {
            id: triggerWrapper
            implicitHeight: 24
            implicitWidth: (!root.hasActive || root.isHovered) ? triggerBtn.implicitWidth : 0
            clip: true
            visible: implicitWidth > 0

            Behavior on implicitWidth {
                NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
            }

            IconButton {
                id: triggerBtn
                bar: root.bar
                iconText: "󱓞"
                color: root.isHovered ? "#88c0d0" : "#4c566a"
                paddingHorizontal: 4
                tooltipText: "Actions Bar\nHover to reveal actions\nClick: Open Actions Menu"
                onClicked: root.runCmd("quickshell -p ~/.dotfiles/quickshell ipc call menu toggle")
            }
        }

        // 1. Music (cliamp)
        Item {
            id: musicWrapper
            property bool shouldShow: root.cliampRunning || root.isHovered
            implicitHeight: 24
            implicitWidth: shouldShow ? musicBtn.implicitWidth : 0
            clip: true
            visible: implicitWidth > 0

            Behavior on implicitWidth {
                NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
            }

            IconButton {
                id: musicBtn
                bar: root.bar
                iconText: ""
                color: root.cliampRunning ? "#88c0d0" : "#4c566a"
                opacity: root.cliampRunning ? 1.0 : 0.7
                paddingHorizontal: 4
                tooltipText: root.cliampRunning ?
                    "Music (cliamp - Running)\nLeft-click: Focus\nRight-click: Play / Pause" :
                    "Music (cliamp)\nLeft-click: Launch cliamp\nRight-click: Play / Pause"

                onClicked: root.runCmd("launch-or-focus-tui cliamp")
                onRightClicked: {
                    root.runCmd("playerctl play-pause 2>/dev/null");
                    root.refreshSoon();
                }
            }
        }

        // 2. Toggle Screensaver
        Item {
            id: screensaverWrapper
            property bool shouldShow: root.screensaverOff || root.isHovered
            implicitHeight: 24
            implicitWidth: shouldShow ? screensaverBtn.implicitWidth : 0
            clip: true
            visible: implicitWidth > 0

            Behavior on implicitWidth {
                NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
            }

            IconButton {
                id: screensaverBtn
                bar: root.bar
                iconText: "󱄄"
                color: root.screensaverOff ? "#ebcb8b" : "#4c566a"
                opacity: root.screensaverOff ? 1.0 : 0.7
                paddingHorizontal: 4
                tooltipText: root.screensaverOff ?
                    "Screensaver: Disabled (Stay Awake)\nClick to enable" :
                    "Screensaver: Enabled\nClick to disable"

                onClicked: {
                    root.runCmd("toggle-screensaver");
                    root.refreshSoon();
                }
            }
        }

        // 3. Toggle Nightlight
        Item {
            id: nightlightWrapper
            property bool shouldShow: root.nightlightOn || root.isHovered
            implicitHeight: 24
            implicitWidth: shouldShow ? nightlightBtn.implicitWidth : 0
            clip: true
            visible: implicitWidth > 0

            Behavior on implicitWidth {
                NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
            }

            IconButton {
                id: nightlightBtn
                bar: root.bar
                iconText: "󰔎"
                color: root.nightlightOn ? "#d08770" : "#4c566a"
                opacity: root.nightlightOn ? 1.0 : 0.7
                paddingHorizontal: 4
                tooltipText: root.nightlightOn ?
                    "Nightlight: Active (4000K)\nClick to toggle daylight" :
                    "Nightlight: Inactive (6000K)\nClick to toggle nightlight"

                onClicked: {
                    root.runCmd("toggle-nightlight");
                    root.refreshSoon();
                }
            }
        }

        // 4. Toggle Idle Lock
        Item {
            id: idleWrapper
            property bool shouldShow: root.stayAwakeActive || root.isHovered
            implicitHeight: 24
            implicitWidth: shouldShow ? idleBtn.implicitWidth : 0
            clip: true
            visible: implicitWidth > 0

            Behavior on implicitWidth {
                NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
            }

            IconButton {
                id: idleBtn
                bar: root.bar
                iconText: "󱫖"
                color: root.stayAwakeActive ? "#bf616a" : "#4c566a"
                opacity: root.stayAwakeActive ? 1.0 : 0.7
                paddingHorizontal: 4
                tooltipText: root.stayAwakeActive ?
                    "Idle Lock: Disabled (Stay Awake)\nClick to enable" :
                    "Idle Lock: Enabled\nClick to disable"

                onClicked: {
                    root.runCmd("toggle-idle");
                    root.refreshSoon();
                }
            }
        }
    }
}

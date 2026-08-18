import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components"

RowLayout {
    id: root
    spacing: 8

    // Helper process to execute commands asynchronously
    function runCmd(cmd) {
        cmdRunner.command = ["zsh", "-c", cmd];
        cmdRunner.running = true;
    }

    Process {
        id: cmdRunner
        command: []
        running: false
    }

    // 1. Launch Menu (NixOS / Menu icon)
    IconButton {
        iconText: ""
        color: "#88c0d0"
        tooltipText: "Menu (Super + Alt + Space)\nRight-click: Terminal"
        paddingHorizontal: 6

        onClicked: root.runCmd("launch-menu")
        onRightClicked: root.runCmd("xdg-terminal-exec")
    }

    // 2. Idle Inhibitor
    Item {
        id: idleModule
        implicitWidth: idleBtn.implicitWidth
        implicitHeight: idleBtn.implicitHeight

        property bool isIdleInhibited: false

        Process {
            id: idleCheckProc
            command: ["pgrep", "-x", "hypridle"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    // If hypridle is running, idle inhibitor is DEACTIVATED (normal locking)
                    // If hypridle is NOT running, idle inhibitor is ACTIVATED (prevent locking)
                    idleModule.isIdleInhibited = (idleCheckProc.exitCode !== 0);
                }
            }
        }

        Timer {
            interval: 5000
            running: true
            repeat: true
            onTriggered: {
                idleCheckProc.running = true;
            }
        }

        IconButton {
            id: idleBtn
            iconText: idleModule.isIdleInhibited ? "" : ""
            color: idleModule.isIdleInhibited ? "#ebcb8b" : "#d8dee9"
            tooltipText: idleModule.isIdleInhibited ? "Idle inhibitor: Active (Screen stays on)" : "Idle inhibitor: Inactive"
            paddingHorizontal: 4

            onClicked: {
                root.runCmd("toggle-idle");
                idleCheckTimer.start();
            }
        }

        Timer {
            id: idleCheckTimer
            interval: 300
            onTriggered: idleCheckProc.running = true
        }
    }

    // 3. Weather Module
    Item {
        id: weatherModule
        implicitWidth: weatherBtn.implicitWidth
        implicitHeight: weatherBtn.implicitHeight

        property string weatherIcon: ""
        property string weatherText: ""
        property string weatherTooltip: "Loading weather..."

        Process {
            id: weatherProc
            command: ["weather"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        let json = JSON.parse(this.text.trim());
                        if (json.text) weatherModule.weatherIcon = json.text;
                        if (json.tooltip) weatherModule.weatherTooltip = json.tooltip;
                    } catch (e) {
                        weatherModule.weatherIcon = "";
                    }
                }
            }
        }

        Timer {
            interval: 900000 // 15 minutes
            running: true
            repeat: true
            onTriggered: weatherProc.running = true
        }

        IconButton {
            id: weatherBtn
            iconText: weatherModule.weatherIcon
            text: weatherModule.weatherText
            color: "#d8dee9"
            tooltipText: weatherModule.weatherTooltip
            paddingHorizontal: 4

            onClicked: weatherProc.running = true
            onRightClicked: root.runCmd("launch-weather-report")
        }
    }
}

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components"

RowLayout {
    id: root
    spacing: 8

    property var bar: null

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

    // Launch Menu (NixOS / Menu icon)
    IconButton {
        iconText: ""
        color: "#88c0d0"
        tooltipText: "Menu (Super + Alt + Space)\nRight-click: Terminal"
        paddingHorizontal: 6

        onClicked: root.runCmd("launch-menu")
        onRightClicked: root.runCmd("xdg-terminal-exec")
    }
}

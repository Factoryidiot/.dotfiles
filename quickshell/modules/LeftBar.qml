import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../components"

RowLayout {
    id: root
    spacing: 8

    property var bar: null
    property var menu: null

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
        tooltipText: "Launcher (Super + Space)\nRight-click: Terminal"
        paddingHorizontal: 6

        onClicked: {
            if (root.menu) {
                root.menu.toggle();
            } else {
                root.runCmd("quickshell -p ~/.dotfiles/quickshell ipc call menu toggle");
            }
        }
        onRightClicked: root.runCmd("xdg-terminal-exec")
    }
}

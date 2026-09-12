import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"

RowLayout {
    id: root
    spacing: 8

    property var bar: null
    property var menu: null

    function runCmd(cmd) {
        Quickshell.execDetached(["zsh", "-c", cmd]);
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
                root.runCmd("quickshell ipc call menu toggle");
            }
        }
        onRightClicked: root.runCmd("xdg-terminal-exec")
    }

    // Actions Bar (Status indicators & quick toggles)
    ActionsBar {
        id: actionsBar
        bar: root.bar
        menu: root.menu
    }
}

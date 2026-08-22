import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import "../components"

RowLayout {
    id: root
    spacing: 2

    // Set of persistent workspaces to always display
    readonly property var defaultWorkspaces: [1, 2, 3, 4, 5]

    // Active workspace ID from Hyprland
    readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    // Build the list of workspace IDs to show (1-5 plus any existing higher IDs)
    function getWorkspaceList() {
        let wsSet = new Set(defaultWorkspaces);
        if (Hyprland.workspaces) {
            for (let i = 0; i < Hyprland.workspaces.values.length; i++) {
                let ws = Hyprland.workspaces.values[i];
                if (ws && ws.id > 0) {
                    wsSet.add(ws.id);
                }
            }
        }
        let list = Array.from(wsSet);
        list.sort((a, b) => a - b);
        return list;
    }

    Repeater {
        model: root.getWorkspaceList()

        delegate: Item {
            id: wsDelegate
            readonly property int wsId: modelData
            readonly property bool isActive: wsId === root.activeWsId

            implicitWidth: wsBtn.implicitWidth
            implicitHeight: wsBtn.implicitHeight

            IconButton {
                id: wsBtn
                text: wsDelegate.isActive ? "󱓻" : wsDelegate.wsId.toString()
                color: wsDelegate.isActive ? "#88c0d0" : "#d8dee9"
                activeColor: "#88c0d0"
                isActive: wsDelegate.isActive
                paddingHorizontal: 5
                paddingVertical: 1

                onClicked: {
                    Hyprland.dispatch("workspace " + wsDelegate.wsId);
                }

                onScrollUp: {
                    Hyprland.dispatch("workspace e-1");
                }

                onScrollDown: {
                    Hyprland.dispatch("workspace e+1");
                }
            }
        }
    }
}

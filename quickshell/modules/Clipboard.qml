import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: clipWindow

    property bool isOpen: false
    property var clipItems: []
    property int selectedIndex: 0
    property string searchQuery: ""

    Process {
        id: loadClipProc
        command: ["zsh", "-c", "cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text;
                if (!out || out.trim().length === 0) {
                    clipWindow.clipItems = [];
                    return;
                }
                let lines = out.split("\n");
                let items = [];
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i];
                    if (!line || line.trim().length === 0) continue;
                    let tabIdx = line.indexOf("\t");
                    let id = "";
                    let text = "";
                    if (tabIdx !== -1) {
                        id = line.substring(0, tabIdx).trim();
                        text = line.substring(tabIdx + 1);
                    } else {
                        text = line;
                    }
                    items.push({
                        raw: line,
                        id: id,
                        text: text.trim(),
                        isBinary: text.includes("[[ binary data") || text.includes("[[ image")
                    });
                }
                clipWindow.clipItems = items;
            }
        }
    }

    function open() {
        searchQuery = "";
        searchInput.text = "";
        selectedIndex = 0;
        loadClipProc.running = true;
        isOpen = true;
        searchInput.forceActiveFocus();
    }

    function close() {
        isOpen = false;
        searchInput.focus = false;
    }

    function toggle() {
        if (isOpen) {
            close();
        } else {
            open();
        }
    }

    function copyAndClose(item) {
        if (!item || !item.raw) return;
        // Pipe the exact raw line into cliphist decode | wl-copy
        let cmd = "printf '%s\\n' " + JSON.stringify(item.raw) + " | cliphist decode | wl-copy";
        Quickshell.execDetached(["zsh", "-c", cmd]);
        close();
    }

    function deleteItem(item, idx) {
        if (!item || !item.raw) return;
        let cmd = "printf '%s\\n' " + JSON.stringify(item.raw) + " | cliphist delete";
        Quickshell.execDetached(["zsh", "-c", cmd]);
        let items = clipItems.slice();
        let found = items.indexOf(item);
        if (found !== -1) {
            items.splice(found, 1);
            clipItems = items;
        }
    }

    function clearAll() {
        Quickshell.execDetached(["zsh", "-c", "cliphist wipe"]);
        clipItems = [];
        close();
    }

    function getFilteredItems() {
        let q = searchQuery.toLowerCase().trim();
        if (!q) return clipItems;
        return clipItems.filter(it => it.text.toLowerCase().includes(q));
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
    WlrLayershell.namespace: "quickshell-clipboard"

    IpcHandler {
        target: "clipboard"
        function toggle(): void { clipWindow.toggle(); }
        function open(): void { clipWindow.open(); }
        function close(): void { clipWindow.close(); }
    }

    // Scrim / Backdrop dismiss
    MouseArea {
        anchors.fill: parent
        onClicked: clipWindow.close()
    }

    // Main Floating Modal Container
    Rectangle {
        id: modalBox
        width: 480
        height: Math.min(480, Math.max(120, 80 + (resultsList.count * 36)))
        anchors.centerIn: parent
        color: "#2e3440"
        border.color: "#d8dee9"
        border.width: 1
        radius: 0
        clip: true

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => mouse.accepted = true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            // Top Header: Title, Count, Clear Button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "󰅍"
                    color: "#88c0d0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                }

                Text {
                    text: "Clipboard History"
                    color: "#eceff4"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.bold: true
                }

                Rectangle {
                    color: "#3b4252"
                    radius: 0
                    implicitWidth: countText.implicitWidth + 8
                    implicitHeight: countText.implicitHeight + 4

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: resultsList.count.toString()
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: clearText.implicitWidth + 10
                    implicitHeight: clearText.implicitHeight + 4
                    color: clearHover.containsMouse ? "#bf616a" : "#3b4252"
                    radius: 0

                    Text {
                        id: clearText
                        anchors.centerIn: parent
                        text: "󰆴 Clear"
                        color: clearHover.containsMouse ? "#2e3440" : "#d8dee9"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }

                    MouseArea {
                        id: clearHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clipWindow.clearAll()
                    }
                }
            }

            // Search input field
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                color: "#3b4252"
                radius: 0
                border.width: 1
                border.color: searchInput.activeFocus ? "#88c0d0" : "#434c5e"

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
                        verticalAlignment: TextInput.AlignVCenter
                        focus: true
                        selectByMouse: true

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Type to search history..."
                            color: "#d8dee9"
                            opacity: 0.4
                            font: parent.font
                            visible: !parent.text && !parent.inputMethodComposing
                        }

                        onTextChanged: {
                            clipWindow.searchQuery = text;
                            clipWindow.selectedIndex = 0;
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                clipWindow.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down) {
                                if (resultsList.count > 0) {
                                    clipWindow.selectedIndex = Math.min(clipWindow.selectedIndex + 1, resultsList.count - 1);
                                    resultsList.positionViewAtIndex(clipWindow.selectedIndex, ListView.Contain);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up) {
                                if (resultsList.count > 0) {
                                    clipWindow.selectedIndex = Math.max(clipWindow.selectedIndex - 1, 0);
                                    resultsList.positionViewAtIndex(clipWindow.selectedIndex, ListView.Contain);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                let filtered = clipWindow.getFilteredItems();
                                if (filtered.length > 0 && clipWindow.selectedIndex < filtered.length) {
                                    clipWindow.copyAndClose(filtered[clipWindow.selectedIndex]);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
                                let filtered = clipWindow.getFilteredItems();
                                if (filtered.length > 0 && clipWindow.selectedIndex < filtered.length) {
                                    clipWindow.deleteItem(filtered[clipWindow.selectedIndex], clipWindow.selectedIndex);
                                }
                                event.accepted = true;
                            }
                        }
                    }

                    Text {
                        visible: searchInput.text.length > 0
                        text: "󰅖"
                        color: "#d8dee9"
                        opacity: 0.7
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
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
                boundsBehavior: Flickable.StopAtBounds

                model: clipWindow.getFilteredItems()

                delegate: Rectangle {
                    required property var modelData
                    required property int index

                    width: resultsList.width
                    height: 32
                    radius: 0
                    color: index === clipWindow.selectedIndex ? "#434c5e" : (itemHover.containsMouse ? "#3b4252" : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: modelData.isBinary ? "󰹑" : "󰅍"
                            color: index === clipWindow.selectedIndex ? "#88c0d0" : "#81a1c1"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }

                        Text {
                            text: modelData.text
                            color: index === clipWindow.selectedIndex ? "#88c0d0" : "#eceff4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "󰆴"
                            color: delHover.containsMouse ? "#bf616a" : "#4c566a"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            visible: itemHover.containsMouse || index === clipWindow.selectedIndex

                            MouseArea {
                                id: delHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: clipWindow.deleteItem(modelData, index)
                            }
                        }
                    }

                    MouseArea {
                        id: itemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: clipWindow.selectedIndex = index
                        onClicked: clipWindow.copyAndClose(modelData)
                    }
                }
            }

            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: resultsList.count === 0

                Text {
                    anchors.centerIn: parent
                    text: clipWindow.searchQuery.length > 0 ? "No matching clipboard entries" : "Clipboard is empty"
                    color: "#d8dee9"
                    opacity: 0.5
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }
        }
    }
}

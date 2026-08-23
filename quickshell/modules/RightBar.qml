import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import "../components"

RowLayout {
    id: root
    spacing: 8

    property var bar: null

    function runCmd(cmd) {
        Quickshell.execDetached(["zsh", "-c", cmd]);
    }

    property var activeTrayItem: null
    property var activeTrayAnchor: null
    property bool trayMenuOpen: false

    property var submenuStack: []
    readonly property int submenuDepth: submenuStack.length
    readonly property string currentSubmenuTitle: submenuDepth > 0 ? submenuStack[submenuDepth - 1].title : ""
    readonly property var currentChildren: root.submenuDepth > 0
        ? (root.submenuStack[root.submenuDepth - 1].opener && root.submenuStack[root.submenuDepth - 1].opener.children ? root.submenuStack[root.submenuDepth - 1].opener.children.values : [])
        : (trayMenuOpener.children ? trayMenuOpener.children.values : [])

    property bool menuLevelSettling: false

    Component {
        id: submenuOpenerComponent
        QsMenuOpener {}
    }

    Timer {
        id: menuLevelSettleTimer
        interval: 200
        onTriggered: root.menuLevelSettling = false
    }

    function settleMenuLevel() {
        menuLevelSettling = true;
        menuLevelSettleTimer.restart();
    }

    function resetTrayMenu() {
        menuLevelSettling = false;
        menuLevelSettleTimer.stop();
        if (trayMenuFlick) trayMenuFlick.contentY = 0;
        var openers = submenuStack;
        submenuStack = [];
        for (var i = openers.length - 1; i >= 0; i--) {
            if (openers[i].opener) openers[i].opener.destroy();
        }
    }

    function enterSubmenu(entry, title) {
        var opener = submenuOpenerComponent.createObject(root, { menu: entry });
        if (!opener) return;
        var stack = submenuStack.slice();
        stack.push({ opener: opener, title: title });
        submenuStack = stack;
        settleMenuLevel();
    }

    function leaveSubmenu() {
        if (submenuStack.length === 0) return;
        var stack = submenuStack.slice();
        var top = stack.pop();
        submenuStack = stack;
        if (top.opener) top.opener.destroy();
        settleMenuLevel();
    }

    function openTrayMenu(item, anchorItem) {
        if (root.trayMenuOpen && root.activeTrayItem === item) {
            root.trayMenuOpen = false;
            return;
        }
        root.resetTrayMenu();
        root.activeTrayItem = item;
        root.activeTrayAnchor = anchorItem;
        root.trayMenuOpen = true;
    }

    QsMenuOpener {
        id: trayMenuOpener
        menu: root.activeTrayItem ? root.activeTrayItem.menu : null
    }

    // Floating Tray Menu Popup (styled with SwayOSD border & separator colors)
    PopupWindow {
        id: trayMenuPopup

        // Explicit surface dimensions for Wayland compositor
        implicitWidth: 280
        implicitHeight: menuContainer.implicitHeight

        anchor {
            id: trayPopupAnchor
            window: root.bar
            adjustment: PopupAdjustment.Slide
            edges: Edges.Top | Edges.Left
            gravity: Edges.Bottom | Edges.Right
            rect.width: 1
            rect.height: 1

            onAnchoring: {
                var target = root.activeTrayAnchor;
                if (!target || !root.bar) return;
                var popupW = trayMenuPopup.implicitWidth;
                var point = root.bar.contentItem.mapFromItem(target, 0, 0);
                var posX = Math.round(point.x + target.width - popupW);
                var posY = Math.round(root.bar.height + 6);
                trayPopupAnchor.rect.x = Math.max(10, posX);
                trayPopupAnchor.rect.y = posY;
            }
        }

        visible: root.trayMenuOpen && root.activeTrayItem !== null && (root.currentChildren ? (root.currentChildren.length > 0 || (root.currentChildren.values && root.currentChildren.values.length > 0)) : false)
        color: "transparent"

        onVisibleChanged: {
            if (!visible) root.resetTrayMenu();
        }

        Rectangle {
            id: menuContainer
            width: 280
            implicitHeight: Math.min(450, menuHeaderColumn.implicitHeight + (trayMenuColumn.implicitHeight > 0 ? Math.min(380, trayMenuColumn.implicitHeight) : 40) + 16)
            color: "#2e3440"
            border.color: "#d8dee9"
            border.width: 1
            radius: 6
            clip: true

            ColumnLayout {
                id: menuMainLayout
                anchors.fill: parent
                anchors.margins: 6
                spacing: 0

                // Submenu Header (when drilled into a submenu)
                ColumnLayout {
                    id: menuHeaderColumn
                    Layout.fillWidth: true
                    visible: root.submenuDepth > 0
                    spacing: 2

                    Item {
                        Layout.fillWidth: true
                        implicitHeight: 30

                        Rectangle {
                            anchors.fill: parent
                            radius: 4
                            color: backMouse.containsMouse ? "#434c5e" : "transparent"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            text: "‹"
                            color: "#88c0d0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 26
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            text: root.currentSubmenuTitle
                            color: "#eceff4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: backMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.menuLevelSettling) return;
                                if (trayMenuFlick) trayMenuFlick.contentY = 0;
                                root.leaveSubmenu();
                            }
                        }
                    }

                    // Separator below header in SwayOSD border color
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        height: 1
                        color: "#d8dee9"
                        opacity: 0.35
                    }
                }

                // Scrollable Item List
                Flickable {
                    id: trayMenuFlick
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.min(380, trayMenuColumn.implicitHeight)
                    contentWidth: width
                    contentHeight: trayMenuColumn.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    interactive: contentHeight > height

                    ColumnLayout {
                        id: trayMenuColumn
                        width: parent.width
                        spacing: 2

                        Repeater {
                            model: root.currentChildren || []

                            delegate: Item {
                                id: menuRow
                                required property var modelData
                                required property int index

                                readonly property string rowText: String(modelData.text || "")
                                readonly property bool isSep: modelData.isSeparator || false
                                readonly property bool hasKids: modelData.hasChildren || false
                                readonly property bool isChecked: modelData.checkState === Qt.Checked || (modelData.checked === true)

                                Layout.fillWidth: true
                                implicitHeight: isSep ? 8 : 30
                                visible: rowText !== "" || isSep
                                opacity: (modelData.enabled !== false) ? 1.0 : 0.45

                                // Separator line in SwayOSD border color
                                Rectangle {
                                    visible: menuRow.isSep
                                    anchors.centerIn: parent
                                    width: parent.width - 12
                                    height: 1
                                    color: "#d8dee9"
                                    opacity: 0.35
                                }

                                // Hover background
                                Rectangle {
                                    visible: !menuRow.isSep
                                    anchors.fill: parent
                                    radius: 4
                                    color: rowMouse.containsMouse && (modelData.enabled !== false) ? "#434c5e" : "transparent"
                                }

                                RowLayout {
                                    visible: !menuRow.isSep
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    // Checkmark if checked
                                    Text {
                                        visible: menuRow.isChecked
                                        text: ""
                                        color: "#88c0d0"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                    }

                                    // Optional item icon
                                    Image {
                                        visible: String(menuRow.modelData.icon || "") !== ""
                                        source: String(menuRow.modelData.icon || "")
                                        sourceSize: Qt.size(14, 14)
                                        Layout.preferredWidth: 14
                                        Layout.preferredHeight: 14
                                        fillMode: Image.PreserveAspectFit
                                    }

                                    // Label text in SwayOSD / tooltip color
                                    Text {
                                        Layout.fillWidth: true
                                        text: menuRow.rowText
                                        color: rowMouse.containsMouse ? "#88c0d0" : "#d8dee9"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    // Submenu chevron
                                    Text {
                                        visible: menuRow.hasKids
                                        text: "›"
                                        color: rowMouse.containsMouse ? "#88c0d0" : "#d8dee9"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    enabled: !menuRow.isSep && (menuRow.modelData.enabled !== false)
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                                    onClicked: {
                                        if (root.menuLevelSettling) return;
                                        if (menuRow.hasKids) {
                                            trayMenuFlick.contentY = 0;
                                            root.enterSubmenu(menuRow.modelData, menuRow.rowText);
                                        } else {
                                            if (menuRow.modelData.trigger) {
                                                menuRow.modelData.trigger();
                                            } else if (menuRow.modelData.triggered) {
                                                menuRow.modelData.triggered();
                                            }
                                            root.trayMenuOpen = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 1. Collapsible System Tray Drawer
    RowLayout {
        id: traySection
        spacing: 2
        visible: SystemTray.items.values.length > 0

        property bool isExpanded: false

        // Toggle Drawer Chevron Button
        IconButton {
            id: trayToggleBtn
            iconText: traySection.isExpanded ? "" : ""
            color: "#81a1c1"
            tooltipText: traySection.isExpanded ? "Hide system tray" : `Show system tray (${SystemTray.items.values.length})`
            paddingHorizontal: 2
            paddingVertical: 2

            onClicked: {
                traySection.isExpanded = !traySection.isExpanded;
            }
        }

        // Sliding Clip Container for Tray Icons
        Item {
            id: trayClip
            implicitHeight: 24
            implicitWidth: traySection.isExpanded ? trayRow.implicitWidth : 0
            clip: true

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            RowLayout {
                id: trayRow
                spacing: 4
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: SystemTray.items.values
                    delegate: Item {
                        id: trayDelegate
                        required property SystemTrayItem modelData

                        implicitWidth: 20
                        implicitHeight: 24

                        Rectangle {
                            id: trayBg
                            anchors.fill: parent
                            radius: 3
                            color: "#434c5e"
                            opacity: trayMouseArea.containsMouse ? 0.4 : 0.0
                            visible: trayMouseArea.containsMouse

                            Behavior on opacity {
                                NumberAnimation { duration: 120 }
                            }
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: trayDelegate.modelData.icon
                            sourceSize: Qt.size(14, 14)
                            fillMode: Image.PreserveAspectFit
                        }

                        MouseArea {
                            id: trayMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                var text = trayDelegate.modelData.tooltip !== "" ? trayDelegate.modelData.tooltip : trayDelegate.modelData.title;
                                var b = root.bar;
                                if (b && text !== "") {
                                    b.showTooltip(trayDelegate, text);
                                }
                            }

                            onExited: {
                                var b = root.bar;
                                if (b) {
                                    b.hideTooltip(trayDelegate);
                                }
                            }

                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton || trayDelegate.modelData.onlyMenu) {
                                    if (trayDelegate.modelData.hasMenu) {
                                        root.openTrayMenu(trayDelegate.modelData, trayDelegate);
                                    } else {
                                        trayDelegate.modelData.secondaryActivate();
                                    }
                                } else if (mouse.button === Qt.MiddleButton) {
                                    trayDelegate.modelData.secondaryActivate();
                                } else {
                                    root.trayMenuOpen = false;
                                    trayDelegate.modelData.activate();
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 2. CPU / Resource Monitor
    IconButton {
        iconText: "󰍛"
        color: "#d8dee9"
        tooltipText: "Resource Monitor (btop)"
        paddingHorizontal: 3

        onClicked: root.runCmd("launch-or-focus-tui btop")
    }

    // 3. Music Player (cliamp) - only visible when audio is playing
    Item {
        id: musicModule
        visible: isPlaying
        implicitWidth: visible ? musicBtn.implicitWidth : 0
        implicitHeight: visible ? musicBtn.implicitHeight : 0

        property string trackInfo: ""
        property bool isPlaying: false

        Process {
            id: playerProc
            command: ["zsh", "-c", "status=$(playerctl status 2>/dev/null); if [[ $status == 'Playing' ]]; then artist=$(playerctl metadata artist 2>/dev/null); title=$(playerctl metadata title 2>/dev/null); echo \"$status|$artist|$title\"; else echo 'Stopped'; fi"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let out = this.text.trim();
                    if (out.startsWith("Playing")) {
                        musicModule.isPlaying = true;
                        let parts = out.split("|");
                        let artist = parts[1] || "";
                        let title = parts[2] || "";
                        musicModule.trackInfo = (artist.length > 0 ? artist + " - " : "") + title;
                    } else {
                        musicModule.isPlaying = false;
                        musicModule.trackInfo = "";
                    }
                }
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: playerProc.running = true
        }

        IconButton {
            id: musicBtn
            iconText: ""
            color: "#88c0d0"
            tooltipText: musicModule.trackInfo !== "" ? 
                `Music Player (cliamp)\n${musicModule.trackInfo}\nLeft-click: Open Player\nRight-click: Play / Pause` :
                "Music Player (cliamp)\nLeft-click: Open Player\nRight-click: Play / Pause"
            paddingHorizontal: 3

            onClicked: root.runCmd("launch-or-focus-tui cliamp")
            onRightClicked: {
                root.runCmd("playerctl play-pause 2>/dev/null");
                playerProc.running = true;
            }
        }
    }

    // 4. Bluetooth Module
    Item {
        id: btModule
        implicitWidth: btBtn.implicitWidth
        implicitHeight: btBtn.implicitHeight

        property string btIcon: ""
        property string btTooltip: "Bluetooth"

        Process {
            id: btProc
            command: ["zsh", "-c", "bluetoothctl show | grep -q 'Powered: yes' && (bluetoothctl info 2>/dev/null | grep -q 'Connected: yes' && echo 'connected' || echo 'on') || echo 'off'"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let out = this.text.trim();
                    if (out === "connected") {
                        btModule.btIcon = "󰂱";
                        btModule.btTooltip = "Bluetooth: Connected";
                    } else if (out === "on") {
                        btModule.btIcon = "";
                        btModule.btTooltip = "Bluetooth: Enabled";
                    } else {
                        btModule.btIcon = "󰂲";
                        btModule.btTooltip = "Bluetooth: Disabled";
                    }
                }
            }
        }

        Timer {
            interval: 5000
            running: true
            repeat: true
            onTriggered: btProc.running = true
        }

        IconButton {
            id: btBtn
            iconText: btModule.btIcon
            color: btModule.btIcon === "󰂱" ? "#88c0d0" : "#d8dee9"
            tooltipText: btModule.btTooltip
            paddingHorizontal: 3

            onClicked: root.runCmd("launch-or-focus-tui bluetui")
        }
    }

    // 4. Network Module (iwd & nmcli aware)
    Item {
        id: netModule
        implicitWidth: netBtn.implicitWidth
        implicitHeight: netBtn.implicitHeight

        property string netIcon: "󰤨"
        property string netTooltip: "Network"

        Process {
            id: netProc
            command: ["zsh", "-c", `
                # Check for active ethernet first
                for eth in /sys/class/net/e*; do
                    if [[ -d "$eth" && "$(cat $eth/operstate 2>/dev/null)" == "up" ]]; then
                        echo "ethernet:Connected"
                        exit 0
                    fi
                done

                # Check iwd (iwctl)
                iw_out=$(iwctl station wlan0 show 2>/dev/null)
                if [[ "$iw_out" =~ "State"[[:space:]]+"connected" ]]; then
                    ssid=$(echo "$iw_out" | grep "Connected network" | sed "s/.*Connected network[[:space:]]*//" | xargs)
                    rssi=$(echo "$iw_out" | grep "RSSI" | head -1 | grep -oE -- "-[0-9]+" | head -1)
                    echo "wifi:\${ssid:-Connected}:\${rssi:--60}"
                    exit 0
                fi

                # Check nmcli fallback
                if command -v nmcli &>/dev/null; then
                    nm_out=$(nmcli -t -f TYPE,STATE,SIGNAL,CONNECTION dev 2>/dev/null | grep ':connected' | head -1)
                    if [[ "$nm_out" =~ ^wifi ]]; then
                        parts=(\${(s/:/)nm_out})
                        echo "wifi:\${parts[4]:-Connected}:\${parts[3]:-70}"
                        exit 0
                    fi
                fi

                echo "disconnected"
            `]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let out = this.text.trim();
                    if (out.startsWith("ethernet")) {
                        netModule.netIcon = "󰀂";
                        netModule.netTooltip = "Ethernet Connected";
                    } else if (out.startsWith("wifi")) {
                        let parts = out.split(":");
                        let ssid = parts[1] || "WiFi";
                        let val = parseInt(parts[2]) || -60;
                        
                        // Handle RSSI (dBm, negative) or percentage (0-100)
                        let percent = 70;
                        if (val < 0) {
                            percent = Math.min(100, Math.max(0, Math.round(2 * (val + 100))));
                        } else {
                            percent = val;
                        }

                        if (percent >= 80) netModule.netIcon = "󰤨";
                        else if (percent >= 60) netModule.netIcon = "󰤥";
                        else if (percent >= 40) netModule.netIcon = "󰤢";
                        else if (percent >= 20) netModule.netIcon = "󰤟";
                        else netModule.netIcon = "󰤯";

                        netModule.netTooltip = `WiFi: ${ssid} (${percent}%)`;
                    } else {
                        netModule.netIcon = "󰤮";
                        netModule.netTooltip = "Network Disconnected";
                    }
                }
            }
        }

        Timer {
            interval: 4000
            running: true
            repeat: true
            onTriggered: netProc.running = true
        }

        IconButton {
            id: netBtn
            iconText: netModule.netIcon
            color: "#d8dee9"
            tooltipText: netModule.netTooltip
            paddingHorizontal: 3

            onClicked: root.runCmd("launch-wifi")
        }
    }

    // 5. Audio / Pipewire Module (pamixer integration)
    Item {
        id: audioModule
        implicitWidth: audioBtn.implicitWidth
        implicitHeight: audioBtn.implicitHeight

        property int volumePercent: 80
        property bool isMuted: false

        Process {
            id: audioProc
            command: ["zsh", "-c", "pamixer --get-volume 2>/dev/null; pamixer --get-mute 2>/dev/null"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let lines = this.text.trim().split("\n");
                    if (lines.length >= 1 && lines[0] !== "") {
                        audioModule.volumePercent = parseInt(lines[0]) || 0;
                    }
                    if (lines.length >= 2) {
                        audioModule.isMuted = (lines[1].trim() === "true");
                    }
                }
            }
        }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: audioProc.running = true
        }

        function getAudioIcon() {
            if (isMuted || volumePercent === 0) return "";
            if (volumePercent < 30) return "";
            if (volumePercent < 70) return "";
            return "";
        }

        IconButton {
            id: audioBtn
            iconText: audioModule.getAudioIcon()
            color: audioModule.isMuted ? "#bf616a" : "#d8dee9"
            tooltipText: `Volume: ${audioModule.volumePercent}%${audioModule.isMuted ? " (Muted)" : ""}`
            paddingHorizontal: 3

            onClicked: root.runCmd("launch-or-focus-tui wiremix")
            onRightClicked: {
                root.runCmd("pamixer -t");
                audioRefreshTimer.restart();
            }
            onScrollUp: {
                root.runCmd("pamixer -i 5");
                audioRefreshTimer.restart();
            }
            onScrollDown: {
                root.runCmd("pamixer -d 5");
                audioRefreshTimer.restart();
            }
        }

        Timer {
            id: audioRefreshTimer
            interval: 150
            onTriggered: audioProc.running = true
        }
    }

    // 6. Battery / Power Module (AC plug & threshold aware)
    Item {
        id: batModule
        implicitWidth: batBtn.implicitWidth
        implicitHeight: batBtn.implicitHeight

        property int capacity: 100
        property string status: "Discharging"
        property bool isPluggedIn: false

        Process {
            id: batProc
            command: ["zsh", "-c", `
                ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1)
                cap=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1)
                stat=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1)
                echo "\${ac:-0}|\${cap:-100}|\${stat:-Discharging}"
            `]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let parts = this.text.trim().split("|");
                    if (parts.length >= 3) {
                        batModule.isPluggedIn = (parts[0].trim() === "1");
                        batModule.capacity = parseInt(parts[1]) || 100;
                        batModule.status = parts[2].trim();
                    }
                }
            }
        }

        Timer {
            interval: 5000
            running: true
            repeat: true
            onTriggered: batProc.running = true
        }

        function getBatIcon() {
            let cap = capacity;
            let charging = status === "Charging";
            let fullOrHeld = status === "Full" || status === "Not charging";

            if (isPluggedIn) {
                if (fullOrHeld) {
                    return "";
                }
                if (charging) {
                    if (cap >= 90) return "󰂅";
                    if (cap >= 80) return "󰂋";
                    if (cap >= 70) return "󰂊";
                    if (cap >= 60) return "󰂉";
                    if (cap >= 50) return "󰢝";
                    if (cap >= 40) return "󰂈";
                    if (cap >= 30) return "󰂇";
                    if (cap >= 20) return "󰂆";
                    return "󰢜";
                }
                return "";
            } else {
                if (cap >= 90) return "󰁹";
                if (cap >= 80) return "󰂂";
                if (cap >= 70) return "󰂁";
                if (cap >= 60) return "󰂀";
                if (cap >= 50) return "󰁿";
                if (cap >= 40) return "󰁾";
                if (cap >= 30) return "󰁽";
                if (cap >= 20) return "󰁼";
                if (cap >= 10) return "󰁻";
                return "󰁺";
            }
        }

        function getTooltipText() {
            if (isPluggedIn) {
                if (status === "Not charging") {
                    return `Power: Plugged In (${capacity}%, Charge Limit Active)`;
                } else if (status === "Charging") {
                    return `Power: Charging (${capacity}%)`;
                } else {
                    return `Power: Plugged In (${capacity}%)`;
                }
            } else {
                return `Battery: ${capacity}% (${status})`;
            }
        }

        IconButton {
            id: batBtn
            iconText: batModule.getBatIcon()
            color: (!batModule.isPluggedIn && batModule.capacity <= 15) ? "#bf616a" : ((!batModule.isPluggedIn && batModule.capacity <= 25) ? "#ebcb8b" : "#d8dee9")
            tooltipText: batModule.getTooltipText()
            paddingHorizontal: 3

            onClicked: root.runCmd("launch-menu power")
            onRightClicked: root.runCmd('notify-send -u low "$(battery-status)"')
        }
    }

    // 7. Weather Popup
    WeatherPopup {
        id: weatherPopup
        bar: root.bar
        anchorTarget: weatherBtn
    }

    // 7. Weather Module (placed beside clock)
    Item {
        id: weatherModule
        implicitWidth: weatherBtn.implicitWidth
        implicitHeight: weatherBtn.implicitHeight

        property string weatherIcon: ""
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
            color: weatherPopup.isOpen ? "#88c0d0" : "#d8dee9"
            isActive: weatherPopup.isOpen
            tooltipText: weatherPopup.isOpen ? "Close weather" : (weatherModule.weatherTooltip + "\nLeft-click: Weather details\nRight-click: Full report")
            paddingHorizontal: 3

            onClicked: weatherPopup.toggle()
            onRightClicked: root.runCmd("launch-weather-report")
        }
    }

    // 8. Calendar Popup
    CalendarPopup {
        id: calPopup
        bar: root.bar
        anchorTarget: clockBtn
    }

    // 8. Clock & Calendar Module
    Item {
        id: clockModule
        implicitWidth: clockBtn.implicitWidth
        implicitHeight: clockBtn.implicitHeight

        property bool showAltFormat: false
        property var dateObj: new Date()

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clockModule.dateObj = new Date()
        }

        function getClockText() {
            let d = dateObj;
            if (showAltFormat) {
                return Qt.formatDateTime(d, "dd MMMM yyyy");
            } else {
                return Qt.formatDateTime(d, "dddd HH:mm");
            }
        }

        IconButton {
            id: clockBtn
            text: clockModule.getClockText()
            color: calPopup.isOpen ? "#88c0d0" : "#d8dee9"
            isActive: calPopup.isOpen
            tooltipText: (calPopup.isOpen ? "Close calendar" : "Open calendar") + 
                "\nRight-click: Switch format (" + (clockModule.showAltFormat ? "Time" : "Date") + ")"
            paddingHorizontal: 5

            onClicked: calPopup.toggle()
            onRightClicked: clockModule.showAltFormat = !clockModule.showAltFormat
        }
    }
}

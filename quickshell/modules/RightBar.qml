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
                                        var pt = trayDelegate.mapToItem(null, mouse.x, mouse.y);
                                        trayDelegate.modelData.display(root.bar, pt.x, pt.y);
                                    } else {
                                        trayDelegate.modelData.secondaryActivate();
                                    }
                                } else if (mouse.button === Qt.MiddleButton) {
                                    trayDelegate.modelData.secondaryActivate();
                                } else {
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
            color: "#d8dee9"
            tooltipText: weatherModule.weatherTooltip
            paddingHorizontal: 3

            onClicked: weatherProc.running = true
            onRightClicked: root.runCmd("launch-weather-report")
        }
    }

    // 8. Clock Module
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
            color: "#d8dee9"
            tooltipText: clockModule.showAltFormat ? Qt.formatDateTime(clockModule.dateObj, "dddd HH:mm") : Qt.formatDateTime(clockModule.dateObj, "dd MMMM yyyy")
            paddingHorizontal: 5

            onClicked: clockModule.showAltFormat = !clockModule.showAltFormat
            onRightClicked: root.runCmd("launch-floating-terminal-with-presentation tz-select")
        }
    }
}

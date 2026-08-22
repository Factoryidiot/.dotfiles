import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import "../components"

RowLayout {
    id: root
    spacing: 8

    function runCmd(cmd) {
        cmdRunner.command = ["zsh", "-c", cmd];
        cmdRunner.running = true;
    }

    Process {
        id: cmdRunner
        command: []
        running: false
    }

    // 1. System Tray
    RowLayout {
        id: trayRow
        spacing: 4
        visible: SystemTray.items.values.length > 0

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
                    fillMode: Image.PreserveAspectFit
                }

                MouseArea {
                    id: trayMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            if (trayDelegate.modelData.hasMenu) {
                                trayDelegate.modelData.secondaryActivate();
                            } else {
                                trayDelegate.modelData.activate();
                            }
                        } else {
                            trayDelegate.modelData.activate();
                        }
                    }

                    ToolTip.visible: containsMouse && (trayDelegate.modelData.tooltip !== "" || trayDelegate.modelData.title !== "")
                    ToolTip.text: trayDelegate.modelData.tooltip !== "" ? trayDelegate.modelData.tooltip : trayDelegate.modelData.title
                    ToolTip.delay: 500
                    ToolTip.timeout: 4000
                }
            }
        }
    }

    // 2. CPU / Resource Monitor
    IconButton {
        iconText: "󰍛"
        color: "#d8dee9"
        tooltipText: "Resource Monitor (Click: btop)"
        paddingHorizontal: 3

        onClicked: root.runCmd("launch-or-focus-tui btop")
    }

    // 3. Bluetooth Module
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
                        btModule.btTooltip = "Bluetooth: Connected\nClick: Bluetooth Manager (bluetui)";
                    } else if (out === "on") {
                        btModule.btIcon = "";
                        btModule.btTooltip = "Bluetooth: Enabled\nClick: Bluetooth Manager (bluetui)";
                    } else {
                        btModule.btIcon = "󰂲";
                        btModule.btTooltip = "Bluetooth: Disabled\nClick: Bluetooth Manager (bluetui)";
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

    // 4. Network Module
    Item {
        id: netModule
        implicitWidth: netBtn.implicitWidth
        implicitHeight: netBtn.implicitHeight

        property string netIcon: "󰤨"
        property string netTooltip: "Network"

        Process {
            id: netProc
            command: ["zsh", "-c", "nmcli -t -f TYPE,STATE,SIGNAL,CONNECTION dev | grep ':connected' | head -1"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let out = this.text.trim();
                    if (out.startsWith("ethernet")) {
                        netModule.netIcon = "󰀂";
                        netModule.netTooltip = "Ethernet Connected\nClick: WiFi Manager (impala)";
                    } else if (out.startsWith("wifi")) {
                        let parts = out.split(":");
                        let sig = parseInt(parts[2]) || 70;
                        if (sig >= 80) netModule.netIcon = "󰤨";
                        else if (sig >= 60) netModule.netIcon = "󰤥";
                        else if (sig >= 40) netModule.netIcon = "󰤢";
                        else if (sig >= 20) netModule.netIcon = "󰤟";
                        else netModule.netIcon = "󰤯";
                        netModule.netTooltip = `WiFi: ${parts[3] || "Connected"} (${sig}%)\nClick: WiFi Manager (impala)`;
                    } else {
                        netModule.netIcon = "󰤮";
                        netModule.netTooltip = "Network Disconnected\nClick: WiFi Manager (impala)";
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

    // 5. Audio / Pipewire Module
    Item {
        id: audioModule
        implicitWidth: audioBtn.implicitWidth
        implicitHeight: audioBtn.implicitHeight

        readonly property var sink: Pipewire.defaultAudioSink
        readonly property bool isMuted: sink && sink.audio ? sink.audio.muted : false
        readonly property real volume: sink && sink.audio ? sink.audio.volume : 0.5
        readonly property int volumePercent: Math.round(volume * 100)

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
            tooltipText: `Volume: ${audioModule.volumePercent}%${audioModule.isMuted ? " (Muted)" : ""}\nClick: Audio Mixer (wiremix)\nScroll: Volume Up/Down\nRight-click: Mute Toggle`
            paddingHorizontal: 3

            onClicked: root.runCmd("launch-or-focus-tui wiremix")
            onRightClicked: {
                if (audioModule.sink && audioModule.sink.audio) {
                    audioModule.sink.audio.muted = !audioModule.sink.audio.muted;
                } else {
                    root.runCmd("pamixer -t");
                }
            }
            onScrollUp: {
                if (audioModule.sink && audioModule.sink.audio) {
                    audioModule.sink.audio.volume = Math.min(1.0, audioModule.sink.audio.volume + 0.05);
                } else {
                    root.runCmd("pamixer -i 5");
                }
            }
            onScrollDown: {
                if (audioModule.sink && audioModule.sink.audio) {
                    audioModule.sink.audio.volume = Math.max(0.0, audioModule.sink.audio.volume - 0.05);
                } else {
                    root.runCmd("pamixer -d 5");
                }
            }
        }
    }

    // 6. Battery Module
    Item {
        id: batModule
        implicitWidth: batBtn.implicitWidth
        implicitHeight: batBtn.implicitHeight

        property int capacity: 100
        property string status: "Discharging"

        Process {
            id: batProc
            command: ["zsh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    let lines = this.text.trim().split("\n");
                    if (lines.length >= 1 && lines[0] !== "") {
                        batModule.capacity = parseInt(lines[0]) || 100;
                    }
                    if (lines.length >= 2) {
                        batModule.status = lines[1].trim();
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
            let charging = status === "Charging" || status === "Full";
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

        IconButton {
            id: batBtn
            iconText: batModule.getBatIcon()
            color: batModule.capacity <= 15 ? "#bf616a" : (batModule.capacity <= 25 ? "#ebcb8b" : "#d8dee9")
            tooltipText: `Battery: ${batModule.capacity}% (${batModule.status})\nClick: Power Menu\nRight-click: Detailed Status`
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
            tooltipText: `${weatherModule.weatherTooltip}\nClick: Refresh | Right-click: Weather Report`
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
            tooltipText: "Left-click: Toggle Date Format\nRight-click: Timezone Select"
            paddingHorizontal: 5

            onClicked: clockModule.showAltFormat = !clockModule.showAltFormat
            onRightClicked: root.runCmd("launch-floating-terminal-with-presentation tz-select")
        }
    }
}

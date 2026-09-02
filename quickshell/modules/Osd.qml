import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: root

    property bool isShown: false
    property string osdType: "volume" // "volume", "mic", "brightness", "capslock", "media"
    property string iconGlyph: "󰕾"
    property string iconColor: "#88c0d0"
    property string titleText: "Volume"
    property string valueText: "50%"
    property real progressValue: 0.5
    property bool showProgress: true

    Timer {
        id: hideTimer
        interval: 1600
        repeat: false
        onTriggered: root.isShown = false
    }

    function triggerOsd(type, glyph, color, title, valStr, prog, hasProg) {
        root.osdType = type;
        root.iconGlyph = glyph;
        root.iconColor = color;
        root.titleText = title;
        root.valueText = valStr;
        root.progressValue = Math.max(0, Math.min(1, prog));
        root.showProgress = hasProg;
        root.isShown = true;
        hideTimer.restart();
    }

    // Process for executing volume adjustments and capturing results
    Process {
        id: volumeProc
        property string pendingDelta: ""
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text.trim().split("\n");
                let vol = parseInt(out[0]) || 0;
                let isMuted = out.length > 1 && out[1].trim() === "true";
                let glyph = isMuted ? "󰖁" : (vol > 60 ? "󰕾" : (vol > 20 ? "󰖀" : "󰕿"));
                let color = isMuted ? "#bf616a" : "#88c0d0";
                let valStr = isMuted ? "Muted" : (vol + "%");
                root.triggerOsd("volume", glyph, color, "Volume", valStr, vol / 100.0, !isMuted);
            }
        }
    }

    // Process for mute toggle
    Process {
        id: muteProc
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text.trim().split("\n");
                let vol = parseInt(out[0]) || 0;
                let isMuted = out.length > 1 && out[1].trim() === "true";
                let glyph = isMuted ? "󰖁" : (vol > 60 ? "󰕾" : (vol > 20 ? "󰖀" : "󰕿"));
                let color = isMuted ? "#bf616a" : "#88c0d0";
                let valStr = isMuted ? "Muted" : (vol + "%");
                root.triggerOsd("volume", glyph, color, "Volume", valStr, vol / 100.0, !isMuted);
            }
        }
    }

    // Process for mic mute toggle
    Process {
        id: micProc
        stdout: StdioCollector {
            onStreamFinished: {
                let isMuted = this.text.trim() === "true";
                let glyph = isMuted ? "󰍭" : "󰍬";
                let color = isMuted ? "#bf616a" : "#a3be8c";
                let valStr = isMuted ? "Muted" : "Active";
                root.triggerOsd("mic", glyph, color, "Microphone", valStr, isMuted ? 0 : 1, false);
            }
        }
    }

    // Process for brightness adjustment
    Process {
        id: brightnessProc
        stdout: StdioCollector {
            onStreamFinished: {
                let out = this.text.trim().replace("%", "");
                let pct = parseInt(out) || 0;
                let glyph = pct > 66 ? "󰃠" : (pct > 33 ? "󰃟" : "󰃞");
                root.triggerOsd("brightness", glyph, "#ebcb8b", "Brightness", pct + "%", pct / 100.0, true);
            }
        }
    }

    // Process for caps lock check
    Process {
        id: capsProc
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                let isOn = raw.includes("1");
                let glyph = "󰌌";
                let color = isOn ? "#88c0d0" : "#4c566a";
                let valStr = isOn ? "ON" : "OFF";
                root.triggerOsd("capslock", glyph, color, "Caps Lock", valStr, isOn ? 1 : 0, false);
            }
        }
    }

    IpcHandler {
        target: "osd"

        function volume(delta: string): void {
            let cmd = "";
            if (delta.startsWith("+")) {
                let val = delta.substring(1);
                cmd = "pamixer --allow-boost -u -i " + val + " && pamixer --get-volume && pamixer --get-mute";
            } else if (delta.startsWith("-")) {
                let val = delta.substring(1);
                cmd = "pamixer --allow-boost -u -d " + val + " && pamixer --get-volume && pamixer --get-mute";
            } else {
                cmd = "pamixer --get-volume && pamixer --get-mute";
            }
            volumeProc.command = ["zsh", "-c", cmd];
            volumeProc.running = true;
        }

        function volumeMute(): void {
            let cmd = "pamixer -t && pamixer --get-volume && pamixer --get-mute";
            muteProc.command = ["zsh", "-c", cmd];
            muteProc.running = true;
        }

        function micMute(): void {
            let cmd = "pamixer --default-source -t && pamixer --default-source --get-mute";
            micProc.command = ["zsh", "-c", cmd];
            micProc.running = true;
        }

        function brightness(delta: string): void {
            let cmd = "";
            if (delta.startsWith("+")) {
                let val = delta.substring(1);
                cmd = "brightnessctl set " + val + "%+ >/dev/null && brightnessctl -m | cut -d, -f4";
            } else if (delta.startsWith("-")) {
                let val = delta.substring(1);
                cmd = "brightnessctl set " + val + "%- >/dev/null && brightnessctl -m | cut -d, -f4";
            } else {
                cmd = "brightnessctl -m | cut -d, -f4";
            }
            brightnessProc.command = ["zsh", "-c", cmd];
            brightnessProc.running = true;
        }

        function capslock(): void {
            // Check sysfs LED state with brief 40ms delay for kernel debounce
            let cmd = "sleep 0.04; grep -h . /sys/class/leds/*capslock*/brightness 2>/dev/null";
            capsProc.command = ["zsh", "-c", cmd];
            capsProc.running = true;
        }

        function media(action: string): void {
            Quickshell.execDetached(["zsh", "-c", "playerctl " + action]);
            let glyph = action === "play-pause" ? "󰐊" : (action === "next" ? "󰒭" : "󰒮");
            let title = action === "play-pause" ? "Play / Pause" : (action === "next" ? "Next Track" : "Previous Track");
            root.triggerOsd("media", glyph, "#81a1c1", "Media", title, 1, false);
        }
    }

    // Render OSD window on all connected displays
    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: osdWindow
                required property var modelData
                screen: modelData

                anchors {
                    bottom: true
                }
                margins {
                    bottom: 64
                }

                implicitWidth: 280
                implicitHeight: 52
                color: "transparent"

                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-osd"

                visible: root.isShown

                // SwayOSD-style pill card
                Rectangle {
                    anchors.fill: parent
                    color: "#2e3440"
                    border.color: "#d8dee9"
                    border.width: 1
                    radius: 6

                    opacity: root.isShown ? 1.0 : 0.0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                            easing.type: Easing.OutQuad
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.topMargin: 10
                        anchors.bottomMargin: 10
                        spacing: 12

                        // Icon
                        Text {
                            text: root.iconGlyph
                            color: root.iconColor
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            Layout.alignment: Qt.AlignVCenter
                        }

                        // Details & Progress
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4

                            // Title & Value text row
                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: root.titleText
                                    color: "#d8dee9"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: root.valueText
                                    color: root.iconColor
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }

                            // Progress Bar (if applicable)
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: 3
                                color: "#3b4252"
                                visible: root.showProgress

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.max(0, Math.min(parent.width, parent.width * root.progressValue))
                                    radius: 3
                                    color: root.iconColor

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 100
                                            easing.type: Easing.OutQuad
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
}

//@ pragma UseQApplication
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./modules"

ShellRoot {
    id: root

    // Central Application & Actions Launcher Menu
    Menu {
        id: appMenu
    }

    // Native Clipboard History Modal
    Clipboard {
        id: clipboardHistory
    }

    // Native On-Screen Display (OSD)
    Osd {
        id: osdOverlay
    }

    // Native Desktop & System Notifications Server
    Notifications {
        id: notifications
    }

    Variants {
        // Target internal laptop display (eDP), falling back to first screen if running standalone
        model: {
            let internal = Quickshell.screens.filter(s => s && s.name && s.name.startsWith("eDP"));
            return internal.length > 0 ? internal : (Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []);
        }

        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData

                property string tooltipText: ""
                property var tooltipTarget: null
                property bool tooltipShown: false

                Timer {
                    id: tooltipTimer
                    interval: 300
                    onTriggered: {
                        if (barWindow.tooltipTarget && barWindow.tooltipText !== "") {
                            barWindow.tooltipShown = true;
                        }
                    }
                }

                function showTooltip(target, text) {
                    if (!text || text === "") return;
                    barWindow.tooltipText = text;
                    barWindow.tooltipTarget = target;
                    tooltipTimer.restart();
                }

                function hideTooltip(target) {
                    if (barWindow.tooltipTarget === target) {
                        tooltipTimer.stop();
                        barWindow.tooltipShown = false;
                        barWindow.tooltipTarget = null;
                        barWindow.tooltipText = "";
                    }
                }

                // Anchors for a full top bar
                anchors {
                    top: true
                    left: true
                    right: true
                }

                implicitHeight: 26
                color: "transparent"

                WlrLayershell.layer: WlrLayer.Top
                WlrLayershell.namespace: "quickshell-bar"

                Rectangle {
                    id: barBackground
                    anchors.fill: parent
                    color: "#2e3440"

                    // Subtle separator line at bottom of bar
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: "#3b4252"
                    }

                    // Left Section (Menu)
                    LeftBar {
                        id: leftModules
                        bar: barWindow
                        menu: appMenu
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Center Section (Hyprland Workspaces)
                    CenterBar {
                        id: centerModules
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    // Right Section (Tray, CPU, Bluetooth, Network, Audio, Battery, Weather, Clock)
                    RightBar {
                        id: rightModules
                        bar: barWindow
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                PopupWindow {
                    id: tooltipWindow
                    visible: barWindow.tooltipShown && barWindow.tooltipTarget !== null && barWindow.tooltipText !== ""
                    color: "transparent"
                    implicitWidth: Math.ceil(tooltipBubble.implicitWidth)
                    implicitHeight: Math.ceil(tooltipBubble.implicitHeight)

                    anchor {
                        id: tooltipAnchor
                        window: barWindow
                        adjustment: PopupAdjustment.Slide
                        edges: Edges.Top | Edges.Left
                        gravity: Edges.Bottom | Edges.Right
                        rect.width: 1
                        rect.height: 1

                        onAnchoring: {
                            var target = barWindow.tooltipTarget;
                            if (!target) return;
                            var popupWidth = tooltipWindow.implicitWidth;
                            var localX = (target.width / 2) - (popupWidth / 2);
                            var localY = target.height + 6;
                            var point = barWindow.contentItem.mapFromItem(target, localX, localY);
                            tooltipAnchor.rect.x = Math.round(point.x);
                            tooltipAnchor.rect.y = Math.round(point.y);
                        }
                    }

                    Rectangle {
                        id: tooltipBubble
                        implicitWidth: tooltipLabel.implicitWidth + 16
                        implicitHeight: tooltipLabel.implicitHeight + 10
                        color: "#2e3440"
                        border.color: "#4c566a"
                        border.width: 1
                        radius: 4

                        Text {
                            id: tooltipLabel
                            anchors.centerIn: parent
                            text: barWindow.tooltipText
                            color: "#d8dee9"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            lineHeight: 1.15
                        }
                    }
                }
            }
        }
    }
}

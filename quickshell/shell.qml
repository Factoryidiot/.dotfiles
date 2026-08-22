import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "./modules"

ShellRoot {
    id: root

    Variants {
        model: Quickshell.screens

        delegate: Component {
            PanelWindow {
                id: barWindow
                required property var modelData
                screen: modelData

                property string tooltipText: ""
                property var tooltipTarget: null
                property bool tooltipVisible: false

                Timer {
                    id: tooltipDelayTimer
                    interval: 300
                    onTriggered: {
                        if (barWindow.tooltipTarget && barWindow.tooltipText !== "") {
                            barWindow.tooltipVisible = true;
                        }
                    }
                }

                function showTooltip(target, text) {
                    if (!text || text === "") return;
                    barWindow.tooltipText = text;
                    barWindow.tooltipTarget = target;
                    tooltipDelayTimer.restart();
                }

                function hideTooltip(target) {
                    if (barWindow.tooltipTarget === target) {
                        tooltipDelayTimer.stop();
                        barWindow.tooltipVisible = false;
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

                    // Left Section (Menu, Idle Inhibitor)
                    LeftBar {
                        id: leftModules
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
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                PopupWindow {
                    id: tooltipPopup
                    visible: barWindow.tooltipVisible && barWindow.tooltipTarget !== null && barWindow.tooltipText !== ""
                    color: "transparent"
                    implicitWidth: Math.ceil(tooltipBox.implicitWidth)
                    implicitHeight: Math.ceil(tooltipBox.implicitHeight)

                    anchor {
                        window: barWindow
                        adjustment: PopupAdjustment.Slide
                        edges: Edges.Top | Edges.Left
                        gravity: Edges.Bottom | Edges.Right
                        rect.width: 1
                        rect.height: 1

                        onAnchoring: {
                            if (!barWindow.tooltipTarget) return;
                            var target = barWindow.tooltipTarget;
                            var popupWidth = tooltipPopup.implicitWidth;
                            var localX = (target.width / 2) - (popupWidth / 2);
                            var localY = target.height + 6;
                            var point = barWindow.contentItem.mapFromItem(target, localX, localY);
                            anchor.rect.x = Math.round(point.x);
                            anchor.rect.y = Math.round(point.y);
                        }
                    }

                    Rectangle {
                        id: tooltipBox
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

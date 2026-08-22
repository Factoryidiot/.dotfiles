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

                // Anchors for a full top bar
                anchors {
                    top: true
                    left: true
                    right: true
                }

                // Resolves the deprecated 'height' warning by using implicitHeight
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
            }
        }
    }
}

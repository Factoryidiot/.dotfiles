import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

Scope {
    id: root

    // ListModel of active on-screen notification toasts
    ListModel {
        id: toastModel
    }

    property var notifRefs: ({})

    NotificationServer {
        id: server
        imageSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true

        onNotification: notification => {
            var id = String(notification.id || Date.now());
            root.notifRefs[id] = notification;

            var duration = 5000;
            if (notification.urgency === NotificationUrgency.Critical) {
                duration = 0; // Critical stays on screen until dismissed
            } else if (notification.urgency === NotificationUrgency.Low) {
                duration = 3500;
            } else if (notification.expireTimeout > 0) {
                duration = notification.expireTimeout;
            }

            // Remove any existing toast with same id
            for (var i = 0; i < toastModel.count; i++) {
                if (toastModel.get(i).toastId === id) {
                    toastModel.remove(i);
                    break;
                }
            }

            toastModel.insert(0, {
                toastId: id,
                summary: notification.summary || "",
                body: notification.body || "",
                appName: notification.appName || "Notification",
                appIcon: notification.appIcon || "",
                urgency: notification.urgency || 1,
                duration: duration
            });
        }
    }

    function dismissToast(toastId) {
        var ref = root.notifRefs[toastId];
        if (ref) {
            try { ref.dismiss(); } catch (e) {}
            delete root.notifRefs[toastId];
        }
        for (var i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).toastId === toastId) {
                toastModel.remove(i);
                break;
            }
        }
    }

    // Top-Right Floating Toast Stack
    Variants {
        model: {
            let internal = Quickshell.screens.filter(s => s && s.name && s.name.startsWith("eDP"));
            return internal.length > 0 ? internal : (Quickshell.screens.length > 0 ? [Quickshell.screens[0]] : []);
        }

        delegate: Component {
            PanelWindow {
                id: toastWindow
                required property var modelData
                screen: modelData

                visible: toastModel.count > 0
                color: "transparent"

                WlrLayershell.namespace: "quickshell-notifications"
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                exclusionMode: ExclusionMode.Ignore

                anchors {
                    top: true
                    right: true
                }

                margins {
                    top: 32
                    right: 12
                }

                implicitWidth: 340
                implicitHeight: toastColumn.implicitHeight

                ColumnLayout {
                    id: toastColumn
                    width: 340
                    spacing: 8

                    Repeater {
                        model: toastModel
                        delegate: Rectangle {
                            id: card
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            implicitHeight: cardContent.implicitHeight + 16
                            radius: 6
                            color: "#2e3440"
                            border.color: modelData.urgency === NotificationUrgency.Critical ? "#bf616a" : "#d8dee9"
                            border.width: 1

                            Timer {
                                interval: modelData.duration
                                running: modelData.duration > 0
                                repeat: false
                                onTriggered: root.dismissToast(modelData.toastId)
                            }

                            ColumnLayout {
                                id: cardContent
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 4

                                // Header: App Icon, App Name, Close Button
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Item {
                                        Layout.preferredWidth: 14
                                        Layout.preferredHeight: 14
                                        Layout.alignment: Qt.AlignVCenter

                                        Image {
                                            anchors.fill: parent
                                            source: modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
                                            sourceSize: Qt.size(14, 14)
                                            fillMode: Image.PreserveAspectFit
                                            visible: source.toString() !== ""
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰂚"
                                            color: "#88c0d0"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 12
                                            visible: !modelData.appIcon || modelData.appIcon === ""
                                        }
                                    }

                                    Text {
                                        text: modelData.appName
                                        color: "#81a1c1"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        font.bold: true
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        Layout.alignment: Qt.AlignVCenter
                                    }

                                    Text {
                                        text: "✕"
                                        color: closeMouseArea.containsMouse ? "#bf616a" : "#d8dee9"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        opacity: closeMouseArea.containsMouse ? 1.0 : 0.6
                                        Layout.alignment: Qt.AlignVCenter

                                        MouseArea {
                                            id: closeMouseArea
                                            anchors.fill: parent
                                            anchors.margins: -4
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.dismissToast(modelData.toastId)
                                        }
                                    }
                                }

                                // Title / Summary
                                Text {
                                    text: modelData.summary
                                    color: "#eceff4"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    font.bold: true
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    visible: modelData.summary !== ""
                                }

                                // Body
                                Text {
                                    text: modelData.body
                                    color: "#d8dee9"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    wrapMode: Text.Wrap
                                    maximumLineCount: 4
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    visible: modelData.body !== ""
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.dismissToast(modelData.toastId)
                            }
                        }
                    }
                }
            }
        }
    }
}

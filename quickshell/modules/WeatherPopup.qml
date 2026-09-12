import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../components"

PopupWindow {
    id: root

    property var bar: null
    property var anchorTarget: null
    property bool isOpen: false

    property var weatherData: null
    property string currentIcon: ""
    property string currentTemp: "--"
    property string currentDesc: "Loading weather..."
    property string currentLocation: "Wellington"
    property string feelsLike: "--"
    property string humidity: "--"
    property string windSpeed: "--"
    property string sunrise: "--"
    property string sunset: "--"
    property var forecastDays: []

    // Explicit window dimensions for Wayland surface
    implicitWidth: 380
    implicitHeight: container.implicitHeight

    function toggle() {
        if (root.isOpen) {
            root.close();
        } else {
            root.open();
        }
    }

    function open() {
        if (!root.weatherData) {
            weatherFetchProc.running = true;
        }
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }

    function getIconForCode(code) {
        let c = parseInt(code) || 119;
        switch (c) {
            case 113: return "";
            case 116: return "";
            case 119:
            case 122: return "";
            case 143:
            case 248:
            case 260: return "";
            case 176:
            case 263:
            case 353: return "";
            case 179:
            case 227:
            case 230:
            case 323:
            case 326:
            case 368: return "";
            case 200:
            case 386:
            case 389:
            case 392:
            case 395: return "";
            case 266:
            case 293:
            case 296:
            case 299:
            case 302:
            case 305:
            case 308:
            case 356:
            case 359: return "";
            case 329:
            case 332:
            case 335:
            case 338:
            case 371: return "";
            default: return "";
        }
    }

    function getDayName(dateStr) {
        if (!dateStr) return "";
        let parts = dateStr.split("-");
        if (parts.length < 3) return dateStr;
        let d = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
        let days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        return days[d.getDay()] || dateStr;
    }

    Process {
        id: weatherFetchProc
        command: ["zsh", "-c", `
            loc=$(jq -r '.default // "Wellington"' ~/.dotfiles/weather/locations.json 2>/dev/null)
            curl -fsS --max-time 6 "https://wttr.in/\${loc:-Wellington}?format=j1" 2>/dev/null
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    root.weatherData = data;

                    if (data.current_condition && data.current_condition.length > 0) {
                        let cur = data.current_condition[0];
                        root.currentTemp = cur.temp_C || "--";
                        root.feelsLike = cur.FeelsLikeC || cur.temp_C || "--";
                        root.humidity = (cur.humidity || "--") + "%";
                        root.windSpeed = (cur.windspeedKmph || "--") + " km/h";
                        root.currentDesc = (cur.weatherDesc && cur.weatherDesc[0]) ? cur.weatherDesc[0].value : "";
                        root.currentIcon = root.getIconForCode(cur.weatherCode);
                    }

                    if (data.nearest_area && data.nearest_area.length > 0) {
                        let area = data.nearest_area[0];
                        let name = (area.areaName && area.areaName[0]) ? area.areaName[0].value : "Wellington";
                        let country = (area.country && area.country[0]) ? area.country[0].value : "";
                        root.currentLocation = country ? `${name}, ${country}` : name;
                    }

                    if (data.weather && data.weather.length > 0) {
                        let astro = data.weather[0].astronomy ? data.weather[0].astronomy[0] : null;
                        if (astro) {
                            root.sunrise = astro.sunrise || "--";
                            root.sunset = astro.sunset || "--";
                        }

                        let days = [];
                        for (let i = 0; i < data.weather.length && i < 3; i++) {
                            let day = data.weather[i];
                            let noon = (day.hourly && day.hourly.length > 4) ? day.hourly[4] : (day.hourly ? day.hourly[0] : null);
                            let code = noon ? noon.weatherCode : "119";
                            let desc = (noon && noon.weatherDesc && noon.weatherDesc[0]) ? noon.weatherDesc[0].value : "";
                            days.push({
                                name: i === 0 ? "Today" : root.getDayName(day.date),
                                date: day.date,
                                max: day.maxtempC || "--",
                                min: day.mintempC || "--",
                                icon: root.getIconForCode(code),
                                desc: desc
                            });
                        }
                        root.forecastDays = days;
                    }
                } catch (e) {
                    // Fallback on error
                }
            }
        }
    }

    Timer {
        interval: 900000 // 15 minutes
        running: true
        repeat: true
        onTriggered: weatherFetchProc.running = true
    }

    anchor {
        id: popupAnchor
        window: root.bar
        adjustment: PopupAdjustment.Slide
        edges: Edges.Top | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        rect.width: 1
        rect.height: 1

        onAnchoring: {
            var target = root.anchorTarget;
            if (!target || !root.bar) return;
            var popupW = root.implicitWidth;
            var point = root.bar.contentItem.mapFromItem(target, 0, 0);
            var posX = Math.round(point.x + target.width - popupW);
            var posY = Math.round(root.bar.height + 6);
            popupAnchor.rect.x = Math.max(10, posX);
            popupAnchor.rect.y = posY;
        }
    }

    visible: root.isOpen
    color: "transparent"

    Rectangle {
        id: container
        width: 380
        implicitHeight: mainLayout.implicitHeight + 24
        color: "#2e3440"
        border.color: "#d8dee9"
        border.width: 1
        radius: 0
        clip: true

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // 1. Hero Condition Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Big Weather Glyph
                Text {
                    text: root.currentIcon
                    color: "#88c0d0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 42
                }

                // Temp & Condition
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    RowLayout {
                        spacing: 4
                        Text {
                            text: `${root.currentTemp}°C`
                            color: "#eceff4"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            font.bold: true
                        }
                        Text {
                            text: `(Feels ${root.feelsLike}°C)`
                            color: "#d8dee9"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        text: root.currentDesc
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: root.currentLocation
                        color: "#d8dee9"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }
            }

            // Divider in SwayOSD border color
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#d8dee9"
                opacity: 0.35
            }

            // 2. Weather Details Grid (Wind, Humidity, Sunrise, Sunset)
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 16
                rowSpacing: 6

                // Wind
                RowLayout {
                    spacing: 6
                    Text { text: "󰖝"; color: "#81a1c1"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                    Text { text: `Wind: ${root.windSpeed}`; color: "#d8dee9"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                }

                // Humidity
                RowLayout {
                    spacing: 6
                    Text { text: "󰖌"; color: "#81a1c1"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                    Text { text: `Humidity: ${root.humidity}`; color: "#d8dee9"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                }

                // Sunrise
                RowLayout {
                    spacing: 6
                    Text { text: "󰖜"; color: "#ebcb8b"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                    Text { text: `Sunrise: ${root.sunrise}`; color: "#d8dee9"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                }

                // Sunset
                RowLayout {
                    spacing: 6
                    Text { text: "󰖛"; color: "#d08770"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                    Text { text: `Sunset: ${root.sunset}`; color: "#d8dee9"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                }
            }

            // Divider in SwayOSD border color
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#d8dee9"
                opacity: 0.35
            }

            // 3. 3-Day Forecast Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.forecastDays

                    delegate: Rectangle {
                        id: forecastCard
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        implicitHeight: 70
                        radius: 0
                        color: fMouse.containsMouse ? "#434c5e" : "#3b4252"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 2

                            Text {
                                text: forecastCard.modelData.name
                                color: "#eceff4"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: forecastCard.modelData.icon
                                color: "#88c0d0"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: `${forecastCard.modelData.max}° / ${forecastCard.modelData.min}°`
                                color: "#d8dee9"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: fMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }
            }

            // Divider in SwayOSD border color
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#d8dee9"
                opacity: 0.35
            }

            // 4. Footer Actions (Refresh & Full Report)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Refresh Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 0
                    color: refMouse.containsMouse ? "#434c5e" : "#3b4252"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰑐"
                            color: "#88c0d0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }

                        Text {
                            text: "Refresh"
                            color: "#d8dee9"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: refMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: weatherFetchProc.running = true
                    }
                }

                // Web Report Button
                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 0
                    color: webMouse.containsMouse ? "#434c5e" : "#3b4252"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰖔"
                            color: "#88c0d0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }

                        Text {
                            text: "Full Report"
                            color: "#d8dee9"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: webMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["zsh", "-c", "launch-weather-report"]);
                            root.close();
                        }
                    }
                }
            }
        }
    }
}

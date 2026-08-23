import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../components"

PopupWindow {
    id: root

    property var bar: null
    property var anchorTarget: null
    property bool isOpen: false

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()

    readonly property bool viewingCurrentMonth: viewYear === today.getFullYear() && viewMonth === today.getMonth()

    // Explicit dimensions on the window so Wayland allocates full surface bounds
    implicitWidth: 380
    implicitHeight: container.implicitHeight

    Timer {
        interval: 1000
        running: root.isOpen
        repeat: true
        onTriggered: root.today = new Date()
    }

    function toggle() {
        if (root.isOpen) {
            root.close();
        } else {
            root.open();
        }
    }

    function open() {
        root.goToToday();
        root.isOpen = true;
    }

    function close() {
        root.isOpen = false;
    }

    function pad2(n) {
        return (n < 10 ? "0" : "") + n;
    }

    function keyFor(y, m, d) {
        return y + "-" + pad2(m + 1) + "-" + pad2(d);
    }

    function getTodayKey() {
        return keyFor(today.getFullYear(), today.getMonth(), today.getDate());
    }

    function isLeapYear(year) {
        return ((year % 4 === 0) && (year % 100 !== 0)) || (year % 400 === 0);
    }

    function getYearProgress() {
        let start = new Date(today.getFullYear(), 0, 1);
        let diff = today - start;
        let totalDays = isLeapYear(today.getFullYear()) ? 366 : 365;
        let totalMs = totalDays * 86400000;
        return Math.min(100, Math.max(0, Math.round((diff / totalMs) * 100)));
    }

    function prevMonth() {
        let d = new Date(viewYear, viewMonth - 1, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    function nextMonth() {
        let d = new Date(viewYear, viewMonth + 1, 1);
        viewYear = d.getFullYear();
        viewMonth = d.getMonth();
    }

    function goToToday() {
        today = new Date();
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }

    function getMonthName(monthIndex) {
        const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        return months[monthIndex] || "";
    }

    function getMonthGrid(year, month) {
        let startDay = (new Date(year, month, 1).getDay() + 6) % 7; // Monday = 0
        let cursor = new Date(year, month, 1 - startDay);
        let todayKey = getTodayKey();
        let grid = [];

        for (let w = 0; w < 6; w++) {
            let days = [];
            let thursday = null;

            for (let d = 0; d < 7; d++) {
                let cy = cursor.getFullYear();
                let cm = cursor.getMonth();
                let cd = cursor.getDate();
                let wd = cursor.getDay();
                let key = keyFor(cy, cm, cd);

                if (wd === 4) {
                    thursday = new Date(cy, cm, cd);
                }

                days.push({
                    day: cd,
                    month: cm,
                    year: cy,
                    inMonth: (cm === month && cy === year),
                    today: (key === todayKey),
                    isWeekend: (wd === 0 || wd === 6)
                });

                cursor.setDate(cursor.getDate() + 1);
            }

            let thurs = thursday || new Date(days[0].year, days[0].month, days[0].day);
            let dUtc = new Date(Date.UTC(thurs.getFullYear(), thurs.getMonth(), thurs.getDate()));
            let dayNum = dUtc.getUTCDay() || 7;
            dUtc.setUTCDate(dUtc.getUTCDate() + 4 - dayNum);
            let yearStart = new Date(Date.UTC(dUtc.getUTCFullYear(), 0, 1));
            let weekNo = Math.ceil((((dUtc - yearStart) / 86400000) + 1) / 7);

            grid.push({
                week: weekNo,
                days: days
            });
        }
        return grid;
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
            // Align right edge of popup with right edge of target, with screen padding
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
        radius: 6
        clip: true

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // 1. Hero Header Section
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "󰃭"
                    color: "#88c0d0"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 34
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: Qt.formatDate(root.today, "dddd, MMMM d")
                        color: "#eceff4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    Text {
                        text: Qt.formatDateTime(root.today, "HH:mm:ss")
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 17
                        font.bold: true
                    }
                }

                // Year Progress Badge
                ColumnLayout {
                    spacing: 3
                    Layout.alignment: Qt.AlignRight

                    Text {
                        text: `Year: ${root.getYearProgress()}%`
                        color: "#d8dee9"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignRight
                    }

                    Rectangle {
                        width: 76
                        height: 6
                        radius: 3
                        color: "#3b4252"

                        Rectangle {
                            width: Math.round(parent.width * (root.getYearProgress() / 100))
                            height: parent.height
                            radius: 3
                            color: "#81a1c1"
                        }
                    }
                }
            }

            // Divider Line in SwayOSD border color
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#d8dee9"
                opacity: 0.35
            }

            // 2. Month Navigation Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Prev Month Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 4
                    color: prevMouse.containsMouse ? "#434c5e" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "‹"
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        id: prevMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.prevMonth()
                    }
                }

                // Month & Year Label (clickable to reset to today)
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 26

                    Text {
                        anchors.centerIn: parent
                        text: `${root.getMonthName(root.viewMonth)} ${root.viewYear}`
                        color: monthMouse.containsMouse ? "#88c0d0" : "#eceff4"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        id: monthMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goToToday()
                    }
                }

                // Next Month Button
                Rectangle {
                    width: 26
                    height: 26
                    radius: 4
                    color: nextMouse.containsMouse ? "#434c5e" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "›"
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    MouseArea {
                        id: nextMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.nextMonth()
                    }
                }
            }

            // 3. Calendar Grid (Headers + 6 Weeks)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                // Day of Week Header Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    // Week number header
                    Text {
                        width: 26
                        text: "W"
                        color: "#81a1c1"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Repeater {
                        model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                        delegate: Text {
                            Layout.fillWidth: true
                            text: modelData
                            color: (index >= 5) ? "#81a1c1" : "#d8dee9"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }

                // 6 Weeks of Days
                Repeater {
                    model: root.getMonthGrid(root.viewYear, root.viewMonth)

                    delegate: RowLayout {
                        id: weekRow
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 2

                        // Week Number
                        Text {
                            width: 26
                            text: weekRow.modelData.week.toString()
                            color: "#4c566a"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignHCenter
                        }

                        // 7 Days in Week
                        Repeater {
                            model: weekRow.modelData.days

                            delegate: Item {
                                id: dayCell
                                required property var modelData
                                Layout.fillWidth: true
                                implicitHeight: 26

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 28
                                    height: 24
                                    radius: 4
                                    color: dayCell.modelData.today ? "#88c0d0" : (dayMouse.containsMouse ? "#434c5e" : "transparent")
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: dayCell.modelData.day.toString()
                                    color: {
                                        if (dayCell.modelData.today) return "#2e3440";
                                        if (!dayCell.modelData.inMonth) return "#4c566a";
                                        if (dayCell.modelData.isWeekend) return "#81a1c1";
                                        return "#d8dee9";
                                    }
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: dayCell.modelData.today
                                }

                                MouseArea {
                                    id: dayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (!dayCell.modelData.inMonth) {
                                            root.viewYear = dayCell.modelData.year;
                                            root.viewMonth = dayCell.modelData.month;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Divider Line in SwayOSD border color
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#d8dee9"
                opacity: 0.35
            }

            // 4. Footer Section (Today Jump + Timezone Button)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    visible: !root.viewingCurrentMonth
                    Layout.fillWidth: true
                    height: 26
                    radius: 4
                    color: todayJumpMouse.containsMouse ? "#434c5e" : "#3b4252"

                    Text {
                        anchors.centerIn: parent
                        text: "Jump to Today"
                        color: "#88c0d0"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }

                    MouseArea {
                        id: todayJumpMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.goToToday()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 26
                    radius: 4
                    color: tzMouse.containsMouse ? "#434c5e" : "#3b4252"

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󱑒"
                            color: "#88c0d0"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }

                        Text {
                            text: "Timezones"
                            color: "#d8dee9"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: tzMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["zsh", "-c", "launch-floating-terminal-with-presentation tz-select"]);
                            root.close();
                        }
                    }
                }
            }
        }
    }
}

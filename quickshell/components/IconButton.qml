import QtQuick

Item {
    id: root

    property var bar: null
    property string text: ""
    property string iconText: ""
    property color color: "#d8dee9"
    property color hoverColor: "#434c5e"
    property color activeColor: "#81a1c1"
    property string tooltipText: ""
    property int spacing: 4
    property int paddingHorizontal: 6
    property int paddingVertical: 2
    property bool isActive: false
    property bool hasBackground: false

    signal clicked()
    signal rightClicked()
    signal scrollUp()
    signal scrollDown()

    function getBar() {
        if (root.bar) return root.bar;
        var p = root.parent;
        while (p) {
            if (p.bar) return p.bar;
            if (p.showTooltip) return p;
            p = p.parent;
        }
        return null;
    }

    implicitWidth: contentRow.implicitWidth + (paddingHorizontal * 2)
    implicitHeight: 24

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 3
        color: root.isActive ? root.activeColor : (mouseArea.containsMouse ? root.hoverColor : "transparent")
        opacity: root.isActive ? 0.25 : (mouseArea.containsMouse ? 0.4 : 0.0)
        visible: root.hasBackground || mouseArea.containsMouse || root.isActive

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.spacing

        Text {
            id: iconLabel
            text: root.iconText
            color: root.isActive ? root.activeColor : root.color
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            visible: root.iconText !== ""
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: textLabel
            text: root.text
            color: root.isActive ? root.activeColor : root.color
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            visible: root.text !== ""
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            var b = root.getBar();
            if (b && root.tooltipText !== "") {
                b.showTooltip(root, root.tooltipText);
            }
        }

        onExited: {
            var b = root.getBar();
            if (b) {
                b.hideTooltip(root);
            }
        }

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.rightClicked();
            } else {
                root.clicked();
            }
        }

        onWheel: wheel => {
            if (wheel.angleDelta.y > 0) {
                root.scrollUp();
            } else if (wheel.angleDelta.y < 0) {
                root.scrollDown();
            }
        }
    }
}

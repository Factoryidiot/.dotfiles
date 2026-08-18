import QtQuick

QtObject {
    id: theme

    // Nord & Omarchy Color Palette
    readonly property color bg: "#2e3440"
    readonly property color bgAlt: "#3b4252"
    readonly property color bgHover: "#434c5e"
    readonly property color border: "#4c566a"
    readonly property color fg: "#d8dee9"
    readonly property color fgDim: "#7e8eab"
    readonly property color fgMuted: "#616e88"
    
    // Accents
    readonly property color frost0: "#8fbcbb"
    readonly property color frost1: "#88c0d0"
    readonly property color frost2: "#81a1c1"
    readonly property color frost3: "#5e81ac"
    
    // Status
    readonly property color red: "#bf616a"
    readonly property color orange: "#d08770"
    readonly property color yellow: "#ebcb8b"
    readonly property color green: "#a3be8c"
    readonly property color purple: "#b48ead"

    // Sizing and Typography
    readonly property string fontFamily: "CaskaydiaMono Nerd Font"
    readonly property int fontSize: 12
    readonly property int fontSizeSmall: 10
    readonly property int barHeight: 26
    readonly property int iconSize: 14
}

pragma Singleton

import QtQuick

// Mirrors .chezmoidata/palette.yml. Deliberately not templated: these run out
// of /usr, before and outside any user session, so chezmoi never sees them.
// Keep the two in step by hand.
QtObject {
    readonly property color canvas: "#dcdcdd"
    readonly property color surface: "#ebebec"
    readonly property color panel: "#ebebec"
    readonly property color elevated: "#fafafa"
    readonly property color hover: "#dfdfe0"
    readonly property color active: "#cacaca"

    readonly property color fg: "#242529"
    readonly property color muted: "#58585a"
    readonly property color placeholder: "#7e8086"

    readonly property color accent: "#5c78e2"
    readonly property color border: "#c9c9ca"
    readonly property color focused: "#7d82e8"
    readonly property color error: "#d36151"
    readonly property color warning: "#a48819"
    readonly property color success: "#669f59"

    readonly property string fontFamily: "IBM Plex Sans"
    readonly property string monoFamily: "Lilex Nerd Font Mono"

    readonly property int barHeight: 24
    readonly property int radius: 10
    readonly property int radiusSmall: 6
    readonly property int pad: 12
    readonly property int padSmall: 6
    readonly property int fontSmall: 11
    readonly property int fontBase: 13
}

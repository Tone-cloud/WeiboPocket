import QtQuick 2.12
import WeiboPlugin 1.0

Rectangle {
    id: iconButton
    width: 32
    height: 32
    radius: Theme.smallRadius
    color: pressed ? Theme.bgPressed : (hovered ? Theme.bgHover : "transparent")

    property string icon: ""
    property string text: ""
    property color iconColor: Theme.textPrimary
    signal clicked()

    property bool hovered: false
    property bool pressed: false

    Text {
        anchors.centerIn: parent
        text: iconButton.icon !== "" ? iconButton.icon : iconButton.text
        font.pixelSize: iconButton.icon !== "" ? 16 : Theme.fontSizeSmall
        color: iconButton.iconColor
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: iconButton.hovered = true
        onExited: iconButton.hovered = false
        onPressed: iconButton.pressed = true
        onReleased: iconButton.pressed = false
        onClicked: iconButton.clicked()
    }
}

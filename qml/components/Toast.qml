import QtQuick 2.12
import ".."

Rectangle {
    id: toast
    width: Math.min(200, toastText.implicitWidth + 20)
    height: 26
    radius: Theme.radiusMedium
    color: "#E6000000"
    visible: false
    z: 999

    property string text: ""
    property int duration: 2000

    Text {
        id: toastText
        anchors.centerIn: parent
        text: toast.text
        font.pixelSize: Theme.fontSmall
        font.family: Theme.fontFamily
        color: "#FFFFFF"
        elide: Text.ElideRight
        width: parent.width - 16
        horizontalAlignment: Text.AlignHCenter
    }

    Timer {
        id: hideTimer
        interval: toast.duration
        onTriggered: toast.visible = false
    }

    function show(message, dur) {
        toast.text = message || ""
        if (dur !== undefined) toast.duration = dur
        toast.visible = true
        hideTimer.restart()
    }

    Behavior on opacity { NumberAnimation { duration: 150 } }
}

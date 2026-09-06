import QtQuick 2.12
import ".."

Rectangle {
    id: errorOverlay
    anchors.fill: parent
    color: "transparent"
    visible: false

    property string errorText: "加载失败"
    property string retryText: "重试"
    property bool showRetry: true

    signal retry()

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingMedium

        Canvas {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 36; height: 36
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = Theme.textTertiary
                ctx.lineWidth = 2
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                // 圆圈 + 感叹号
                ctx.beginPath()
                ctx.arc(18, 18, 14, 0, Math.PI * 2)
                ctx.stroke()
                ctx.beginPath()
                ctx.moveTo(18, 10)
                ctx.lineTo(18, 20)
                ctx.stroke()
                ctx.beginPath()
                ctx.arc(18, 25, 1.2, 0, Math.PI * 2)
                ctx.fillStyle = Theme.textTertiary
                ctx.fill()
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: errorOverlay.errorText
            font.pixelSize: Theme.fontSmall
            font.family: Theme.fontFamily
            color: Theme.textSecondary
            elide: Text.ElideRight
            width: 200
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            width: 60
            height: 24
            radius: Theme.radiusMedium
            color: Theme.primary
            anchors.horizontalCenter: parent.horizontalCenter
            visible: errorOverlay.showRetry

            Text {
                anchors.centerIn: parent
                text: errorOverlay.retryText
                font.pixelSize: Theme.fontSmall
                font.family: Theme.fontFamily
                color: "#FFFFFF"
                font.bold: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: errorOverlay.retry()
            }
        }
    }
}

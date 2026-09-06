import QtQuick 2.12
import ".."

Item {
    id: loadingIndicator
    width: 80
    height: 60
    visible: true

    property string message: "加载中..."
    property color color: Theme.primary
    property bool running: true

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingSmall

        // 旋转加载动画
        Item {
            width: 28
            height: 28
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                id: spinnerCanvas
                anchors.fill: parent
                property real angle: 0

                Timer {
                    interval: 30
                    repeat: true
                    running: loadingIndicator.running
                    onTriggered: {
                        spinnerCanvas.angle = (spinnerCanvas.angle + 12) % 360
                        spinnerCanvas.requestPaint()
                    }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    var cx = width / 2
                    var cy = height / 2
                    var r = Math.min(width, height) / 2 - 2

                    // 背景圆
                    ctx.strokeStyle = Theme.withAlpha(loadingIndicator.color, 0.15)
                    ctx.lineWidth = 2.5
                    ctx.beginPath()
                    ctx.arc(cx, cy, r, 0, Math.PI * 2)
                    ctx.stroke()

                    // 前景弧
                    ctx.strokeStyle = loadingIndicator.color
                    ctx.lineCap = "round"
                    ctx.beginPath()
                    var startAngle = (angle * Math.PI) / 180
                    var endAngle = ((angle + 240) * Math.PI) / 180
                    ctx.arc(cx, cy, r, startAngle, endAngle)
                    ctx.stroke()
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: loadingIndicator.message
            font.pixelSize: Theme.fontTiny
            font.family: Theme.fontFamily
            color: Theme.textTertiary
            visible: loadingIndicator.message !== ""
        }
    }
}

import QtQuick 2.12
import WeiboPlugin 1.0
import "../components" as Components

// 微博视频播放页：调用外部 mpv 播放器
Rectangle {
    id: playerPage
    width: 320
    height: 170
    color: "#000000"

    property var controller: null
    property int playQuality: 16
    signal backClicked()

    property bool controlsVisible: true
    property bool launchRequested: false

    readonly property int btnSize: 34
    readonly property int iconSize: 18
    readonly property int barHeight: 32
    readonly property color accentColor: Theme.primary

    Connections {
        target: controller
        ignoreUnknownSignals: true
        function onPlaybackReady(url) {
            if (!launchRequested || !url || url.length === 0 || !controller) return
            controller.playback.launchExternalPlayerCurrentSelection()
        }
    }

    // 第1层：占位画面
    Rectangle {
        id: videoContainer
        anchors.fill: parent
        color: "#000000"
        z: 0

        Image {
            anchors.fill: parent
            source: controller && controller.currentStatusVideoCover
                    ? "image://weibo/" + encodeURIComponent(controller.currentStatusVideoCover)
                    : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            opacity: 0.6
            visible: controller && controller.currentStatusVideoCover && controller.currentStatusVideoCover.length > 0
        }

        Text {
            id: placeholderText
            anchors.centerIn: parent
            visible: controlsVisible
            text: controller ? "点击播放按钮以开始" : "正在初始化..."
            color: "#999999"
            font.family: Theme.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 1.4
        }
    }

    // 第2层：点击区域
    MouseArea {
        id: videoClickArea
        anchors.fill: parent
        z: 10
        onClicked: {
            controlsVisible = !controlsVisible
            playPauseIcon.refresh()
            if (controlsVisible) hideControlsTimer.restart()
        }
    }

    // 第3层：顶部控制栏
    Rectangle {
        id: topBar
        width: parent.width
        height: barHeight
        anchors.top: parent.top
        z: 20
        visible: controlsVisible
        opacity: controlsVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.8) }
            GradientStop { position: 1.0; color: "transparent" }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 8
            spacing: 6

            Item {
                width: btnSize
                height: btnSize
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 24
                    radius: Theme.radiusMedium
                    color: backBtnArea.pressed ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

                    Canvas {
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.strokeStyle = "#FFFFFF"
                            ctx.lineWidth = 2.2
                            ctx.lineCap = "round"
                            ctx.lineJoin = "round"
                            ctx.beginPath()
                            ctx.moveTo(11, 2)
                            ctx.lineTo(4, 8)
                            ctx.lineTo(11, 14)
                            ctx.stroke()
                        }
                    }
                }

                MouseArea {
                    id: backBtnArea
                    anchors.fill: parent
                    onClicked: playerPage.backClicked()
                }
            }

            Text {
                text: controller ? controller.currentStatusText().left(25) : ""
                color: "#FFFFFF"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
                width: parent.width - btnSize - 20
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // 第3层：底部控制栏
    Rectangle {
        id: bottomBar
        width: parent.width
        height: barHeight
        anchors.bottom: parent.bottom
        z: 20
        visible: controlsVisible
        opacity: controlsVisible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.8) }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 8
            spacing: 8

            Item {
                width: btnSize
                height: btnSize
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 28
                    height: 24
                    radius: Theme.radiusMedium
                    color: playBtnArea.pressed ? Qt.rgba(1, 1, 1, 0.15) : "transparent"

                    Canvas {
                        id: playPauseIcon
                        anchors.centerIn: parent
                        width: iconSize
                        height: iconSize
                        property bool playing: false
                        function refresh() {
                            playing = controller && controller.playback.externalPlayerRunning()
                        }
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            ctx.fillStyle = "#FFFFFF"
                            if (playing) {
                                var barWidth = 3.5
                                var gap = 4
                                var totalW = barWidth * 2 + gap
                                var barX = (width - totalW) / 2
                                var barY = (height - 14) / 2
                                ctx.fillRect(barX, barY, barWidth, 14)
                                ctx.fillRect(barX + barWidth + gap, barY, barWidth, 14)
                            } else {
                                var triWidth = 12
                                var triHeight = 14
                                var offsetX = (width - triWidth) / 2 + 1.5
                                var offsetY = (height - triHeight) / 2
                                ctx.beginPath()
                                ctx.moveTo(offsetX, offsetY)
                                ctx.lineTo(offsetX, offsetY + triHeight)
                                ctx.lineTo(offsetX + triWidth, offsetY + triHeight / 2)
                                ctx.closePath()
                                ctx.fill()
                            }
                        }
                        onPlayingChanged: requestPaint()
                        Component.onCompleted: refresh()
                    }
                }

                MouseArea {
                    id: playBtnArea
                    anchors.fill: parent
                    onClicked: {
                        if (!controller) return
                        if (controller.isLoading) return
                        playPauseIcon.refresh()
                        if (controller.playback.externalPlayerRunning()) {
                            controller.toastMessage("播放器已在运行，请先关闭当前窗口")
                            return
                        }
                        launchRequested = true
                        controller.toastMessage("正在启动播放器...")
                        if (controller.playUrl && controller.playUrl.length > 0) {
                            controller.playback.launchExternalPlayerCurrentSelection()
                        } else {
                            controller.playback.fetchPlayUrl(controller.currentStatusId)
                        }
                        hideControlsTimer.restart()
                        playPauseIcon.refresh()
                    }
                }
            }

            Text {
                id: currentTimeText
                text: controller && controller.playDuration > 0
                      ? "时长: " + Math.floor(controller.playDuration / 60) + ":" + (controller.playDuration % 60).toString().padStart(2, '0')
                      : "微博视频"
                color: "#FFFFFF"
                font.family: Theme.fontFamily
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
                width: 100
                elide: Text.ElideRight
            }
        }
    }

    // Loading 指示器
    Components.LoadingIndicator {
        anchors.centerIn: parent
        z: 50
        running: controller && controller.isLoading
        message: "获取播放地址..."
        color: "#FFFFFF"
    }

    // 自动隐藏计时器
    Timer {
        id: hideControlsTimer
        interval: 3000
        onTriggered: controlsVisible = false
    }

    Component.onCompleted: {
        hideControlsTimer.start()
    }
}
